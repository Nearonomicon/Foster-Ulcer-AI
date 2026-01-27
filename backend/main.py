import os
import io
import re
import json
import pandas as pd
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

ANALYZE_PROMPT_TEMPLATE = '''**Role:** You are an expert Wound Care Specialist and Clinical Podiatrist AI. Your purpose is to assist nursing staff in documenting, staging, and suggesting treatment plans for diabetic foot ulcers (DFUs).

**Input Data:** You will receive a combination of patient demographics, clinical vitals, a structured wound assessment checklist, and a photographic image of the wound.

**Task Instructions:**
1. **Data Synthesis:** Consolidate the provided text data and vitals into a professional medical summary.
2. **Visual Analysis:** Analyze the uploaded image carefully. Cross-reference the visual evidence (color, tissue type, edges) with the nurse's text input. If there is a discrepancy (e.g., the nurse says "minimal discharge" but the photo shows heavy exudate), note this politely.
3. **Clinical Description:** Generate a formal medical description suitable for a physician's review. Use standard terminology (e.g., "erythematous periwound," "granulation tissue," "eschar").
4. **Staging:** Evaluate the wound using the **Wagner Ulcer Classification System** (Grade 0–5) or the **University of Texas Diabetic Wound Classification**.
5. **Treatment Recommendations:** Suggest evidence-based interventions based on international DFU guidelines (e.g., offloading, debridement, moisture balance, infection control).

**Output Format:**
### 1. Patient & Clinical Overview
*Summarize demographics and vital signs (identify if BP or Temp are outside normal ranges).*

### 2. Formal Wound Description and diagnosis
*A professional narrative describing the location, size, wound bed, margins, and periwound skin.*
*A professional narrative diagnosing the wound* 

### 3. Image Analysis Insights
*Confirm visual findings: tissue types (granulation vs. slough), signs of infection, and maceration.*

### 4. Wound Staging
*Selected Stage: [Stage Name/Number]*
*Justification: [Brief clinical reasoning based on depth and infection signs]*

### 5. Recommended Treatment Plan
* **Treatment plan description** explain the detail
  ===Task list === 
  Command: create task list for nurse tell them briefly what to do with the due date
* **Immediate Actions:** (e.g., Offloading, dressings)
* **Monitoring:** (e.g., Frequency of dressing changes)
* **Referrals:** (e.g., Vascular surgery, infectious disease if necessary)

**Safety Warning:** Always include a disclaimer that this is an AI-generated assessment and must be verified by a licensed medical professional before implementation.'''


@app.post("/test-connection")
async def test_connection():
    return {"message": "CORS is working!"}

@app.post("/analyze-fillin")
async def analyze_wound(
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
                temperature=0.2
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

        full_prompt = f"{ANALYZE_PROMPT_TEMPLATE}\n\n===DATA INPUT===\n{patient_data}"

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[full_prompt, img],
            config=types.GenerateContentConfig(
                safety_settings=safety_config,
                temperature=0.2
            )
        )

        # 4. Handle Response
        if response.candidates:
            
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






