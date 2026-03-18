// lib/mockdata/mock_nurse_case.dart

final Map<String, dynamic> mockCaseDetailResponse = {
  "request_id": "req_003",
  "timestamp": "2026-03-09T10:05:00Z",
  "success": true,
  "message": "Case detail fetched",
  "data": {
    "case_bundle": {
      "case_summary": {
        "record_id": "REC-0001",
        "case_id": "ULC-9283",
        "patient_id": "PAT-001",
        "patient_name": "PAWMAN",
        "urgency": "HIGH",
        "status": "DOCTOR_REVIEW",
        "ai_stage": "Stage 3 Ulcer",
        "ai_confidence": 0.75,
        "image_count": 3,
        "latest_image_url":
            "https://images.unsplash.com/photo-1584515933487-779824d29309?q=80&w=1200&auto=format&fit=crop",
        "has_nurse_note": true,
        "created_at": "2026-03-06T09:30:00+07:00",
        "updated_at": "2026-03-06T09:45:00+07:00",
        "assigned_doctor_id": "doctor_001",
        "submitted_by_nurse_id": "nurse_001",
        "analyze_at": "2026-03-06T09:43:00+07:00"
      },
      "patient_profile": {
        "patient_id": "PAT-001",
        "patient_name": "PAWMAN",
        "phone_no": "0861948565",
        "dob": "2001-02-03",
        "age": 25,
        "gender": "male",
        "height_cm": 170,
        "weight_kg": 60,
        "occupation": "Data Analysis",
        "medical_history": ["Diabetes"],
        "diabetes_flag": true,
        "comorbidities": ["Diabetes"],
        "allergies": [],
        "created_at": "2026-01-28T11:33:20+07:00"
      },
      "nurse_reviewed": {
        "review_id": "NR-ULC-9283-001",
        "case_id": "ULC-9283",
        "location_primary": "toe",
        "location_detail": "plantar aspect of the great toe",
        "laterality": "right",
        "wound_type": "ulcer",
        "shape": "round",
        "size_width_cm": 1.5,
        "size_length_cm": 1.5,
        "area_cm2": 2.25,
        "depth_category": "full_thickness",
        "bed_granulation_pct": 85,
        "bed_slough_pct": 10,
        "bed_necrotic_pct": 5,
        "edge_description": "calloused",
        "periwound_status": "erythematous",
        "discharge_volume": "minimal",
        "discharge_type": "serous",
        "odor_presence": "faint",
        "pain_score": 4,
        "has_infection": false,
        "skin_condition": "dry",
        "temperature_c": 37.0,
        "blood_pressure": "120/80",
        "heart_rate": 80,
        "respiratory_rate": 18,
        "blood_glucose_mg_dl": 148,
        "mobility_status": "walks independently",
        "offloading_in_place": false,
        "nurse_note":
            "Patient reports mild pain while walking. Wound appears deeper than last week. Periwound redness present.",
        "captured_by": "nurse_001",
        "captured_at": "2026-03-06T09:40:00+07:00"
      },
      "ai_analysis": {
        "analysis_id": "AI-ULC-9283-001",
        "image_id": "IMG-ULC-9283-003",
        "case_id": "ULC-9283",
        "creator": "Gemini AI",
        "model_version": "v1.2.0",
        "draft_status": "READY",
        "wound_stage": "STAGE 3",
        "diagnosis":
            "Diabetic foot ulcer on the plantar aspect of the great toe with surrounding erythema.",
        "confidence": 0.75,
        "description":
            "Full-thickness ulcer with minor necrotic tissue and erythema around the wound.",
        "treatment_suggestion":
            "Focus on offloading, debridement, moist wound environment, infection monitoring.",
        "healing_progress": "stable",
        "created_at": "2026-03-06T09:43:00+07:00"
      },
      "wound_images": [
        {
          "image_id": "IMG-ULC-9283-001",
          "case_id": "ULC-9283",
          "image_url":
              "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=1200&auto=format&fit=crop",
          "thumbnail_url":
              "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=400&auto=format&fit=crop",
          "taken_time": "2026-02-27T10:15:00+07:00",
          "visit_day_label": "1 week ago",
          "is_latest": false,
          "nurse_note": "Earlier visit. Wound looked smaller and cleaner.",
          "uploaded_by": "nurse_001",
          "patient_snapshot": {
            "patient_id": "PAT-001",
            "patient_name": "PAWMAN",
            "phone_no": "0861948565",
            "dob": "2001-02-03",
            "age": 25,
            "gender": "male",
            "height_cm": 170,
            "weight_kg": 60,
            "occupation": "Data Analysis",
            "medical_history": ["Diabetes"],
            "diabetes_flag": true,
            "comorbidities": ["Diabetes"],
            "allergies": [],
            "created_at": "2026-01-28T11:33:20+07:00"
          },
          "wound_snapshot": {
            "review_id": "NR-ULC-9283-000",
            "case_id": "ULC-9283",
            "location_primary": "toe",
            "location_detail": "plantar aspect of the great toe",
            "laterality": "right",
            "wound_type": "ulcer",
            "shape": "round",
            "size_width_cm": 1.1,
            "size_length_cm": 1.0,
            "area_cm2": 1.10,
            "depth_category": "partial_thickness",
            "bed_granulation_pct": 92,
            "bed_slough_pct": 5,
            "bed_necrotic_pct": 0,
            "edge_description": "attached",
            "periwound_status": "mild pink",
            "discharge_volume": "minimal",
            "discharge_type": "serous",
            "odor_presence": "none",
            "pain_score": 2,
            "has_infection": false,
            "skin_condition": "dry",
            "temperature_c": 36.7,
            "blood_pressure": "118/78",
            "heart_rate": 76,
            "respiratory_rate": 18,
            "blood_glucose_mg_dl": 140,
            "mobility_status": "walks independently",
            "offloading_in_place": true,
            "nurse_note":
                "Wound bed mostly clean. Healthy granulation noted. Minimal pain.",
            "captured_by": "nurse_001",
            "captured_at": "2026-02-27T10:15:00+07:00"
          },
          "ai_snapshot": {
            "analysis_id": "AI-ULC-9283-OLD-001",
            "case_id": "ULC-9283",
            "creator": "Gemini AI",
            "model_version": "v1.2.0",
            "draft_status": "READY",
            "wound_stage": "STAGE 2",
            "diagnosis":
                "Healing diabetic foot ulcer on the plantar aspect of the great toe.",
            "confidence": 0.91,
            "description":
                "Smaller wound area with healthy granulation and minimal slough. Healing trend appears favorable.",
            "treatment_suggestion":
                "Continue offloading, moist wound care, and routine follow-up.",
            "healing_progress": "improving",
            "created_at": "2026-02-27T10:18:00+07:00"
          }
        },
        {
          "image_id": "IMG-ULC-9283-003",
          "case_id": "ULC-9283",
          "image_url":
              "https://images.unsplash.com/photo-1584515933487-779824d29309?q=80&w=1200&auto=format&fit=crop",
          "thumbnail_url":
              "https://images.unsplash.com/photo-1584515933487-779824d29309?q=80&w=400&auto=format&fit=crop",
          "taken_time": "2026-03-06T09:40:00+07:00",
          "visit_day_label": "Today",
          "is_latest": true,
          "nurse_note":
              "Wound appears deeper than last week. Mild redness still present.",
          "uploaded_by": "nurse_001",
          "patient_snapshot": {
            "patient_id": "PAT-001",
            "patient_name": "PAWMAN",
            "phone_no": "0861948565",
            "dob": "2001-02-03",
            "age": 25,
            "gender": "male",
            "height_cm": 170,
            "weight_kg": 60,
            "occupation": "Data Analysis",
            "medical_history": ["Diabetes"],
            "diabetes_flag": true,
            "comorbidities": ["Diabetes"],
            "allergies": [],
            "created_at": "2026-01-28T11:33:20+07:00"
          },
          "wound_snapshot": {
            "review_id": "NR-ULC-9283-001",
            "case_id": "ULC-9283",
            "location_primary": "toe",
            "location_detail": "plantar aspect of the great toe",
            "laterality": "right",
            "wound_type": "ulcer",
            "shape": "round",
            "size_width_cm": 1.5,
            "size_length_cm": 1.5,
            "area_cm2": 2.25,
            "depth_category": "full_thickness",
            "bed_granulation_pct": 85,
            "bed_slough_pct": 10,
            "bed_necrotic_pct": 5,
            "edge_description": "calloused",
            "periwound_status": "erythematous",
            "discharge_volume": "minimal",
            "discharge_type": "serous",
            "odor_presence": "faint",
            "pain_score": 4,
            "has_infection": false,
            "skin_condition": "dry",
            "temperature_c": 37.0,
            "blood_pressure": "120/80",
            "heart_rate": 80,
            "respiratory_rate": 18,
            "blood_glucose_mg_dl": 148,
            "mobility_status": "walks independently",
            "offloading_in_place": false,
            "nurse_note":
                "Patient reports mild pain while walking. Wound appears deeper than last week. Periwound redness present.",
            "captured_by": "nurse_001",
            "captured_at": "2026-03-06T09:40:00+07:00"
          },
          "ai_snapshot": {
            "analysis_id": "AI-ULC-9283-001",
            "image_id": "IMG-ULC-9283-003",
            "case_id": "ULC-9283",
            "creator": "Gemini AI",
            "model_version": "v1.2.0",
            "draft_status": "READY",
            "wound_stage": "STAGE 3",
            "diagnosis":
                "Diabetic foot ulcer on the plantar aspect of the great toe with surrounding erythema.",
            "confidence": 0.75,
            "description":
                "Full-thickness ulcer with minor necrotic tissue and erythema around the wound.",
            "treatment_suggestion":
                "Focus on offloading, debridement, moist wound environment, infection monitoring.",
            "healing_progress": "stable",
            "created_at": "2026-03-06T09:43:00+07:00"
          }
        }
      ],
      "permissions": {
        "can_edit_ai_review": true,
        "can_create_treatment_plan": true,
        "can_send_plan": true,
        "latest_image_id": "IMG-ULC-9283-003"
      }
    }
  },
  "meta": {
    "version": "v1",
    "pagination": null
  },
  "error": null
};