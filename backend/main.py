import os
import io
import re
import json
import pandas as pd
import requests
import uuid
import datetime
from datetime import date
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from PIL import Image
from dotenv import load_dotenv

genai_model = "gemini-2.0-flash"
app = FastAPI()

#---------- FUNCTION ---------------#
def generate_patient_id(df_patients):

# 1. Get current YYMM prefix (e.g., "2601")
    current_prefix = date.today().strftime("%y%m")
    prefix_label = "PT" 
    
    # 2. Check if the DataFrame is empty
    if df_patients.empty:
        return f"{prefix_label}-{current_prefix}-00001"
    
    # 3. Get the last patient_id from the last row
    last_id = str(df_patients['patient_id'].iloc[-1])
    
    try:
        parts = last_id.split('-')
        last_date_part = parts[1]        
        last_running_num = int(parts[2]) 
        
        # 4. Check if same month
        if last_date_part == current_prefix:
            new_running_num = last_running_num + 1
        else:
            new_running_num = 1
            
    except (IndexError, ValueError):
        # Fallback if the last_id format was corrupted
        new_running_num = 1

    # 5. Format the new code
    new_code = f"{prefix_label}-{current_prefix}-{new_running_num:05d}"
    return new_code


#---- READ (MOCK UP) DATABASE ------#

df_patients_path="C:/Users/Pawarit/Desktop/GitHub/Foster-Ulcer-AI/Foster-Ulcer-AI/mockup_data/patients.csv"
df_wound_cases_path="C:/Users/Pawarit/Desktop/GitHub/Foster-Ulcer-AI/Foster-Ulcer-AI/mockup_data/wound_cases.csv"
df_ai_analysis_path = "C:/Users/Pawarit/Desktop/GitHub/Foster-Ulcer-AI/Foster-Ulcer-AI/mockup_data/ai_analysis.csv"
df_treatment_plan_path = "C:/Users/Pawarit/Desktop/GitHub/Foster-Ulcer-AI/Foster-Ulcer-AI/mockup_data/treatment_plan.csv"
df_plan_task_path= "C:/Users/Pawarit/Desktop/GitHub/Foster-Ulcer-AI/Foster-Ulcer-AI/mockup_data/plan_task.csv"


df_patients = pd.read_csv(df_patients_path)
df_wound_cases = pd.read_csv(df_wound_cases_path)
df_ai_analysis = pd.read_csv(df_ai_analysis_path)
df_treatment_plan = pd.read_csv(df_treatment_plan_path)
df_plan_task = pd.read_csv(df_plan_task_path)


#-----------------------------------#

# --- CORS CONFIGURATION ---
# You can specify the exact port Flutter is running on, 
# or use ["*"] to allow everything during development.
origins = [
    "http://localhost:55351",
    "http://127.0.0.1:55351",
    "http://localhost", # Useful if port changes
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],           # Allow any origin
    allow_methods=["*"],           # Allow all methods (POST, OPTIONS, etc.)
    allow_headers=["*"],           # Allow all headers
    allow_credentials=False,       # Set to False when using allow_origins=["*"]
)

# Load environment variables
load_dotenv()
my_key = os.getenv("GEMINI_API_KEY")

# Initialize FastAPI and Gemini Client
app = FastAPI(title="Wound Care AI Analysis API")
client = genai.Client(api_key=my_key)

# Define Safety Config
safety_config = [
    types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_NONE"),
]

FILLIN_PROMPT_TEMPLATE ='''Role: You are an expert Wound Care Specialist and Clinical Podiatrist.

Task: Analyze the attached image of the foot ulcer and provide a clinical assessment. Your output must be in a strict JSON format using the schema provided below.

Constraints:

For measurements (width/length), provide estimates based on visual scale if a ruler is present; otherwise, label as "estimated."

Use only the ENUM values provided in the schema.

If a value cannot be determined from the image (like pain or odor), provide a "best-fit" clinical estimate based on the wound morphology and note it as such.

No Newlines: The entire output must be on one single line. Do not use \n or line breaks.

JSON Only: Do not include any conversational text or markdown code blocks (no ```json). Output only the raw string.


JSON Schema / Fields to Fill: 
{ "location_primary": "ENUM (toe, sole, side, heel, dorsal_aspect, medial_malleolus, lateral_malleolus)",
 "location_detail": "string",
 "wound_type": "string",
 "shape": "ENUM (round, oval, irregular, linear, punched_out)",
 "size_width_cm": "float",
 "size_length_cm": "float",
 "depth_category": "ENUM (superficial, partial_thickness, full_thickness, deep, very_deep_exposed_bone_tendon)",
 "bed_slough_pct": "integer",
 "bed_necrotic_pct": "integer",
 "edge_description": "ENUM (smooth, thickened, irregular, rolled_epibole, undermined, calloused)",
 "periwound_status": "ENUM (normal, erythematous, edematous, indurated, macerated, fluctuant, hyperpigmented)",
 "discharge_volume": "ENUM (none, minimal, moderate, heavy)",
 "discharge_type": "ENUM ("serous (clear)", "sanguineous (bloody)", "serosanguineous (pink)", "purulent (yellow/pus)", "seropurulent (cloudy yellow)")",
 "odor_presence": "ENUM (none, faint, moderate, foul, putrid)",
 "pain_score": "integer (0-10)",
 "has_infection": "boolean",
 "skin_condition": "ENUM (healthy, dry, cracked, macerated, fragile, scaling)" }'''
   
ANALYZE_PROMPT_TEMPLATE = '''Role: You are an expert Wound Care Specialist & Clinical Podiatrist AI supporting nursing documentation for diabetic foot ulcers (DFUs). Your job is to create a clinician-ready summary, wound description, staging, and a draft treatment plan. You must be cautious, evidence-based, and avoid over-claiming.

IMPORTANT RULES
1) Multimodal: You will receive (a) structured patient text data and nurse checklist and (b) one wound photo. Use BOTH.
2) If information is missing or unclear, do not guess. Use JSON null for unknown numeric/boolean values and the string "unknown" for unknown text. Do not invent data.
3) Cross-check: If the photo conflicts with nurse input, politely note the discrepancy and explain what you observe visually.
4) Safety: Include a clear disclaimer that this is AI-generated and must be verified by a licensed clinician. If urgent red flags are present (systemic infection, rapidly spreading cellulitis, suspected necrotizing infection, critical ischemia, gangrene, exposed bone with systemic signs), recommend urgent escalation.
5) NO PRESCRIBING: Do not prescribe or give dosing. Do not name specific antibiotics unless they are explicitly provided in the input; instead say “consider per clinician/local protocol.”
6) JSON STRICTNESS:
   - Output MUST be valid JSON ONLY. No markdown. No code fences. No extra text.
   - Output must start with { and end with }.
   - Use exactly the schema/keys provided below. No extra keys. No trailing commas.

PRIMARY STAGING REQUIREMENT — UNIVERSITY OF TEXAS (UT)
- Use the University of Texas Diabetic Foot Ulcer Classification as the PRIMARY staging logic.
- UT consists of **Grade (0–3 depth)** and **Stage (A–D infection/ischemia)**.

UT GRADES (DEPTH)
• Grade 0 = Pre/post ulcerative lesion; skin intact
• Grade 1 = Superficial wound; not involving tendon/capsule/bone
• Grade 2 = Wound penetrating to tendon or capsule
• Grade 3 = Wound penetrating to bone or joint

UT STAGES (INFECTION / ISCHEMIA)
• Stage A = Non-infected, non-ischemic
• Stage B = Infected
• Stage C = Ischemic
• Stage D = Infected AND ischemic

STAGING DECISION RULES
- If no open lesion → Grade 0.
- If open ulcer and depth unknown but no deep structure visible → default Grade 1 with lower confidence.
- Visible tendon/joint capsule OR sinbad_depth deep OR probe-to-bone positive → at least Grade 2.
- Bone visible / probe-to-bone positive / joint exposure → Grade 3.
- Use infection_checklist + sinbad_infection + exudate/pus to infer Stage B.
- Use ischemia_points + pulse absence + color/capillary refill indicators to infer Stage C.
- Use Stage D ONLY when BOTH infection and ischemia evidence are present.
- If uncertain between B/C/D → choose safer higher stage but explain uncertainty inside TEXT.

CONFIDENCE
- confidence is a number from 0.00 to 1.00.
- Start at 0.80 then subtract:
  -0.15 if image is unclear/poor lighting/out of focus
  -0.10 if wound size missing
  -0.15 if depth/probe-to-bone missing
  -0.10 if infection indicators missing
  -0.10 if ischemia indicators missing
  -0.10 if notable text-image discrepancy
- Clamp final confidence to [0.05, 0.95].

TASK LIST
- Create 3–10 nurse tasks with short actionable wording.
- task_due must be ISO 8601 datetime timezone +07:00.
- If no reference datetime → assume Asia/Bangkok today.
- urgent = same day 16:00, routine = next day 10:00, 48–72h = day +2/+3 10:00.
- status must always be "DRAFT".

INPUT YOU WILL RECEIVE
- patient_profile
- selected_patient
- nurse_reviewed
- ai_prefill
- wound photo

WHAT TO PRODUCE
Return JSON with exactly this schema:

{
  "AI_analysis": {
    "creator": "Gemini AI",
    "wound_stage": "TEXT",
    "description": "TEXT",
    "diagnosis": "TEXT",
    "confidence": 0.00,
    "red_flag": BOOLEAN
    "treatment_plan": "TEXT"
  },
  "treatment_plan": {
    "plan_text": "TEXT",
    "followup_days": 0,
    "status": "DRAFT",
    "plan_tasks": [
      {
        "task_text": "TEXT",
        "status": "DRAFT",
        "task_due": "YYYY-MM-DDTHH:MM:SS+07:00"
      }
    ]
  }
}

NOTE:
- wound_stage TEXT must contain UT result formatted like:
  "UT Grade 2 Stage B"

PLAN FIELD CONSISTENCY
- AI_analysis.treatment_plan = clinician-facing rationale.
- treatment_plan.plan_text = nurse-facing condensed action summary.

CONTENT GUIDANCE (inside TEXT fields)

A) description TEXT must include labeled sections:
1. Patient & Clinical Overview
2. Formal Wound Description
3. Image Analysis Insights
4. Wound Staging → MUST state UT Grade + Stage + justification
5. Red Flags

B) diagnosis TEXT:
- Concise clinical impression.
- Use “concern for osteomyelitis” phrasing if uncertain.

C) AI_analysis.treatment_plan TEXT:
- Evidence-based DFU principles only.
- No dosing, no antibiotic naming.

D) treatment_plan.plan_text:
- Nurse-friendly summary consistent with severity.

E) followup_days guideline:
mild = 7–14  
moderate = 2–7  
severe = 0–1  

FINAL SAFETY DISCLAIMER (MUST appear in BOTH description and treatment_plan TEXT)
“This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene.”

Now analyze the provided patient data + wound checklist + photo and output JSON only.'''


@app.post("/load-dashboard")
async def load_dashboard():
    
    return {"message": "CORS is working!"}

@app.post("/create-patient-profile")
async def create_patient_profile(
    patient_data: str = Form(...),
    image: UploadFile = File(None)
):
    global df_patients # Required to update the global DataFrame
    try:
        # Decode JSON string
        data = json.loads(patient_data)

        if not data.get("phone_no", "").strip():
            raise HTTPException(status_code=400, detail="phone_no is required")

        ## generate patient_id
        patient_id = generate_patient_id(df_patients)
        created_at = data.get("created_at") or datetime.utcnow().isoformat()

        data["patient_id"] = patient_id
        data["created_at"] = created_at

        ## insert new record
        record = {
            "patient_id": patient_id,
            "patient_name": data.get("patient_name"),
            "phone_no": data.get("phone_no"),
            "dob": data.get("dob"),
            "gender": data.get("gender"),
            "height_cm": str(data.get("height_cm", "")).strip(),
            "weight_kg": str(data.get("weight_kg", "")).strip(),
            "status": 'Active',
            "medical_history": data.get("medical_history"),
            "image_url": None, # You can handle file saving logic here to update this
            "created_by": "admin",
            "created_at": created_at,
        }
        
        # Correctly update the global DataFrame
        new_row = pd.DataFrame([record])
        df_patients = pd.concat([df_patients, new_row], ignore_index=True)

        df_patients.to_csv(df_patients_path,index=False)

        print("create-patient-profile success for:", patient_id)

        return {
            "status": "success",
            "patient_id": patient_id,
            "patient_profile": data,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze-fillin")
async def fill_in(
    image: UploadFile = File(...)   # Received as a file upload
):
    try:
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        full_prompt = f"{FILLIN_PROMPT_TEMPLATE}"

        response = client.models.generate_content(
            model=genai_model,
            contents=[full_prompt, img],
            config=types.GenerateContentConfig(
                safety_settings=safety_config,
                temperature=0.2,
                response_mime_type="application/json"
            )
        )

        # 4. Handle Response
        if response.candidates:
            data_dict = json.loads(response.text)
            df = pd.DataFrame([data_dict])
            print(df)
            raw_text = response.text.strip().replace("```json", "").replace("```", "")
            data_dict = json.loads(raw_text)
            return {"status": "success", "analysis": data_dict}
        else:
            return {
                "status": "blocked", 
                "reason": str(response.prompt_feedback.block_reason)
            }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze-wound")
async def analyze_wound(
    patient_data: str = Form(...),  # Received as a string/JSON from frontend
    image: UploadFile = File(...)   # Received as a file upload
):
    try:
        print(f"Sending this payload for wound analyzing: {patient_data}")
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        full_prompt = f"Today is {date.today()}\n\n{ANALYZE_PROMPT_TEMPLATE}\n\n===DATA INPUT===\n{patient_data}"

        response = client.models.generate_content(
            model=genai_model,
            contents=[full_prompt, img],
            config=types.GenerateContentConfig(
                safety_settings=safety_config,
                temperature=0.2,
                response_mime_type="application/json"
            )
        )

        # 4. Handle Response
        if response.candidates:
            print(response.text)
            return {"status": "success", "analysis": response.text}
        else:
            return {
                "status": "blocked", 
                "reason": str(response.prompt_feedback.block_reason)
            }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/create-case")
async def create_case(
    case_data: str = Form(...),  # Received as a string/JSON from frontend
    image: UploadFile = File(...)   # Received as a file upload
):
    try:
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        print(case_data)
        img.show()

        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)






