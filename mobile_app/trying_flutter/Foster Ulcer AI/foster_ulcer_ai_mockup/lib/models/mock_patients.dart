List<Map<String, dynamic>> buildMockPatients() {
  return [
    {
      "id": "PT-1002",
      "name": "John Smith",
      "age": 68,
      "gender": "male",
      "stage": "Wagner 3",
      "priority": "Critical",
      "urgency": "high_urgent",
      "status": "In Treatment",
      "date": "2026-01-28",
      "image": "https://upload.wikimedia.org/wikipedia/commons/4/41/DMgas_gangrene.jpg",
      "todos": [
        {
          "task": "Apply antimicrobial dressing",
          "completed": false,
          "due": "Today, 4:00 PM",
          "urgent": true
        },
      ],
      "nurse_reviewed": {
        "temperature": "37.8",
        "blood_pressure": "145/95",
        "heart_rate": "92",
        "location_primary": "heel",
        "location_detail": "Lateral side of left heel",
        "wound_type": "Diabetic Foot Ulcer",
        "shape": "irregular",
        "size_width_cm": "4.2",
        "size_length_cm": "3.5",
        "depth_category": "full_thickness",
        "bed_slough_pct": "25",
        "bed_necrotic_pct": "10",
        "edge_description": "undermined",
        "periwound_status": "erythematous",
        "discharge_volume": "moderate",
        "discharge_type": "sanguineous (bloody)",
        "odor_presence": "moderate",
        "pain_score": "8",
        "has_infection": true,
        "skin_condition": "dry",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 3",
          "diagnosis": "Deep diabetic foot ulcer with active infection.",
          "confidence": 0.88,
          "description":
              "Deep tissue involvement reaching fascia. Slough covers 25% of bed. Active purulent discharge.",
        },
        "treatment_plan": {
          "plan_text": "Sharp debridement. Silver dressing. Oral Clindamycin. Vascular consult.",
          "plan_tasks": [
            {
              "task_text": "Apply silver dressing",
              "task_due": "2026-01-28T16:00:00",
              "status": "Urgent"
            },
            {
              "task_text": "Check glycemic levels",
              "task_due": "2026-01-28T14:00:00",
              "status": "Pending"
            },
          ],
        },
      }
    },
    {
      "id": "PT-3091",
      "name": "Rahul Sharma",
      "age": 71,
      "gender": "male",
      "stage": "Wagner 2",
      "priority": "Medium",
      "urgency": "medium",
      "status": "Stable",
      "date": "2026-01-27",
      "image": "https://www.saakhealth.com/wp-content/uploads/2024/10/Image20241008065706.png",
      "todos": [
        {
          "task": "Prepare for surgical referral",
          "completed": false,
          "due": "ASAP",
          "urgent": true
        },
      ],
      "nurse_reviewed": {
        "temperature": "36.8",
        "blood_pressure": "122/82",
        "heart_rate": "72",
        "location_primary": "sole",
        "location_detail": "1st metatarsal head",
        "wound_type": "Neuropathic Ulcer",
        "shape": "round",
        "size_width_cm": "2.0",
        "size_length_cm": "2.2",
        "depth_category": "partial_thickness",
        "bed_slough_pct": "0",
        "bed_necrotic_pct": "0",
        "edge_description": "smooth",
        "periwound_status": "normal",
        "discharge_volume": "minimal",
        "discharge_type": "serous",
        "odor_presence": "none",
        "pain_score": "2",
        "has_infection": false,
        "skin_condition": "healthy",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 2",
          "diagnosis": "Superficial neuropathic ulcer.",
          "confidence": 0.94,
          "description": "Healthy granulation tissue. No signs of localized infection.",
        },
        "treatment_plan": {
          "plan_text": "Saline cleaning. Hydrocolloid dressing. Pressure offloading.",
          "plan_tasks": [
            {
              "task_text": "Clean with saline",
              "task_due": "2026-01-28T09:00:00",
              "status": "Completed"
            },
          ],
        },
      }
    },
    {
      "id": "PT-4022",
      "name": "Sita Devi",
      "age": 62,
      "gender": "female",
      "stage": "Wagner 1",
      "priority": "Routine",
      "urgency": "routine",
      "status": "Stable",
      "date": "2026-01-26",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQq3gdPb0H4GwIzPsWw4L3AVtoQAGck3uX9Gg&s",
      "todos": [
        {
          "task": "Apply moisturizer",
          "completed": true,
          "due": "Completed",
          "urgent": false
        },
      ],
      "nurse_reviewed": {
        "temperature": "36.6",
        "blood_pressure": "118/76",
        "heart_rate": "70",
        "location_primary": "toe",
        "location_detail": "Great toe lateral",
        "wound_type": "Neuropathic Ulcer",
        "shape": "oval",
        "size_width_cm": "1.2",
        "size_length_cm": "1.5",
        "depth_category": "superficial",
        "bed_slough_pct": "0",
        "bed_necrotic_pct": "0",
        "edge_description": "smooth",
        "periwound_status": "normal",
        "discharge_volume": "none",
        "discharge_type": "none",
        "odor_presence": "none",
        "pain_score": "1",
        "has_infection": false,
        "skin_condition": "healthy",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 1",
          "diagnosis": "Minor skin break.",
          "confidence": 0.98,
          "description": "Routine maintenance case with no depth or exudate.",
        },
        "treatment_plan": {
          "plan_text": "Monitor daily. Apply urea cream for hydration.",
          "plan_tasks": [
            {
              "task_text": "Apply urea cream",
              "task_due": "2026-01-30T10:00:00",
              "status": "Pending"
            },
          ],
        },
      }
    }
  ];
}
