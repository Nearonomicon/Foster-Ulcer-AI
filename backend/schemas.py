from datetime import datetime
from enum import Enum
from typing import List, Optional, Union

from pydantic import BaseModel, Field, model_validator


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
    risk_history: List[str] = Field(default_factory=list)
    complications: List[str] = Field(default_factory=list)

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
    width_cm: Optional[float] = None
    length_cm: Optional[float] = None


class Bed(BaseModel):
    slough_pct: Optional[int] = None
    necrotic_pct: Optional[int] = None


class Discharge(BaseModel):
    volume: Optional[str] = None
    type: Optional[str] = None


class VitalSigns(BaseModel):
    temperature: Optional[str] = None
    blood_pressure: Optional[str] = None
    blood_glucose: Optional[str] = None
    heart_rate: Optional[str] = None
    respiratory_rate: Optional[str] = None


class WoundDetail(BaseModel):
    location_primary: Optional[str] = None
    location_detail: Optional[str] = None
    wound_type: Optional[str] = None

    shape: Optional[Shape] = None

    size: Size = Field(default_factory=Size)
    depth_category: Optional[DepthCategory] = None

    bed: Bed = Field(default_factory=Bed)

    edge_description: Optional[str] = None
    periwound_status: Optional[str] = None

    discharge: Discharge = Field(default_factory=Discharge)
    odor_presence: Optional[str] = None

    pain_score: Optional[int] = None
    has_infection: Optional[bool] = None

    skin_condition: Optional[str] = None


class Ischemia(BaseModel):
    points: List[int] = Field(default_factory=list)
    pulse: Optional[str] = None
    checklist: List[str] = Field(default_factory=list)


class Infection(BaseModel):
    checklist: List[str] = Field(default_factory=list)
    erythema_extent: Optional[str] = None
    probe_to_bone_test: Optional[str] = None
    has_deep_abscess_or_fasciitis: Optional[str] = None


class Neuropathy(BaseModel):
    points: List[int] = Field(default_factory=list)


class Sinbad(BaseModel):
    site: Optional[str] = None
    ischemia: Optional[str] = None
    neuropathy: Optional[str] = None
    infection: Optional[str] = None
    area: Optional[str] = None
    depth: Optional[str] = None


class LabResults(BaseModel):
    wbc_count: Optional[str] = None
    crp: Optional[str] = None
    esr: Optional[str] = None
    procalcitonin: Optional[str] = None


class Vascular(BaseModel):
    abi_value: Optional[str] = None
    ankle_pressure_mmHg: Optional[str] = None
    toe_pressure_mmHg: Optional[str] = None
    tcpo2_mmHg: Optional[str] = None


class TaskItem(BaseModel):
    task_text: str
    status: str = "PENDING"
    task_due: Optional[str] = None


class TreatmentPlan(BaseModel):
    plan_text: Optional[str] = None
    followup_days: Optional[int] = None
    status: Optional[str] = "DRAFT"
    plan_tasks: List[TaskItem] = Field(default_factory=list)


class Timestamps(BaseModel):
    created_at: datetime
    updated_at: datetime

    analyze_at: Optional[datetime] = None
    doctor_review_at: Optional[datetime] = None
    plan_issued_at: Optional[datetime] = None
    treatment_active_at: Optional[datetime] = None
    appointment_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class CaseImage(BaseModel):
    image_folder_url: Optional[str] = None


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
    urgency: Optional[str] = None
    created_by_nurse: Optional[str] = None
    assigned_doctor: Optional[str] = None
    vitals: Optional[CreateCaseVitals] = None
    meta: Optional[CreateCaseMeta] = None


class WoundCaseRecord(BaseModel):
    record_id: str
    case_id: str
    patient_id: str
    record_created_by: Optional[str] = None
    record_created_at: Optional[datetime] = None
    record_updated_at: Optional[datetime] = None
    created_by_nurse: Optional[str] = None
    assigned_doctor: Optional[str] = None
    status: Optional[Status] = Status.DOCTOR_REVIEW
    urgency: Optional[Urgency] = None

    timestamps: Optional[Timestamps] = None
    image: Optional[CaseImage] = None

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
    task_list: List[TaskItem] = Field(default_factory=list)


class WoundCaseRecordUpdate(WoundCaseRecord):
    @model_validator(mode="after")
    def require_non_null_sections(self):
        missing = []
        if self.vital_signs is None:
            missing.append("vital_signs")
        if self.wound_detail is None:
            missing.append("wound_detail")
        if self.ischemia is None:
            missing.append("ischemia")
        if self.infection is None:
            missing.append("infection")
        if self.neuropathy is None:
            missing.append("neuropathy")
        if self.sinbad is None:
            missing.append("sinbad")
        if self.lab_results is None:
            missing.append("lab_results")
        if self.vascular is None:
            missing.append("vascular")
        if missing:
            raise ValueError(f"Missing required fields: {', '.join(missing)}")
        return self


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
