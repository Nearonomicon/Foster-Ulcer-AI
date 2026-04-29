from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, List, Optional, Union

from pydantic import BaseModel, ConfigDict, Field, model_validator


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
    REQUEST_CLOSE = "REQUEST_CLOSE"
    COMPLETED = "COMPLETED"


class Urgency(str, Enum):
    URGENT = "URGENT"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class NotificationUserRole(str, Enum):
    DOCTOR = "DOCTOR"
    NURSE = "NURSE"


class LocationPrimary(str, Enum):
    TOE = "toe"
    SOLE = "sole"
    SIDE = "side"
    HEEL = "heel"
    DORSAL_ASPECT = "dorsal_aspect"
    MEDIAL_MALLEOLUS = "medial_malleolus"
    LATERAL_MALLEOLUS = "lateral_malleolus"


class WoundType(str, Enum):
    ULCER = "ulcer"
    SURGICAL = "surgical"
    TRAUMATIC = "traumatic"
    PRESSURE = "pressure"
    BURN = "burn"
    OTHER = "other"


class Shape(str, Enum):
    ROUND = "round"
    OVAL = "oval"
    IRREGULAR = "irregular"
    LINEAR = "linear"
    PUNCHED_OUT = "punched_out"


class DepthCategory(str, Enum):
    SUPERFICIAL = "superficial"
    PARTIAL_THICKNESS = "partial_thickness"
    FULL_THICKNESS = "full_thickness"
    DEEP = "deep"
    VERY_DEEP_EXPOSED_BONE_TENDON = "very_deep_exposed_bone_tendon"


class EdgeDescription(str, Enum):
    SMOOTH = "smooth"
    THICKENED = "thickened"
    IRREGULAR = "irregular"
    ROLLED_EPIBOLE = "rolled_epibole"
    UNDERMINED = "undermined"
    CALLOUSED = "calloused"


class PeriwoundStatus(str, Enum):
    NORMAL = "normal"
    ERYTHEMATOUS = "erythematous"
    EDEMATOUS = "edematous"
    INDURATED = "indurated"
    MACERATED = "macerated"
    FLUCTUANT = "fluctuant"
    HYPERPIGMENTED = "hyperpigmented"


class DischargeVolume(str, Enum):
    NONE = "none"
    MINIMAL = "minimal"
    MODERATE = "moderate"
    HEAVY = "heavy"


class DischargeType(str, Enum):
    SEROUS = "serous (clear)"
    SANGUINEOUS = "sanguineous (bloody)"
    SEROSANGUINEOUS = "serosanguineous (pink)"
    PURULENT = "purulent (yellow/pus)"
    SEROPURULENT = "seropurulent (cloudy yellow)"


class OdorPresence(str, Enum):
    NONE = "none"
    FAINT = "faint"
    MODERATE = "moderate"
    FOUL = "foul"
    PUTRID = "putrid"


class SkinCondition(str, Enum):
    HEALTHY = "healthy"
    DRY = "dry"
    CRACKED = "cracked"
    MACERATED = "macerated"
    FRAGILE = "fragile"
    SCALING = "scaling"


class IschemiaChecklistItem(str, Enum):
    COLOR_PALE_BLUE = "Color (pale/blue)"
    COLD_FOOT = "Cold foot"
    BLACK_TISSUE = "Black tissue (tissue loss)"


class InfectionChecklistItem(str, Enum):
    PUS_GOO = "Pus / Goo (Purulent discharge)"
    WARMTH = "Warmth (hotter than other foot)"
    SWELLING = "Swelling (puffy, tight, hard)"
    PAIN = "Pain (tender or hurts to touch)"


class ErythemaExtent(str, Enum):
    NONE = "none"
    GT_0_5_CM = "gt_0_5_cm"
    GT_2_CM = "gt_2_cm"


class ProbeToBoneTest(str, Enum):
    NOT_PERFORMED = "not_performed"
    NEGATIVE = "negative"
    POSITIVE = "positive"


class GangreneExtent(str, Enum):
    NONE = "none"
    DIGITS_ONLY = "digits_only"
    FOREFOOT_MIDFOOT = "forefoot_midfoot"
    HEEL_FULL_THICKNESS = "heel_full_thickness"


class YesNoSinbad(str, Enum):
    NO = "No"
    YES = "Yes"


class SinbadSite(str, Enum):
    FOREFOOT = "Forefoot"
    MIDFOOT_HINDFOOT = "Midfoot/Hindfoot"


class SinbadArea(str, Enum):
    LT_1_CM2 = "< 1 cm\u00b2"
    GTE_1_CM2 = ">= 1 cm\u00b2"


class SinbadDepth(str, Enum):
    SKIN_ONLY = "Skin only"
    DEEP_BONE = "Deep/Bone"


class IschemiaPulse(str, Enum):
    YES = "yes"
    NO_WEAK = "no_weak"


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
    nrc_id: Optional[str] = None
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
    volume: Optional[DischargeVolume] = None
    type: Optional[DischargeType] = None


class VitalSigns(BaseModel):
    temperature: Optional[str] = None
    blood_pressure: Optional[str] = None
    blood_pressure_systolic: Optional[str] = None
    blood_pressure_diastolic: Optional[str] = None
    blood_glucose: Optional[str] = None
    heart_rate: Optional[str] = None
    respiratory_rate: Optional[str] = None


class WoundDetail(BaseModel):
    location_primary: Optional[LocationPrimary] = None
    location_detail: Optional[str] = None
    wound_type: Optional[WoundType] = None
    shape: Optional[Shape] = None
    size: Size
    depth_category: Optional[DepthCategory] = None
    bed: Bed
    edge_description: Optional[EdgeDescription] = None
    periwound_status: Optional[PeriwoundStatus] = None
    discharge: Discharge
    odor_presence: Optional[OdorPresence] = None
    pain_score: Optional[int] = Field(default=None, ge=0, le=10)
    has_infection: Optional[bool] = None
    skin_condition: Optional[SkinCondition] = None


class Ischemia(BaseModel):
    points: List[int] = Field(default_factory=list)
    pulse: Optional[IschemiaPulse] = None
    checklist: List[IschemiaChecklistItem] = Field(default_factory=list)


class Infection(BaseModel):
    checklist: List[InfectionChecklistItem] = Field(default_factory=list)
    erythema_extent: Optional[ErythemaExtent] = None
    probe_to_bone_test: Optional[ProbeToBoneTest] = None
    has_deep_abscess_or_fasciitis: Optional[bool] = None


class Neuropathy(BaseModel):
    points: List[int] = Field(default_factory=list)


class Sinbad(BaseModel):
    site: Optional[SinbadSite] = None
    ischemia: Optional[YesNoSinbad] = None
    neuropathy: Optional[YesNoSinbad] = None
    infection: Optional[YesNoSinbad] = None
    area: Optional[SinbadArea] = None
    depth: Optional[SinbadDepth] = None


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
    task_id: Optional[str] = None
    task_text: str
    status: str = "PENDING"
    task_due: Optional[str] = None
    completed_at: Optional[datetime] = None
    task_photo_url: Optional[str] = None
    source: Optional[str] = None
    order_index: Optional[int] = None


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


class CaseRef(BaseModel):
    patient_id: str
    case_id: str
    record_id: str


class NurseReviewed(BaseModel):
    nurse_reviewed_flag: bool
    vital_signs: VitalSigns
    wound_detail: WoundDetail
    ischemia: Ischemia
    infection: Infection
    neuropathy: Neuropathy
    sinbad: Sinbad
    lab_results: LabResults
    vascular: Vascular
    gangrene_extent: Optional[GangreneExtent] = None


class AnalyzeWoundPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    patient_profile: dict[str, Any]
    nurse_reviewed: NurseReviewed
    ai_prefill: Optional[dict[str, Any]] = None
    case_ref: Optional[dict[str, Any]] = None


class CreateCaseVitals(BaseModel):
    temperature: Optional[str] = None
    blood_pressure: Optional[str] = None
    blood_pressure_systolic: Optional[str] = None
    blood_pressure_diastolic: Optional[str] = None
    heart_rate: Optional[str] = None
    respiratory_rate: Optional[str] = None
    blood_glucose: Optional[str] = None
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


class UpdateCaseRequest(BaseModel):
    patient_id: str
    status: Optional[str] = "Creation"
    urgency: Optional[str] = None
    case_id: Optional[str] = None
    created_by_nurse: Optional[str] = None
    assigned_doctor: Optional[str] = None
    vitals: Optional[CreateCaseVitals] = None
    meta: Optional[CreateCaseMeta] = None


class NotificationDeviceRegistrationRequest(BaseModel):
    user_id: str = Field(min_length=1)
    role: NotificationUserRole
    fcm_token: str = Field(min_length=1)
    platform: Optional[str] = None
    device_id: Optional[str] = None


class NotificationDeviceUnregisterRequest(BaseModel):
    fcm_token: str = Field(min_length=1)


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
    gangrene_extent: Optional[GangreneExtent] = None

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
