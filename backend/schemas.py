from datetime import datetime
from enum import Enum
from typing import List, Optional, Union

from pydantic import BaseModel, Field


# -----------------------------
# ENUMS
# -----------------------------

class Status(str, Enum):
    CREATION = "CREATION"
    AI_PROCESSING = "AI_PROCESSING"
    DOCTOR_REVIEW = "DOCTOR_REVIEW"
    PLAN_ISSUED = "PLAN_ISSUED"
    TREATMENT_ACTIVE = "TREATMENT_ACTIVE"
    APPOINTMENT = "APPOINTMENT"
    COMPLETED = "COMPLETED"


class Urgency(str, Enum):
    URGENT = "URGENT"
    MEDIUM = "MEDIUM"
    ROUTINE = "ROUTINE"


class Shape(str, Enum):
    round = "round"
    oval = "oval"
    irregular = "irregular"
    linear = "linear"
    punched_out = "punched_out"


class DepthCategory(str, Enum):
    superficial = "superficial"
    partial_thickness = "partial_thickness"
    full_thickness = "full_thickness"
    deep = "deep"
    very_deep_exposed_bone_tendon = "very_deep_exposed_bone_tendon"


class WIfI(BaseModel):
    wound_grade: Optional[int] = Field(default=None, ge=0, le=3)
    ischemia_grade: Optional[int] = Field(default=None, ge=0, le=3)
    infection_grade: Optional[int] = Field(default=None, ge=0, le=3)
    clinical_stage: Optional[int] = Field(default=None, ge=0, le=4)


class SINBAD(BaseModel):
    site: Optional[int] = Field(default=None, ge=0, le=1)
    ischemia: Optional[int] = Field(default=None, ge=0, le=1)
    neuropathy: Optional[int] = Field(default=None, ge=0, le=1)
    infection: Optional[int] = Field(default=None, ge=0, le=1)
    area: Optional[int] = Field(default=None, ge=0, le=1)
    depth: Optional[int] = Field(default=None, ge=0, le=1)
    total: Optional[int] = Field(default=None, ge=0)


# -----------------------------
# NESTED MODELS
# -----------------------------


class DiabetesInfo(BaseModel):
    has_diabetes: str
    years: Optional[str] = None
    risk_history: List[str] = []
    complications: List[str] = []

    @property
    def is_diabetic_bool(self) -> bool:
        return self.has_diabetes.lower() == "yes"


class PatientSchema(BaseModel):
    patient_name: str
    phone_no: str
    dob: str
    gender: str
    height_cm: Union[str, float]
    weight_kg: Union[str, float]
    medical_history: str
    diabetes: DiabetesInfo
    created_at: str
    status: str = "Active"


class Size(BaseModel):
    width_cm: Optional[float]
    length_cm: Optional[float]


class Bed(BaseModel):
    slough_pct: Optional[int]
    necrotic_pct: Optional[int]


class Discharge(BaseModel):
    volume: Optional[str]
    type: Optional[str]


class VitalSigns(BaseModel):
    temperature: Optional[str]
    blood_pressure: Optional[str]
    blood_glucose: Optional[str]
    heart_rate: Optional[str]
    respiratory_rate: Optional[str]


class WoundDetail(BaseModel):
    location_primary: Optional[str]
    location_detail: Optional[str]
    wound_type: Optional[str]

    shape: Optional[Shape]

    size: Size
    depth_category: Optional[DepthCategory]

    bed: Bed

    edge_description: Optional[str]
    periwound_status: Optional[str]

    discharge: Discharge
    odor_presence: Optional[str]

    pain_score: Optional[int]
    has_infection: Optional[bool]

    skin_condition: Optional[str]


class Ischemia(BaseModel):
    points: List[int] = []
    pulse: Optional[str]
    checklist: List[str] = []


class Infection(BaseModel):
    checklist: List[str] = []
    erythema_extent: Optional[str]
    probe_to_bone_test: Optional[str]
    has_deep_abscess_or_fasciitis: Optional[str]


class Neuropathy(BaseModel):
    points: List[int] = []


class Sinbad(BaseModel):
    site: Optional[str]
    ischemia: Optional[str]
    neuropathy: Optional[str]
    infection: Optional[str]
    area: Optional[str]
    depth: Optional[str]


class LabResults(BaseModel):
    wbc_count: Optional[str]
    crp: Optional[str]
    esr: Optional[str]
    procalcitonin: Optional[str]


class Vascular(BaseModel):
    abi_value: Optional[str]
    ankle_pressure_mmHg: Optional[str]
    toe_pressure_mmHg: Optional[str]
    tcpo2_mmHg: Optional[str]


class TaskItem(BaseModel):
    task_text: str
    status: str = "PENDING"
    task_due: str


class TreatmentPlan(BaseModel):
    plan_text: Optional[str] = None
    followup_days: Optional[int] = None
    status: Optional[str] = "DRAFT"
    plan_tasks: List[TaskItem] = []


class Timestamps(BaseModel):
    created_at: datetime
    updated_at: datetime

    analyze_at: Optional[datetime]
    doctor_review_at: Optional[datetime]
    plan_issued_at: Optional[datetime]
    treatment_active_at: Optional[datetime]
    appointment_at: Optional[datetime]
    completed_at: Optional[datetime]


class CaseImage(BaseModel):
    image_folder_url: Optional[str]


class CreateCaseVitals(BaseModel):
    temperature: Optional[str] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[str] = None
    repiratory_rate: Optional[str] = None
    respiratory_rate: Optional[str] = None
    blood_sugar: Optional[str] = None


class CreateCaseMeta(BaseModel):
    sent_at: Optional[str] = None


class CreateCaseRequest(BaseModel):
    patient_id: str
    status: Optional[str] = "Creation"
    vitals: Optional[CreateCaseVitals] = None
    meta: Optional[CreateCaseMeta] = None


class WoundCaseRecord(BaseModel):
    record_id: str
    case_id: str
    patient_id: str
    status: Optional[Status] = Status.DOCTOR_REVIEW
    urgency: Optional[Urgency] = Urgency.MEDIUM

    vital_signs: Optional[VitalSigns] = None
    wound_detail: Optional[WoundDetail] = None
    ischemia: Optional[Ischemia] = None
    infection: Optional[Infection] = None
    neuropathy: Optional[Neuropathy] = None
    sinbad: Optional[Sinbad] = None
    lab_results: Optional[LabResults] = None
    vascular: Optional[Vascular] = None
    gangrene_extent: Optional[str] = None

    analysis: Optional[dict] = None
    treatment_plan: Optional[TreatmentPlan] = None
    task_list: List[TaskItem] = []


class AIAnalysisRecord(BaseModel):
    analysis_id: str = Field(min_length=1)
    record_id: str = Field(min_length=1)

    creator: Optional[str] = None
    diagnosis: Optional[str] = None
    description: Optional[str] = None

    idsa_infection_stage: Optional[int] = Field(default=None, ge=1, le=4)

    wifi: Optional[WIfI] = None
    sinbad: Optional[SINBAD] = None

    confidence: Optional[float] = Field(default=None, ge=0.0, le=1.0)

    red_flag: Optional[bool] = None
    red_flag_reasons: List[str] = Field(default_factory=list)

    treatment_plan_summary: Optional[str] = None
    healing_progress: Optional[str] = None

    model_version: Optional[str] = None
    created_at: Optional[datetime] = None
