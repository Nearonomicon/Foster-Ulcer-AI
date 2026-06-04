import argparse
import json
import mimetypes
import sys
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib import error, parse, request


class ApiError(Exception):
    def __init__(self, status_code: int, body: str):
        self.status_code = status_code
        self.body = body
        super().__init__(f"HTTP {status_code}: {body}")


class APIClient:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")

    def get_json(self, path: str, query: dict | None = None, expected_status: int = 200):
        url = self.base_url + path
        if query:
            url += "?" + parse.urlencode(query)
        req = request.Request(url, method="GET")
        return self._send(req, expected_status)

    def post_json(self, path: str, payload: dict | None = None, expected_status: int = 200):
        data = json.dumps(payload or {}).encode("utf-8")
        req = request.Request(
            self.base_url + path,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        return self._send(req, expected_status)

    def patch_json(self, path: str, payload: dict | None = None, expected_status: int = 200):
        data = json.dumps(payload or {}).encode("utf-8")
        req = request.Request(
            self.base_url + path,
            data=data,
            headers={"Content-Type": "application/json"},
            method="PATCH",
        )
        return self._send(req, expected_status)

    def post_multipart(
        self,
        path: str,
        fields: dict[str, str | bytes | None],
        files: list[tuple[str, Path, str | None]] | None = None,
        expected_status: int = 200,
    ):
        content_type, body = build_multipart(fields, files or [])
        req = request.Request(
            self.base_url + path,
            data=body,
            headers={"Content-Type": content_type},
            method="POST",
        )
        return self._send(req, expected_status)

    def _send(self, req: request.Request, expected_status: int):
        try:
            with request.urlopen(req) as resp:
                body = resp.read().decode("utf-8")
                if resp.status != expected_status:
                    raise ApiError(resp.status, body)
                return decode_body(body)
        except error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            if exc.code != expected_status:
                raise ApiError(exc.code, body) from exc
            return decode_body(body)


def build_multipart(fields: dict[str, str | bytes | None], files: list[tuple[str, Path, str | None]]):
    boundary = f"----CodexBoundary{uuid.uuid4().hex}"
    chunks: list[bytes] = []

    for name, value in fields.items():
        if value is None:
            continue
        raw = value if isinstance(value, bytes) else str(value).encode("utf-8")
        chunks.append(f"--{boundary}\r\n".encode("utf-8"))
        chunks.append(
            f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("utf-8")
        )
        chunks.append(raw)
        chunks.append(b"\r\n")

    for field_name, file_path, content_type in files:
        file_bytes = file_path.read_bytes()
        guessed = content_type or mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
        chunks.append(f"--{boundary}\r\n".encode("utf-8"))
        chunks.append(
            (
                f'Content-Disposition: form-data; name="{field_name}"; '
                f'filename="{file_path.name}"\r\n'
            ).encode("utf-8")
        )
        chunks.append(f"Content-Type: {guessed}\r\n\r\n".encode("utf-8"))
        chunks.append(file_bytes)
        chunks.append(b"\r\n")

    chunks.append(f"--{boundary}--\r\n".encode("utf-8"))
    return f"multipart/form-data; boundary={boundary}", b"".join(chunks)


def decode_body(body: str):
    text = body.strip()
    if not text:
        return {}
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text}


def expect(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def now_plus(days: int = 0, hours: int = 0) -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=days, hours=hours)


def iso_dt(days: int = 0, hours: int = 0) -> str:
    return now_plus(days=days, hours=hours).isoformat()


def date_str(days: int = 0) -> str:
    return now_plus(days=days).date().isoformat()


def print_step(title: str):
    print(f"\n== {title} ==")


def verify_notification_contains(notifications: list[dict], case_id: str, record_id: str | None = None):
    for item in notifications:
        if item.get("case_id") == case_id and (record_id is None or item.get("record_id") == record_id):
            return True
    return False


def run_negative_checks(client: APIClient, context: dict):
    print_step("Negative checks")

    case_detail_missing = client.post_json("/case_detail", {}, expected_status=400)
    expect("case_id" in str(case_detail_missing), "case_detail missing-case_id check failed")

    bad_plan_payload = [
        {
            "task_id": context["task_id"],
            "updates": {"status": "DONE"},
        }
    ]
    task_update_bad_plan = client.post_multipart(
        "/task_update",
        fields={
            "case_id": context["case_id"],
            "plan_id": "PL-WRONG",
            "updates": json.dumps(bad_plan_payload),
        },
        expected_status=400,
    )
    expect("plan_id" in str(task_update_bad_plan), "task_update bad plan_id check failed")

    appointment_bad_dt = client.post_json(
        "/create_appointment",
        {"case_id": context["case_id"], "appointment_at": "not-a-date"},
        expected_status=400,
    )
    expect("appointment_at" in str(appointment_bad_dt), "create_appointment invalid datetime check failed")

    request_close_missing = client.post_json("/request_close", {}, expected_status=400)
    expect("case_id" in str(request_close_missing), "request_close missing-case_id check failed")

    complete_missing = client.post_json("/complete_case", {}, expected_status=400)
    expect("case_id" in str(complete_missing), "complete_case missing-case_id check failed")

    update_wrong_patient = client.post_json(
        "/update_cases",
        {
            "patient_id": "PT-WRONG",
            "case_id": context["case_id"],
            "status": "CREATION",
            "urgency": "MEDIUM",
            "created_by_nurse": context["nurse_id"],
            "assigned_doctor": context["doctor_id"],
            "vitals": {"temperature": "36.9"},
            "meta": {"sent_at": iso_dt(days=2)},
        },
        expected_status=400,
    )
    expect("patient_id does not match case" in str(update_wrong_patient), "update_cases wrong patient guard failed")


def run(args):
    client = APIClient(args.base_url)
    suffix = datetime.now().strftime("%Y%m%d%H%M%S")
    patient_name = f"API Test Patient {suffix}"

    image_path = Path(args.image).resolve() if args.image else None
    audio_path = Path(args.audio).resolve() if args.audio else None

    context = {
        "nurse_id": args.nurse_id,
        "doctor_id": args.doctor_id,
    }

    print_step("Create patient")
    patient_payload = {
        "nrc_id": f"1234567{suffix[-6:]}",
        "patient_name": patient_name,
        "phone_no": "0812345678",
        "dob": "19/03/2001",
        "gender": "female",
        "height_cm": 160,
        "weight_kg": 55,
        "medical_history": "Diabetes mellitus",
        "diabetes": {
            "has_diabetes": "Yes",
            "years": "1-5y",
            "risk_history": ["Past Ulcer"],
            "complications": ["Eyes (Retinopathy)"],
        },
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "status": "Active",
    }
    create_patient = client.post_multipart(
        "/create-patient-profile",
        fields={"patient_data": json.dumps(patient_payload)},
        files=[("image", image_path, None)] if image_path else [],
    )
    expect(create_patient.get("status") == "success", "create-patient-profile did not succeed")
    context["patient_id"] = create_patient["patient_id"]

    print_step("List and patch patient")
    patients = client.get_json("/patients_list", {"limit": 20})
    expect(any(p.get("patient_id") == context["patient_id"] for p in patients.get("patients", [])), "patient missing from patients_list")
    patch_patient = client.patch_json(
        f"/patients/{context['patient_id']}",
        {"phone_no": "0899999999", "weight_kg": 56},
    )
    expect(patch_patient.get("status") == "success", "patient patch failed")

    print_step("Create case")
    create_case = client.post_json(
        "/create-case",
        {
            "patient_id": context["patient_id"],
            "status": "CREATION",
            "urgency": "MEDIUM",
            "created_by_nurse": args.nurse_id,
            "assigned_doctor": args.doctor_id,
            "vitals": {
                "temperature": "37.0",
                "blood_pressure": "120/80",
                "blood_pressure_systolic": "120",
                "blood_pressure_diastolic": "80",
                "blood_glucose": "145",
                "heart_rate": "76",
                "respiratory_rate": "18",
            },
            "meta": {"sent_at": iso_dt()},
        },
    )
    context["case_id"] = create_case["case_id"]
    context["record_id"] = create_case["record_id"]

    print_step("Case list and detail checks")
    cases = client.post_json("/cases_list", {"limit": 20})
    expect(any(c.get("case_id") == context["case_id"] for c in cases.get("cases", [])), "case missing from unfiltered cases_list")

    creation_filter = client.post_json("/cases_list", {"filter": ["CREATION"]})
    expect(any(c.get("case_id") == context["case_id"] for c in creation_filter.get("cases", [])), "case missing from CREATION filter")

    patient_filter = client.post_json("/cases_list", {"patient_id": context["patient_id"]})
    expect(any(c.get("case_id") == context["case_id"] for c in patient_filter.get("cases", [])), "case missing from patient_id filter")

    detail = client.post_json("/case_detail", {"case_id": context["case_id"]})
    expect(detail.get("case", {}).get("patient_id") == context["patient_id"], "case_detail patient mismatch")
    expect(any(r.get("record_id") == context["record_id"] for r in detail.get("records", [])), "initial record missing from case_detail")

    if audio_path:
        print_step("Analyze transcribe")
        transcribe = client.post_multipart(
            "/analyze-transcribe",
            fields={"case_id": context["case_id"], "record_id": context["record_id"]},
            files=[("audio", audio_path, None)],
        )
        expect(transcribe.get("status") in {"success", "blocked"}, "analyze-transcribe unexpected response")
    else:
        print("\n== Analyze transcribe ==\nskipped: no --audio provided")

    if image_path:
        print_step("Analyze fill-in")
        fillin = client.post_multipart(
            "/analyze-fillin",
            fields={"case_id": context["case_id"], "record_id": context["record_id"]},
            files=[("image", image_path, None)],
        )
        expect(fillin.get("status") == "success", "analyze-fillin failed")

        print_step("Analyze wound")
        analyze_payload = {
            "case_ref": {
                "patient_id": context["patient_id"],
                "case_id": context["case_id"],
                "record_id": context["record_id"],
            },
            "patient_profile": {
                "patient_id": context["patient_id"],
                "patient_name": patient_name,
            },
            "nurse_reviewed": {
                "nurse_reviewed_flag": True,
                "vital_signs": {
                    "temperature": "37.0",
                    "blood_pressure": "120/80",
                    "blood_pressure_systolic": "120",
                    "blood_pressure_diastolic": "80",
                    "blood_glucose": "145",
                    "heart_rate": "76",
                    "respiratory_rate": "18",
                },
                "wound_detail": {
                    "location_primary": "toe",
                    "location_detail": "left great toe",
                    "wound_type": "ulcer",
                    "shape": "irregular",
                    "size": {"width_cm": 2.4, "length_cm": 3.1},
                    "depth_category": "full_thickness",
                    "bed": {"slough_pct": 40, "necrotic_pct": 10},
                    "edge_description": "irregular",
                    "periwound_status": "erythematous",
                    "discharge": {"volume": "moderate", "type": "seropurulent (cloudy yellow)"},
                    "odor_presence": "faint",
                    "pain_score": 5,
                    "has_infection": True,
                    "skin_condition": "dry",
                },
                "ischemia": {"points": [1], "pulse": "yes", "checklist": []},
                "infection": {
                    "checklist": ["Warmth (hotter than other foot)"],
                    "erythema_extent": "gt_0_5_cm",
                    "probe_to_bone_test": "negative",
                    "has_deep_abscess_or_fasciitis": False,
                },
                "neuropathy": {"points": [1]},
                "sinbad": {
                    "site": "Forefoot",
                    "ischemia": "No",
                    "neuropathy": "Yes",
                    "infection": "Yes",
                    "area": ">= 1 cm2",
                    "depth": "Skin only",
                },
                "lab_results": {"wbc_count": "11000", "crp": "15", "esr": "25", "procalcitonin": "0.2"},
                "vascular": {
                    "abi_value": "1.0",
                    "ankle_pressure_mmHg": "120",
                    "toe_pressure_mmHg": "90",
                    "tcpo2_mmHg": "55",
                },
                "gangrene_extent": "none",
            },
        }
        analyze_wound = client.post_multipart(
            "/analyze-wound",
            fields={"payload_data": json.dumps(analyze_payload)},
            files=[("image", image_path, None)],
        )
        expect(analyze_wound.get("status") in {"success", "blocked"}, "analyze-wound unexpected response")
    else:
        print("\n== Analyze fill-in / Analyze wound ==\nskipped: no --image provided")

    print_step("Send to doctor")
    send_to_doctor = client.post_json(
        "/send-to-doctor",
        {
            "record_id": context["record_id"],
            "case_id": context["case_id"],
            "patient_id": context["patient_id"],
            "created_by_nurse": args.nurse_id,
            "assigned_doctor": args.doctor_id,
            "status": "DOCTOR_REVIEW",
            "urgency": "MEDIUM",
            "vital_signs": {
                "temperature": "37.0",
                "blood_pressure": "120/80",
                "blood_pressure_systolic": "120",
                "blood_pressure_diastolic": "80",
                "blood_glucose": "145",
                "heart_rate": "76",
                "respiratory_rate": "18",
            },
            "wound_detail": {
                "location_primary": "toe",
                "location_detail": "left great toe",
                "wound_type": "ulcer",
                "shape": "irregular",
                "size": {"width_cm": 2.4, "length_cm": 3.1},
                "depth_category": "full_thickness",
                "bed": {"slough_pct": 40, "necrotic_pct": 10},
                "edge_description": "irregular",
                "periwound_status": "erythematous",
                "discharge": {"volume": "moderate", "type": "seropurulent (cloudy yellow)"},
                "odor_presence": "faint",
                "pain_score": 5,
                "has_infection": True,
                "skin_condition": "dry",
            },
            "ischemia": {"points": [1], "pulse": "yes", "checklist": []},
            "infection": {
                "checklist": ["Warmth (hotter than other foot)"],
                "erythema_extent": "gt_0_5_cm",
                "probe_to_bone_test": "negative",
                "has_deep_abscess_or_fasciitis": False,
            },
            "neuropathy": {"points": [1]},
            "sinbad": {
                "site": "Forefoot",
                "ischemia": "No",
                "neuropathy": "Yes",
                "infection": "Yes",
                "area": ">= 1 cm2",
                "depth": "Skin only",
            },
            "lab_results": {"wbc_count": "11000", "crp": "15", "esr": "25", "procalcitonin": "0.2"},
            "vascular": {
                "abi_value": "1.0",
                "ankle_pressure_mmHg": "120",
                "toe_pressure_mmHg": "90",
                "tcpo2_mmHg": "55",
            },
            "gangrene_extent": "none",
            "analysis": {
                "diagnosis": "Initial AI diagnosis",
                "description": "AI suggested wound review",
                "confidence": 0.8,
                "classifications": {"SINBAD": {"site": "Forefoot"}},
            },
            "treatment_plan": {
                "plan_text": "Initial draft plan",
                "followup_days": 7,
                "status": "DRAFT",
                "plan_tasks": [
                    {"task_text": "Clean wound daily", "task_due": date_str(days=1), "status": "DRAFT"},
                    {"task_text": "Check glucose level", "task_due": date_str(days=2), "status": "DRAFT"},
                ],
            },
        },
    )
    context["analysis_id"] = send_to_doctor["analysis_id"]
    context["plan_id"] = send_to_doctor["plan_id"]

    print_step("Doctor notifications")
    doctor_notifications = client.get_json("/doctor-notifications", {"limit": 50})
    expect(
        verify_notification_contains(doctor_notifications.get("notifications", []), context["case_id"], context["record_id"]),
        "doctor notification for send-to-doctor missing",
    )

    print_step("Doctor review")
    doctor_review = client.post_json(
        "/doctor-review",
        {
            "case_id": context["case_id"],
            "record_id": context["record_id"],
            "analysis_id": context["analysis_id"],
            "analysis": {
                "diagnosis": "Doctor reviewed diagnosis",
                "description": "Confirmed infected ulcer",
                "healing_progress": "Baseline assessment completed",
                "classifications": {},
            },
            "treatment_plan": {
                "plan_text": "Perform dressing change, offloading, and follow-up review.",
                "followup_days": 7,
                "plan_tasks": [
                    {"order_index": 1, "task_text": "Apply dressing", "task_due": date_str(days=1)},
                    {"order_index": 2, "task_text": "Offloading education", "task_due": date_str(days=1)},
                    {"order_index": 3, "task_text": "Review in clinic", "task_due": date_str(days=7)},
                ],
            },
            "ai_result_edit_flag": True,
            "treatment_plan_edit_flag": True,
            "signature_base64": "data:image/png;base64,TEST_SIGNATURE",
        },
    )
    context["analysis_id"] = doctor_review["analysis_id"]
    context["plan_id"] = doctor_review["plan_id"]

    print_step("Case detail after doctor review")
    detail_after_review = client.post_json("/case_detail", {"case_id": context["case_id"]})
    case_data = detail_after_review["case"]
    expect(case_data.get("status") == "PLAN_ISSUED", "case not PLAN_ISSUED after doctor-review")
    expect(case_data.get("current_treatment_plan", {}).get("status") == "SENT", "plan not SENT after doctor-review")
    tasks = case_data.get("current_treatment_plan", {}).get("plan_tasks") or []
    expect(tasks and all(t.get("status") == "SENT" for t in tasks), "not all tasks are SENT after doctor-review")
    context["task_id"] = tasks[0]["task_id"]

    print_step("Nurse notifications")
    nurse_notifications = client.get_json("/nurse-notifications", {"limit": 50})
    expect(
        verify_notification_contains(nurse_notifications.get("notifications", []), context["case_id"], context["record_id"]),
        "nurse notification for doctor-review missing",
    )

    print_step("Tasks list and detail")
    tasks_list = client.post_json("/tasks_list", {"limit": 50})
    expect(
        any(item.get("case_id") == context["case_id"] for item in tasks_list.get("current_treatment_plan", [])),
        "case missing from tasks_list",
    )
    task_detail = client.post_json("/task_detail", {"case_id": context["case_id"], "task_index": 0})
    expect(task_detail.get("task", {}).get("task_id") == context["task_id"], "task_detail(0) returned wrong task")
    task_detail_all = client.post_json("/task_detail", {"case_id": context["case_id"]})
    expect(len(task_detail_all.get("plan_tasks", [])) >= 1, "task_detail without index should return plan_tasks")

    print_step("Task update")
    task_update = client.post_multipart(
        "/task_update",
        fields={
            "case_id": context["case_id"],
            "plan_id": context["plan_id"],
            "updates": json.dumps(
                [
                    {
                        "task_id": context["task_id"],
                        "updates": {
                            "status": "COMPLETED",
                            "completed_at": iso_dt(hours=1),
                            "task_text": "Apply dressing and document wound",
                        },
                    }
                ]
            ),
        },
        files=[("images", image_path, None)] if image_path else [],
    )
    expect(context["task_id"] in task_update.get("updated_task_ids", []), "task_update did not report updated task")

    print_step("Dashboard")
    dashboard = client.get_json("/load-dashboard")
    expect("today_task_no" in dashboard, "dashboard missing today_task_no")
    expect("total_active_patient" in dashboard, "dashboard missing total_active_patient")
    expect("upcoming_plan" in dashboard, "dashboard missing upcoming_plan")

    print_step("Create appointment and filters")
    appointment = client.post_json(
        "/create_appointment",
        {"case_id": context["case_id"], "appointment_at": iso_dt(days=3)},
    )
    expect(appointment.get("status") == "success", "create_appointment failed")
    appointment_filter = client.post_json("/cases_list", {"filter": ["APPOINTMENT"]})
    expect(any(c.get("case_id") == context["case_id"] for c in appointment_filter.get("cases", [])), "case missing from APPOINTMENT filter")

    print_step("Request close and filter")
    request_close = client.post_json("/request_close", {"case_id": context["case_id"]})
    expect(request_close.get("status") == "success", "request_close failed")
    request_close_filter = client.post_json("/cases_list", {"filter": ["REQUEST_CLOSE"]})
    expect(any(c.get("case_id") == context["case_id"] for c in request_close_filter.get("cases", [])), "case missing from REQUEST_CLOSE filter")
    doctor_notifications_after_close = client.get_json("/doctor-notifications", {"limit": 50})
    expect(
        verify_notification_contains(doctor_notifications_after_close.get("notifications", []), context["case_id"], context["record_id"]),
        "doctor notification for request_close missing",
    )

    print_step("Complete case and filter")
    complete = client.post_json(
        "/complete_case",
        {"case_id": context["case_id"], "completed_at": iso_dt(days=4)},
    )
    expect(complete.get("status") == "success", "complete_case failed")
    complete_filter = client.post_json("/cases_list", {"filter": ["COMPLETED"]})
    expect(any(c.get("case_id") == context["case_id"] for c in complete_filter.get("cases", [])), "case missing from COMPLETED filter")

    if args.run_followup:
        print_step("Follow-up record")
        followup = client.post_json(
            "/update_cases",
            {
                "patient_id": context["patient_id"],
                "case_id": context["case_id"],
                "status": "CREATION",
                "urgency": "MEDIUM",
                "created_by_nurse": args.nurse_id,
                "assigned_doctor": args.doctor_id,
                "vitals": {
                    "temperature": "36.8",
                    "blood_pressure": "118/78",
                    "blood_pressure_systolic": "118",
                    "blood_pressure_diastolic": "78",
                    "blood_glucose": "138",
                    "heart_rate": "74",
                    "respiratory_rate": "18",
                },
                "meta": {"sent_at": iso_dt(days=5)},
            },
        )
        expect(followup.get("status") == "Case update success", "update_cases follow-up failed")
        context["followup_record_id"] = followup["record_id"]

        if args.run_healing:
            print_step("Analyze healing")
            healing = client.post_json("/analyze-healing", {"case_id": context["case_id"]})
            expect(healing.get("status") in {"success", "blocked"}, "analyze-healing unexpected response")
    elif args.run_healing:
        print("\n== Analyze healing ==\nskipped: use --run-followup together with --run-healing")

    run_negative_checks(client, context)

    print_step("Done")
    print(json.dumps(context, indent=2))


def parse_args():
    parser = argparse.ArgumentParser(description="Manual API smoke test runner for Foster Ulcer AI backend.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8080")
    parser.add_argument("--image", help="Optional test image path for analyze-fillin, analyze-wound, and task_update.")
    parser.add_argument("--audio", help="Optional test audio path for analyze-transcribe.")
    parser.add_argument("--nurse-id", default="NURSE-001")
    parser.add_argument("--doctor-id", default="DR-001")
    parser.add_argument("--run-followup", action="store_true", help="Run /update_cases after the main lifecycle.")
    parser.add_argument("--run-healing", action="store_true", help="Run /analyze-healing after follow-up.")
    return parser.parse_args()


if __name__ == "__main__":
    try:
        run(parse_args())
    except Exception as exc:
        print(f"\nFAILED: {exc}", file=sys.stderr)
        sys.exit(1)
