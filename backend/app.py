import json
from datetime import date, datetime, timezone
from typing import Any

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse, Response
from fastapi.exceptions import RequestValidationError
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import firestore

from routes.patients import router as patients_router
from routes.cases import router as cases_router
from routes.analysis import router as analysis_router
from routes.notifications import router as notifications_router
from routes.task import router as tasks_router
from services.firebase import db


app = FastAPI(title="Wound Care AI Analysis API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=False,
)


ACTIVE_CASE_STATUSES = {
    "CREATION",
    "AI_PROCESSING",
    "DOCTOR_REVIEW",
    "PLAN_ISSUED",
    "TREATMENT_ACTIVE",
    "APPOINTMENT",
}

DONE_TASK_STATUSES = {"DONE", "COMPLETED", "CANCELLED"}


def _parse_dashboard_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        parsed = value
    elif hasattr(value, "ToDatetime"):
        parsed = value.ToDatetime()
    elif isinstance(value, str):
        normalized = value.strip()
        if not normalized:
            return None
        normalized = normalized.replace("Z", "+00:00")
        parsed = None
        for candidate in (normalized, normalized.replace(" ", "T")):
            try:
                parsed = datetime.fromisoformat(candidate)
                break
            except ValueError:
                continue
        if parsed is None:
            return None
    else:
        return None

    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _parse_dashboard_date(value: Any) -> date | None:
    parsed = _parse_dashboard_datetime(value)
    if parsed is not None:
        return parsed.date()
    if isinstance(value, str):
        raw_value = value.strip()
        if not raw_value:
            return None
        try:
            return date.fromisoformat(raw_value[:10])
        except ValueError:
            return None
    return None


def _serialize_dashboard_datetime(value: Any) -> str:
    parsed = _parse_dashboard_datetime(value)
    if parsed is not None:
        return parsed.isoformat()
    if value is None:
        return ""
    return str(value)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    try:
        body = await request.body()
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            try:
                payload = json.loads(body.decode("utf-8")) if body else None
            except Exception:
                payload = body.decode("utf-8", errors="replace")
        else:
            payload = f"{len(body)} bytes"
        print(f"[REQUEST] {request.method} {request.url.path} content_type={content_type} payload={payload}")
        request._body = body
    except Exception as e:
        print(f"[REQUEST] {request.method} {request.url.path} error reading body: {e}")

    response = await call_next(request)
    try:
        body_bytes = b""
        async for chunk in response.body_iterator:
            body_bytes += chunk
        body_text = body_bytes.decode("utf-8", errors="replace")
    except Exception as e:
        body_text = f"<unable to read body: {e}>"

    print(f"[RESPONSE] {request.method} {request.url.path} status={response.status_code} payload={body_text}")

    return Response(
        content=body_bytes,
        status_code=response.status_code,
        headers=dict(response.headers),
        media_type=response.media_type,
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} HTTPException status={exc.status_code} detail={exc.detail}")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    print(f"[RESPONSE] {request.method} {request.url.path} status={exc.status_code}")
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} RequestValidationError")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    errors = exc.errors()
    for err in errors:
        if isinstance(err.get("ctx"), dict):
            err["ctx"] = {k: str(v) for k, v in err["ctx"].items()}
    print(f"[RESPONSE] {request.method} {request.url.path} status=422")
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": errors}))


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    import traceback
    print(f"[ERROR] {request.method} {request.url.path} {exc}")
    print("".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
    print(f"[RESPONSE] {request.method} {request.url.path} status=500")
    return JSONResponse(status_code=500, content={"detail": "Internal Server Error"})


@app.get("/load-dashboard")
async def load_dashboard():
    try:
        today = datetime.now(timezone.utc).date()
        cases_docs = db.collection("cases").order_by(
            "case_updated_at", direction=firestore.Query.DESCENDING
        ).stream()

        cases = []
        patient_ids: set[str] = set()
        active_patient_ids: set[str] = set()
        due_today_count = 0
        upcoming_tasks = []

        for doc in cases_docs:
            case_data = doc.to_dict() or {}
            case_id = case_data.get("case_id") or doc.id
            patient_id = case_data.get("patient_id")
            status = str(case_data.get("status") or "")

            if patient_id:
                patient_ids.add(patient_id)
                if status in ACTIVE_CASE_STATUSES:
                    active_patient_ids.add(patient_id)

            current_treatment_plan = case_data.get("current_treatment_plan") or {}
            plan_tasks = current_treatment_plan.get("plan_tasks") or []
            if not isinstance(plan_tasks, list):
                plan_tasks = []

            cases.append((case_id, case_data))

            for task in plan_tasks:
                if not isinstance(task, dict):
                    continue
                task_status = str(task.get("status") or "").upper()
                completed_at = task.get("completed_at")
                if task_status in DONE_TASK_STATUSES or completed_at not in (None, ""):
                    continue

                due_date = _parse_dashboard_date(task.get("task_due"))
                if due_date is None:
                    continue

                if due_date == today:
                    due_today_count += 1

                if due_date < today:
                    continue

                upcoming_tasks.append(
                    {
                        "case_id": case_id,
                        "patient_id": patient_id or "",
                        "status": status,
                        "urgency": case_data.get("urgency") or "",
                        "case_updated_at": _serialize_dashboard_datetime(case_data.get("case_updated_at")),
                        "due_date": due_date.isoformat(),
                    }
                )

        patient_map: dict[str, dict[str, Any]] = {}
        if patient_ids:
            refs = [db.collection("patients").document(patient_id) for patient_id in patient_ids]
            for snap in db.get_all(refs):
                if snap.exists:
                    patient_map[snap.id] = snap.to_dict() or {}

        upcoming_tasks.sort(
            key=lambda item: (
                item.get("due_date") or "9999-12-31",
                item.get("case_updated_at") or "",
            )
        )

        upcoming_plan = []
        for item in upcoming_tasks[:4]:
            patient_data = patient_map.get(item["patient_id"], {})
            upcoming_plan.append(
                {
                    "case_id": item["case_id"],
                    "patient_id": item["patient_id"],
                    "patient_name": patient_data.get("patient_name", ""),
                    "status": item["status"],
                    "urgency": item["urgency"],
                    "case_updated_at": item["case_updated_at"],
                    "due_date": item["due_date"],
                    "patient_photo_url": patient_data.get("photo_url", ""),
                }
            )

        return {
            "status": "success",
            "today_task_no": due_today_count,
            "total_active_patient": len(active_patient_ids),
            "upcoming_plan": upcoming_plan,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


app.include_router(patients_router)
app.include_router(cases_router)
app.include_router(analysis_router)
app.include_router(notifications_router)
app.include_router(tasks_router)
