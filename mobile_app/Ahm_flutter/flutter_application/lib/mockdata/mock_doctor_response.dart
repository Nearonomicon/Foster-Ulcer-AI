// lib/data/mock/mock_doctor_response.dart

final Map<String, dynamic> mockDoctorResponse = {
  "case_id": "ULC-9283",

  "doctor_draft": {
    "exists": true,
    "doctor_stage_selected": "WAGNER_2",
    "diagnosis_override": "Diabetic foot ulcer, Wagner grade 2",
    "clinical_notes":
        "Deep ulcer with calloused edges. No obvious abscess. Continue close monitoring.",
    "reviewed_by": "doctor_001",
    "reviewed_at": "2026-03-06T10:15:00+07:00",
    "draft_status": "SAVED"
  },

  "treatment_plan": {
    "plan_id": "PLAN-001",
    "case_id": "ULC-9283",
    "plan_text":
        "Offload the right great toe, debride non-viable tissue, apply moist dressing, and follow up in 3 days.",
    "followup_days": 3,
    "status": "SENT_TO_NURSE",
    "created_by": "doctor_001",
    "created_at": "2026-03-06T10:18:00+07:00",
    "sent_at": "2026-03-06T10:20:00+07:00",
    "doctor_signature_url":
        "https://storage.example.com/signatures/doctor_001_plan_001.png",

    "plan_tasks": [
      {
        "task_id": "TASK-001",
        "task_text": "Apply offloading device to affected toe",
        "due_date": "2026-03-06T16:00:00+07:00",
        "status": "PENDING"
      },
      {
        "task_id": "TASK-002",
        "task_text": "Debride non-viable tissue",
        "due_date": "2026-03-07T10:00:00+07:00",
        "status": "PENDING"
      },
      {
        "task_id": "TASK-003",
        "task_text": "Apply moist wound dressing",
        "due_date": "2026-03-06T16:00:00+07:00",
        "status": "PENDING"
      }
    ]
  },

  "meta": {
    "workflow_status": "TREATMENT_SENT",
    "notification_needed_for": "nurse",
    "nurse_notification_type": "TREATMENT_PLAN_READY",
    "last_action_by": "doctor_001",
    "last_action_at": "2026-03-06T10:20:00+07:00"
  }
};