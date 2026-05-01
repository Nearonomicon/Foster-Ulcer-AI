import json
import logging
import os
import time
import traceback
import uuid
from datetime import date, datetime, timezone
from typing import Any

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
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


# ---------------------------------------------------------------------------
# Logging configuration
# ---------------------------------------------------------------------------
# We use the standard library logger instead of bare ``print`` so log output is
# structured, level-controlled, and routed correctly by Cloud Run / GKE / etc.
#
# PHI safety: the previous middleware logged full request and response bodies
# on every call. Patient names, NRC IDs, vitals, and AI-generated wound
# assessments were ending up in stdout. We never log bodies by default now.
# To re-enable body logging during local debugging, set ``LOG_BODIES=true``.
# Do NOT set this in any environment that handles real patient data.

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
logger = logging.getLogger("foster_ulcer_ai")

_LOG_BODIES = os.getenv("LOG_BODIES", "").strip().lower() in {"1", "true", "yes"}


def _parse_allowed_origins() -> list[str]:
    """Read CORS allowlist from env. Comma-separated. Defaults to none."""
    raw = os.getenv("CORS_ALLOWED_ORIGINS", "").strip()
    if not raw:
        return []
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


app = FastAPI(title="Wound Care AI Analysis API")

# CORS: native mobile clients do not need CORS. Restrict to explicit origins
# (e.g. the future doctor-portal web app) configured per-environment. The
# previous wildcard policy is gone.
_allowed_origins = _parse_allowed_origins()
if _allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_allowed_origins,
        allow_methods=["GET", "POST", "PATCH", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type"],
        allow_credentials=False,
    )
else:
    logger.info(
        "CORS disabled (CORS_ALLOWED_ORIGINS is empty). "
        "Native mobile clients are unaffected; browser clients will be blocked."
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
    """Lightweight access log. Emits method, path, status, latency, and a
    request id. Bodies are NOT logged unless ``LOG_BODIES=true`` is set, and
    even then only the request-content-type metadata is recorded — never the
    response body, which can contain PHI from analysis routes.
    """
    request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
    request.state.request_id = request_id
    start = time.perf_counter()

    if _LOG_BODIES:
        # Debug-only path. Still does not echo the body — only its size and
        # content type — so that leaving this enabled by accident does not
        # silently exfiltrate PHI.
        body = await request.body()
        request._body = body  # ensure downstream handlers can re-read
        content_type = request.headers.get("content-type", "")
        logger.debug(
            "request received id=%s method=%s path=%s content_type=%s body_bytes=%d",
            request_id,
            request.method,
            request.url.path,
            content_type,
            len(body),
        )

    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000.0
    response.headers["X-Request-ID"] = request_id

    logger.info(
        "request id=%s method=%s path=%s status=%d duration_ms=%.1f",
        request_id,
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


def _request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "-")


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.warning(
        "http_exception id=%s method=%s path=%s status=%d detail=%s",
        _request_id(request),
        request.method,
        request.url.path,
        exc.status_code,
        exc.detail,
    )
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    for err in errors:
        if isinstance(err.get("ctx"), dict):
            err["ctx"] = {k: str(v) for k, v in err["ctx"].items()}
    # Log only the locations that failed validation, not the values — values
    # may contain PHI from clinical payloads.
    failed_locs = [".".join(str(p) for p in err.get("loc", [])) for err in errors]
    logger.info(
        "validation_error id=%s method=%s path=%s failed=%s",
        _request_id(request),
        request.method,
        request.url.path,
        ",".join(failed_locs) or "<none>",
    )
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": errors}))


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(
        "unhandled_exception id=%s method=%s path=%s exc_type=%s",
        _request_id(request),
        request.method,
        request.url.path,
        type(exc).__name__,
    )
    # Stack traces stay in error logs but never the request body.
    logger.error("traceback id=%s\n%s", _request_id(request), "".join(traceback.format_exception(type(exc), exc, exc.__traceback__)))
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
