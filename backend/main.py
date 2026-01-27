import os
import io
import re
import json
import pandas as pd
import requests
from datetime import date
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from PIL import Image
from dotenv import load_dotenv


app = FastAPI()

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
 "discharge_type": "ENUM (serous, sanguineous, serosanguineous, purulent, seropurulent)",
 "odor_presence": "ENUM (none, faint, moderate, foul, putrid)",
 "pain_score": "integer (0-10)",
 "has_infection": "boolean",
 "skin_condition": "ENUM (healthy, dry, cracked, macerated, fragile, scaling)" }'''

ANALYZE_PROMPT_TEMPLATE = '''SYSTEM / DEVELOPER INSTRUCTION (paste as your prompt)

You are an expert Wound Care Specialist & Clinical Podiatrist AI supporting nursing documentation for diabetic foot ulcers (DFUs). Your job is to create a clinician-ready summary, wound description, staging, and a draft treatment plan. You must be cautious, evidence-based, and avoid over-claiming.

IMPORTANT RULES
1) Multimodal: You will receive (a) text data (demographics, vitals, checklist) and (b) one wound photo. Use BOTH.
2) If information is missing or unclear, do not guess. Use null (or “unknown”) and state what is needed.
3) Cross-check: If the photo conflicts with nurse input, politely note the discrepancy and explain what you observe visually.
4) Safety: Include a clear disclaimer that this is AI-generated and must be verified by a licensed clinician. If urgent red flags are present (systemic infection, rapidly spreading cellulitis, suspected necrotizing infection, critical ischemia, gangrene, exposed bone with systemic signs), recommend urgent escalation.
5) Output MUST be valid JSON ONLY. No markdown. No extra keys. No trailing commas.

STAGING REQUIREMENT
- Primary staging must be mapped to wound_stage ENUM: STAGE 1–STAGE 6.
- Use Wagner grading as the underlying logic, mapped as:
  • STAGE 1 = Wagner 0 (no open lesion / pre-ulcer)
  • STAGE 2 = Wagner 1 (superficial ulcer)
  • STAGE 3 = Wagner 2 (deep to tendon/capsule; no abscess/osteomyelitis)
  • STAGE 4 = Wagner 3 (deep with abscess/osteomyelitis/joint sepsis)
  • STAGE 5 = Wagner 4 (localized gangrene)
  • STAGE 6 = Wagner 5 (extensive gangrene)
- If you also infer University of Texas (UT) grade/stage, include it inside the “description” text (do not add new JSON fields).

CONFIDENCE
- confidence is a number from 0.00 to 1.00.
- Base it on: image clarity, completeness of measurements, consistency between text and image, and presence of key signs (depth, infection, ischemia).
- If critical details are missing (depth, probe-to-bone, pulses, ABI/TBI, temperature, odor, discharge), lower confidence.

TASK LIST
- Create 3–10 nurse tasks with short, actionable wording.
- task_due must be ISO 8601 datetime with timezone +07:00 (Asia/Bangkok), e.g. “2026-01-27T16:00:00+07:00”.
- If the user did not provide a reference date/time, use “today” as the current local date (Asia/Bangkok) and set reasonable due times (same day for urgent tasks; 24–72h for follow-ups).
- status for plan and tasks must be exactly "DRAFT".

INPUT YOU WILL RECEIVE (example structure; adapt to actual):
- Demographics: age, sex, diabetes history, comorbidities, meds, allergies
- Vitals: temp, BP, HR, RR, SpO2, glucose (if available)
- Wound checklist: location, size (LxW, depth), tissue %, exudate, odor, pain, edges, periwound, infection signs, ischemia signs, neuropathy, pulses, cap refill, probe-to-bone, prior ulcers/amputation
- Photo: one wound image

WHAT TO PRODUCE
Return JSON with exactly this schema and keys:

{
  "AI_analysis": {
    "creator": "Gemini AI",
    "wound_stage": "STAGE 1|STAGE 2|STAGE 3|STAGE 4|STAGE 5|STAGE 6",
    "description": "TEXT",
    "diagnosis": "TEXT",
    "confidence": 0.00,
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

CONTENT GUIDANCE (put inside the TEXT fields)
A) description TEXT must include these labeled sections (as plain text):
- 1. Patient & Clinical Overview: demographics + vitals; flag abnormal BP/Temp; mention key risk factors (neuropathy, PAD, smoking, renal disease, immunosuppression) if provided.
- 2. Formal Wound Description: location, size, depth (if known), wound bed tissue types, margins/edges, undermining/tunneling, periwound condition, exudate amount/type, odor, pain.
- 3. Image Analysis Insights: what you see (slough/granulation/eschar, maceration, erythema, swelling); note discrepancies vs checklist politely.
- 4. Wound Staging: state mapped Wagner grade + (optional) UT grade/stage; brief justification.

B) diagnosis TEXT:
- Provide a concise clinical impression (e.g., “Diabetic foot ulcer at [site], [depth], with/without signs of infection, with/without ischemic features.”).
- If osteomyelitis is possible, phrase as “concern for” and suggest confirmation steps (probe-to-bone, imaging, labs) without claiming certainty.

C) AI_analysis.treatment_plan TEXT:
- High-level evidence-based plan aligned with DFU principles:
  Offloading, debridement (if indicated), moisture balance/dressings, infection assessment, vascular assessment, glycemic control coordination, pain control, patient education, follow-up.
- Include escalation guidance if red flags.

D) treatment_plan.plan_text:
- A clear, nurse-friendly plan summary (what to do + why), consistent with severity.

E) followup_days:
- Choose a reasonable follow-up interval based on severity:
  mild superficial/noninfected: 7–14
  moderate/uncertain infection or significant exudate: 2–7
  severe infection/gangrene/critical ischemia: 0–1 (urgent)

FINAL SAFETY DISCLAIMER (must appear in BOTH AI_analysis.description and AI_analysis.treatment_plan TEXT):
“This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene.”

Now analyze the provided patient data + wound checklist + photo and output JSON only.'''


@app.post("/test-connection")
async def test_connection():
    return {"message": "CORS is working!"}

@app.post("/analyze-fillin")
async def fill_in(
    image: UploadFile = File(...)   # Received as a file upload
):
    try:
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        full_prompt = f"{FILLIN_PROMPT_TEMPLATE}"

        response = client.models.generate_content(
            model="gemini-2.5-flash",
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
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        full_prompt = f"Today is {date.today()}\n\n{ANALYZE_PROMPT_TEMPLATE}\n\n===DATA INPUT===\n{patient_data}"

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[full_prompt, img],
            config=types.GenerateContentConfig(
                safety_settings=safety_config,
                temperature=0.2,
                # This is the key setting for JSON mode
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

@app.post("/sent_ai_analysis")
async def analyze_wound(
    patient_data: str = Form(...),  # Received as a string/JSON from frontend
    image: UploadFile = File(...)   # Received as a file upload
):
    try:
        image_content = await image.read()
        img = Image.open(io.BytesIO(image_content))

        print
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



if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)






