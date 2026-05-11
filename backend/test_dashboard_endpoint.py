import importlib
import sys
import types
import unittest
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient


ENDPOINT = "/load-dashboard"


class FakeDocSnapshot:
    def __init__(self, doc_id, data, exists=True):
        self.id = doc_id
        self._data = data
        self.exists = exists

    def to_dict(self):
        return self._data


class FakeDocumentRef:
    def __init__(self, collection_name, doc_id):
        self.collection_name = collection_name
        self.id = doc_id


class FakeCollection:
    def __init__(self, name, docs):
        self.name = name
        self._docs = docs

    def order_by(self, *args, **kwargs):
        return self

    def stream(self):
        return [FakeDocSnapshot(doc_id, data) for doc_id, data in self._docs.items()]

    def document(self, doc_id):
        return FakeDocumentRef(self.name, doc_id)


class FakeDB:
    def __init__(self, cases, patients):
        self._cases = cases
        self._patients = patients

    def collection(self, name):
        if name == "cases":
            return FakeCollection(name, self._cases)
        if name == "patients":
            return FakeCollection(name, self._patients)
        raise KeyError(f"Unsupported collection: {name}")

    def get_all(self, refs):
        snapshots = []
        for ref in refs:
            data = self._patients.get(ref.id)
            snapshots.append(FakeDocSnapshot(ref.id, data or {}, exists=data is not None))
        return snapshots


def install_firebase_stub():
    firebase_module = types.ModuleType("services.firebase")
    firebase_module.db = None
    firebase_module.bucket = None
    firebase_module.upload_file_to_firebase = lambda *args, **kwargs: ""
    firebase_module.upload_case_image_to_firebase = lambda *args, **kwargs: ""
    sys.modules["services.firebase"] = firebase_module


class DashboardEndpointTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        install_firebase_stub()
        cls.app_module = importlib.import_module("app")

    def setUp(self):
        today = datetime.now(timezone.utc).date()

        cases = {
            "case-001": {
                "case_id": "case-001",
                "patient_id": "patient-001",
                "status": "TREATMENT_ACTIVE",
                "urgency": "HIGH",
                "case_updated_at": datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc),
                "current_treatment_plan": {
                    "plan_tasks": [
                        {"task_due": today.isoformat(), "status": "SENT"},
                        {"task_due": (today + timedelta(days=1)).isoformat(), "status": "SENT"},
                        {
                            "task_due": (today + timedelta(days=1)).isoformat(),
                            "status": "COMPLETED",
                            "completed_at": datetime.now(timezone.utc).isoformat(),
                        },
                        {"task_due": "not-a-date", "status": "SENT"},
                    ]
                },
            },
            "case-002": {
                "case_id": "case-002",
                "patient_id": "patient-002",
                "status": "DOCTOR_REVIEW",
                "urgency": "MEDIUM",
                "case_updated_at": datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc) + timedelta(hours=2),
                "current_treatment_plan": {
                    "plan_tasks": [
                        {"task_due": (today + timedelta(days=1)).isoformat(), "status": "SENT"},
                    ]
                },
            },
            "case-003": {
                "case_id": "case-003",
                "patient_id": "patient-003",
                "status": "COMPLETED",
                "urgency": "LOW",
                "case_updated_at": datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc) + timedelta(hours=3),
                "current_treatment_plan": {
                    "plan_tasks": [
                        {"task_due": (today + timedelta(days=2)).isoformat(), "status": "SENT"},
                        {"task_due": (today - timedelta(days=1)).isoformat(), "status": "SENT"},
                    ]
                },
            },
            "case-004": {
                "case_id": "case-004",
                "patient_id": "patient-004",
                "status": "PLAN_ISSUED",
                "urgency": "LOW",
                "case_updated_at": datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc) + timedelta(hours=4),
                "current_treatment_plan": {
                    "plan_tasks": [
                        {"task_due": (today + timedelta(days=3)).isoformat(), "status": "SENT"},
                    ]
                },
            },
            "case-005": {
                "case_id": "case-005",
                "patient_id": "patient-005",
                "status": "CREATION",
                "urgency": "LOW",
                "case_updated_at": datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc) + timedelta(hours=5),
                "current_treatment_plan": {
                    "plan_tasks": [
                        {"task_due": (today + timedelta(days=4)).isoformat(), "status": "SENT"},
                    ]
                },
            },
        }

        patients = {
            "patient-001": {"patient_name": "Alice", "photo_url": "https://example.com/alice.jpg"},
            "patient-002": {"patient_name": "Bob", "photo_url": "https://example.com/bob.jpg"},
            "patient-003": {"patient_name": "Cara", "photo_url": "https://example.com/cara.jpg"},
            "patient-004": {"patient_name": "Dan", "photo_url": "https://example.com/dan.jpg"},
            "patient-005": {"patient_name": "Eve", "photo_url": "https://example.com/eve.jpg"},
        }

        self.app_module.db = FakeDB(cases=cases, patients=patients)
        self.client = TestClient(self.app_module.app)
        self.today = today

    def test_load_dashboard_returns_expected_summary(self):
        response = self.client.get(ENDPOINT)
        self.assertEqual(response.status_code, 200, response.text)

        payload = response.json()
        self.assertEqual(payload["status"], "success")
        self.assertEqual(payload["today_task_no"], 1)
        self.assertEqual(payload["total_active_patient"], 4)

        upcoming_plan = payload["upcoming_plan"]
        self.assertEqual(len(upcoming_plan), 4)

        self.assertEqual(
            [item["case_id"] for item in upcoming_plan],
            ["case-001", "case-001", "case-002", "case-003"],
        )
        self.assertEqual(
            [item["due_date"] for item in upcoming_plan],
            [
                self.today.isoformat(),
                (self.today + timedelta(days=1)).isoformat(),
                (self.today + timedelta(days=1)).isoformat(),
                (self.today + timedelta(days=2)).isoformat(),
            ],
        )
        self.assertEqual(upcoming_plan[0]["patient_name"], "Alice")
        self.assertEqual(upcoming_plan[1]["patient_photo_url"], "https://example.com/alice.jpg")


if __name__ == "__main__":
    unittest.main()
