import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('my')];

  static AppLocalizations of(BuildContext context) {
    final obj = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(obj != null, 'AppLocalizations not found');
    return obj!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocDelegate();

  String tr(String key) {
    const dict = {
      'en': {
        // ===== Login =====
        'login.main_hospital': 'Main Hospital',
        'login.west_wing': 'West Wing Clinic',
        'login.clinical_id': 'CLINICAL ID',
        'login.password': 'PASSWORD',
        'login.forgot': 'Forgot Password?',
        'login.login': 'Log In',
        'login.register': 'Register Account',
        'login.bio_login': 'Log in with Biometrics',
        'login.need_help': 'Need technical assistance?',
        'login.contact_it': 'Contact IT Support',
        'login.subtitle': 'Specialist Ulcer Management',
        'login.switch_language': 'Switch Clinical Language',
        // ===== Register =====
        'register.header.title': 'Practitioner Registration',
        'register.header.subtitle': 'Join the clinical wound care network',
        'register.avatar.label': 'PROFESSIONAL MEDICAL ID',

        'register.full_name.label': 'FULL NAME',
        'register.full_name.hint': 'Dr. Jane Smith',

        'register.license.label': 'MEDICAL LICENSE NUMBER',
        'register.license.hint': 'MD-12345678',

        'register.specialty.label': 'SPECIALTY',
        'register.specialty.select': 'Select Specialty',
        'register.specialty.dermatology': 'Dermatology',
        'register.specialty.vascular': 'Vascular Surgery',
        'register.specialty.wound_care': 'Wound Care Specialist',
        'register.specialty.endocrinology': 'Endocrinology',
        'register.specialty.internal_medicine': 'Internal Medicine',

        'register.hospital.label': 'HOSPITAL AFFILIATION',
        'register.hospital.hint': 'Central Medical Center',

        'register.terms.prefix': 'I agree to the ',
        'register.terms.terms': 'Terms of Clinical Practice',
        'register.terms.suffix': ' and confirm that my medical credentials are accurate.',

        'register.create_account': 'Create Account',

        'register.have_account.prefix': 'Already have an account? ',
        'register.have_account.login': 'Log In',
        // ===== Case Inbox =====
       
        'inbox.title': 'Case Inbox',
        'inbox.tab.needs_review': 'Needs Review',
        'inbox.tab.ai_processed': 'AI Processed',
        'inbox.tab.recent': 'Recent',

        'inbox.section.pending_review': 'Pending Review',
        'inbox.section.ai_processed': 'AI Processed',
        'inbox.section.recent': 'Recent',

        'inbox.nav.inbox': 'INBOX',

        'inbox.badge.high_urgency': 'HIGH URGENCY',
        'inbox.badge.medium': 'MEDIUM',
        'inbox.badge.routine': 'ROUTINE',

        'inbox.id_label': 'ID',
        'inbox.box.ai_detection': 'AI DETECTION',
        'inbox.box.time_elapsed': 'TIME ELAPSED',
        'inbox.box.confidence': 'Confidence',

        'inbox.review_case': 'Review Case',
        // Common
        'common.id': 'ID',
        'common.na': 'N/A',
        'common.none': 'None',
        'common.view_all': 'View All',
        'common.today': 'Today',
        'common.latest': 'Latest',
        'common.save_draft': 'Save Draft',

        'common.gender.male': 'Male',
        'common.gender.female': 'Female',
        'common.urgency.high': 'HIGH URGENCY',
        'common.urgency.routine': 'ROUTINE',

        // Case Detail
        'case_detail.header.title': 'Case Review',
        'case_detail.header.medical': 'Medical',

        'case_detail.section.patient_profile': 'Patient Profile',
        'case_detail.section.wound_timeline': 'Wound Timeline',
        'case_detail.section.ai_analysis': 'AI Analysis',
        'case_detail.section.clinical_evaluation': 'Clinical Evaluation',

        'case_detail.field.age_gender': 'Age / Gender',
        'case_detail.field.vitals': 'Vitals',
        'case_detail.field.hr': 'HR',
        'case_detail.field.comorbidities': 'Comorbidities',
        'case_detail.field.area_est': 'Area (Est.)',

        'case_detail.note.site': 'Site',
        'case_detail.note.slough': 'Slough',
        'case_detail.note.necrotic': 'Necrotic',
        'case_detail.note.pain': 'Pain',
        'case_detail.note.odor': 'Odor',

        'case_detail.metric.confidence': 'Confidence',
        'case_detail.metric.ai_draft': 'AI Draft',
        'case_detail.metric.ready': 'Ready',

        'case_detail.cta.review_ai': 'Review AI Analysis',
        'case_detail.cta.create_treatment_plan': 'Create Treatment Plan',

        'case_detail.field.diagnosis_override': 'Diagnosis Override (Optional)',
        'case_detail.field.clinical_notes': 'Clinical Notes',
        'case_detail.hint.clinical_notes': 'Add specific observation for the nurse...',

        'case_detail.diagnosis.accept_w2': 'Accept AI: Wagner Grade 2',
        'case_detail.diagnosis.override_w3': 'Override: Wagner Grade 3',
        'case_detail.diagnosis.override_w1': 'Override: Wagner Grade 1',
        // AI Review screen
        'ai_review.nav.back': 'Case Detail',
        'ai_review.nav.title': 'AI Review & Edit',

        'ai_review.badge.specialist_review': 'Specialist Review',
        'ai_review.tag.ai_suggested': 'AI Suggested',

        'ai_review.section.modify_findings': 'Modify Findings',
        'ai_review.section.evaluate_ai_accuracy': 'Evaluate AI Accuracy',

        'ai_review.field.wound_stage': 'Wound Stage',
        'ai_review.field.ai_confidence': 'AI Confidence',
        'ai_review.field.diagnostic_classification': 'Diagnostic Classification',
        'ai_review.field.clinical_description': 'Clinical Description',
        'ai_review.field.proposed_treatment_plan': 'Proposed Treatment Plan',
        'ai_review.field.healing_progress': 'Healing Progress',

        'ai_review.quality.accurate': 'Accurate',
        'ai_review.quality.needs_correction': 'Needs Correction',

        'ai_review.cta.proceed_treatment_plan': 'Proceed to Treatment Plan',
        'ai_review.cta.discard_edits': 'Discard Edits',

        // Stage labels
        'ai_review.stage.stage_1': 'Stage 1',
        'ai_review.stage.stage_2': 'Stage 2',
        'ai_review.stage.stage_3': 'Stage 3',
        'ai_review.stage.stage_4': 'Stage 4',
        'ai_review.stage.unstageable': 'Unstageable',

        // Diagnosis labels
        'ai_review.diag.diag_dfu_w2': 'Diabetic Foot Ulcer (Wagner Grade 2)',
        'ai_review.diag.diag_venous': 'Venous Leg Ulcer',
        'ai_review.diag.diag_pressure': 'Pressure Injury',
        'ai_review.diag.diag_arterial': 'Arterial Ulcer',
        'ai_review.diag.diag_mixed': 'Mixed Etiology',

        // Healing labels
        'ai_review.heal.heal_improving': 'Improving (Reduction in erythema)',
        'ai_review.heal.heal_stable': 'Stable (No significant change)',
        'ai_review.heal.heal_declining': 'Declining (Increased size/exudate)',
        'ai_review.heal.heal_critical': 'Critical (Infection suspected)',
        "review_plan.title": "Review Treatment Plan",
        "review_plan.dob": "DOB",
        "review_plan.history": "Hx",

        "review_plan.ai_confidence": "AI Confidence",

        "review_plan.clinical_diagnosis": "Clinical Diagnosis",
        "review_plan.active_plan": "Active Plan",

        "review_plan.followup": "Follow-up",
        "review_plan.every": "Every",
        "review_plan.days": "Days",

        "review_plan.status": "Status",
        "review_plan.plan_notes": "Plan Notes",

        "review_plan.tasks_for_nurse": "Tasks for Nurse",

        "review_plan.signature": "Physician Digital Signature",
        "review_plan.clear_signature": "Clear Signature",
        "review_plan.draw_signature": "Draw signature inside box",

        "review_plan.warning":
        "By signing and sending this plan, you provide legal and clinical authorization for the frontline nursing team to execute these tasks.",

        "review_plan.send_plan": "Authorize & Send Plan",
        "review_plan.sign_first": "Please sign before sending.",
        "review_plan.plan_sent": "Plan sent",
        /* ---------- EN ---------- */
        'tp_dispatch.title': 'Dispatch Plan',
        'tp_dispatch.back': 'Back',
        'tp_dispatch.case_prefix': 'CASE',

        'tp_dispatch.section.diagnosis_staging': 'Diagnosis & Staging',
        'tp_dispatch.section.treatment_schedule': 'Treatment Schedule',
        'tp_dispatch.section.clinical_cadence': 'Clinical Cadence',
        'tp_dispatch.section.assigned_caregiver': 'Assigned Caregiver',

        'tp_dispatch.badge.action_required': 'ACTION REQUIRED',
        'tp_dispatch.badge.stable': 'STABLE',
        'tp_dispatch.badge.ai_suggested': 'AI Suggested',

        'tp_dispatch.tasks': 'TASKS',
        'tp_dispatch.add_task': 'Add Task',
        'tp_dispatch.finalize_send': 'Finalize and send plan to nurse',

        'tp_dispatch.info':
            'Confirming this action will finalize the clinical pathway and update case status to PLAN_SENT. '
            'The nurse will receive a priority notification on their handset immediately.',

        'tp_dispatch.frequency': 'Frequency',
        'tp_dispatch.every': 'Every',
        'tp_dispatch.days': 'Days',
        'tp_dispatch.estimate_end_date': 'Estimate End Date',

        'tp_dispatch.change': 'Change',

        'tp_dispatch.caregiver.default_name': 'Wound Care Nurse (On duty)',
        'tp_dispatch.caregiver.contact': 'Contact',
        'tp_dispatch.caregiver.contact_na': 'Contact: -',

        'tp_dispatch.no_tasks': 'No tasks in this plan yet.',
        'tp_dispatch.task': 'Task',
        'tp_dispatch.due': 'Due',
        'tp_dispatch.status_label': 'Status',
        'tp_dispatch.status.draft': 'DRAFT',

        'tp_dispatch.snack.add_task': 'Add Task (mock)',
        'tp_dispatch.snack.change_caregiver': 'Change caregiver (mock)',

        'tp_dispatch.na_diagnosis': 'Diagnosis not available',
        'tp_dispatch.urgency.normal': 'NORMAL',

                
        // ===== Others (เริ่มใส่ key ของหน้าต่อๆไปได้) =====
        'case_inbox.title': 'Case Inbox',
      },
      'my': {
        // ===== Login =====
        'login.main_hospital': 'အဓိက ဆေးရုံ',
        'login.west_wing': 'အနောက်ပိုင်း ကလစ်နစ်',
        'login.clinical_id': 'ဆေးဘက်ဆိုင်ရာ ID',
        'login.password': 'စကားဝှက်',
        'login.forgot': 'စကားဝှက် မေ့နေပါသလား?',
        'login.login': 'ဝင်မည်',
        'login.register': 'အကောင့်ဖွင့်မည်',
        'login.bio_login': 'Biometrics ဖြင့်ဝင်မည်',
        'login.need_help': 'နည်းပညာအကူအညီလိုပါသလား?',
        'login.contact_it': 'IT Support ကိုဆက်သွယ်မည်',
        'login.subtitle': 'အနာအဆာ စီမံခန့်ခွဲမှု',
        'login.switch_language': 'ဘာသာစကား ပြောင်းမည်',
        // ===== Register =====
        'register.header.title': 'ဆရာဝန် မှတ်ပုံတင်ခြင်း',
        'register.header.subtitle': 'ဆေးဘက်ဆိုင်ရာ အနာကုသမှုကွန်ယက်သို့ ဝင်ရောက်ပါ',
        'register.avatar.label': 'ပရော်ဖက်ရှင်နယ် ဆေးဘက် ID',

        'register.full_name.label': 'အမည်အပြည့်အစုံ',
        'register.full_name.hint': 'Dr. Jane Smith',

        'register.license.label': 'ဆေးဘက်လိုင်စင်နံပါတ်',
        'register.license.hint': 'MD-12345678',

        'register.specialty.label': 'အထူးပြုဘာသာ',
        'register.specialty.select': 'အထူးပြုဘာသာ ရွေးချယ်ပါ',
        'register.specialty.dermatology': 'အရေပြားဆိုင်ရာ',
        'register.specialty.vascular': 'သွေးကြောခွဲစိတ်',
        'register.specialty.wound_care': 'အနာကုသမှု အထူးজ্ঞ',
        'register.specialty.endocrinology': 'ဟော်မုန်း/အင်ဒိုခရိုင်နို',
        'register.specialty.internal_medicine': 'အတွင်းရောဂါ',

        'register.hospital.label': 'ဆေးရုံ/အဖွဲ့အစည်း',
        'register.hospital.hint': 'Central Medical Center',

        'register.terms.prefix': 'ကျွန်ုပ်သည် ',
        'register.terms.terms': 'ဆေးဘက်ဆိုင်ရာ လုပ်ထုံးလုပ်နည်း စည်းကမ်းချက်များ',
        'register.terms.suffix': ' ကို သဘောတူပြီး ကျွန်ုပ်၏ အထောက်အထားများ မှန်ကန်ကြောင်း အတည်ပြုပါသည်။',

        'register.create_account': 'အကောင့်ဖွင့်မည်',

        'register.have_account.prefix': 'အကောင့်ရှိပြီးသားလား? ',
        'register.have_account.login': 'ဝင်မည်',
        // ===== Case Inbox =====
        // Inbox
        'inbox.title': 'ကိစ္စအဝင်ပုံး',
        'inbox.tab.needs_review': 'ပြန်စစ်ရန်လို',
        'inbox.tab.ai_processed': 'AI ပြီးဆုံး',
        'inbox.tab.recent': 'နောက်ဆုံး',

        'inbox.section.pending_review': 'စစ်ဆေးရန်ကျန်',
        'inbox.section.ai_processed': 'AI ပြီးဆုံး',
        'inbox.section.recent': 'နောက်ဆုံး',

        'inbox.nav.inbox': 'INBOX',

        'inbox.badge.high_urgency': 'အရေးပေါ် မြင့်',
        'inbox.badge.medium': 'အလတ်စား',
        'inbox.badge.routine': 'ပုံမှန်',

        'inbox.id_label': 'ID',
        'inbox.box.ai_detection': 'AI စစ်ဆေးမှု',
        'inbox.box.time_elapsed': 'အချိန်ကြာချိန်',
        'inbox.box.confidence': 'ယုံကြည်မှု',

        'inbox.review_case': 'ကိစ္စကို စစ်မည်',

        // ===== Others =====
        'case_inbox.title': 'Case Inbox',
        // Common
        'common.id': 'ID',
        'common.na': 'မရှိ',
        'common.none': 'မရှိပါ',
        'common.view_all': 'အားလုံးကြည့်မည်',
        'common.today': 'ဒီနေ့',
        'common.latest': 'နောက်ဆုံး',
        'common.save_draft': 'မူကြမ်းသိမ်းမည်',

        'common.gender.male': 'ကျား',
        'common.gender.female': 'မ',
        'common.urgency.high': 'အရေးပေါ် မြင့်',
        'common.urgency.routine': 'ပုံမှန်',

        // Case Detail
        'case_detail.header.title': 'ကိစ္စ စစ်ဆေးမှု',
        'case_detail.header.medical': 'ရောဂါအခြေအနေ',

        'case_detail.section.patient_profile': 'လူနာ အချက်အလက်',
        'case_detail.section.wound_timeline': 'အနာ Timeline',
        'case_detail.section.ai_analysis': 'AI ခွဲခြမ်းစိတ်ဖြာမှု',
        'case_detail.section.clinical_evaluation': 'ဆေးဘက်ဆိုင်ရာ သုံးသပ်ချက်',

        'case_detail.field.age_gender': 'အသက် / လိင်',
        'case_detail.field.vitals': 'Vitals',
        'case_detail.field.hr': 'HR',
        'case_detail.field.comorbidities': 'တွဲဖက်ရောဂါများ',
        'case_detail.field.area_est': 'ဧရိယာ (ခန့်မှန်း)',

        'case_detail.note.site': 'နေရာ',
        'case_detail.note.slough': 'Slough',
        'case_detail.note.necrotic': 'Necrotic',
        'case_detail.note.pain': 'နာကျင်မှု',
        'case_detail.note.odor': 'အနံ့',

        'case_detail.metric.confidence': 'ယုံကြည်မှု',
        'case_detail.metric.ai_draft': 'AI Draft',
        'case_detail.metric.ready': 'အဆင်သင့်',

        'case_detail.cta.review_ai': 'AI ခွဲခြမ်းစိတ်ဖြာမှုကို စစ်မည်',
        'case_detail.cta.create_treatment_plan': 'ကုသမှုအစီအစဉ် ဖန်တီးမည်',

        'case_detail.field.diagnosis_override': 'ရောဂါသတ်မှတ်ချက် ပြင်ဆင်ရန် (ရွေးချယ်နိုင်)',
        'case_detail.field.clinical_notes': 'မှတ်စု',
        'case_detail.hint.clinical_notes': 'နာစ့်အတွက် သီးသန့် မှတ်ချက်ထည့်ပါ...',

        'case_detail.diagnosis.accept_w2': 'AI လက်ခံ: Wagner Grade 2',
        'case_detail.diagnosis.override_w3': 'ပြင်ဆင်: Wagner Grade 3',
        'case_detail.diagnosis.override_w1': 'ပြင်ဆင်: Wagner Grade 1',
        // AI Review screen
        'ai_review.nav.back': 'ကိစ္စအသေးစိတ်',
        'ai_review.nav.title': 'AI ပြန်လည်စစ်ဆေး & ပြင်ဆင်',

        'ai_review.badge.specialist_review': 'အထူးကု စစ်ဆေးမှု',
        'ai_review.tag.ai_suggested': 'AI အကြံပြု',

        'ai_review.section.modify_findings': 'တွေ့ရှိချက်များ ပြင်ဆင်',
        'ai_review.section.evaluate_ai_accuracy': 'AI တိကျမှု အကဲဖြတ်',

        'ai_review.field.wound_stage': 'အနာ အဆင့်',
        'ai_review.field.ai_confidence': 'AI ယုံကြည်မှု',
        'ai_review.field.diagnostic_classification': 'ရောဂါအမျိုးအစား သတ်မှတ်ခြင်း',
        'ai_review.field.clinical_description': 'ဆေးဘက်ဆိုင်ရာ ဖော်ပြချက်',
        'ai_review.field.proposed_treatment_plan': 'အကြံပြုကုသမှုအစီအစဉ်',
        'ai_review.field.healing_progress': 'ကုသမှုတိုးတက်မှု',

        'ai_review.quality.accurate': 'တိကျသည်',
        'ai_review.quality.needs_correction': 'ပြင်ဆင်ရန်လို',

        'ai_review.cta.proceed_treatment_plan': 'ကုသမှုအစီအစဉ်သို့ ဆက်သွားမည်',
        'ai_review.cta.discard_edits': 'ပြင်ဆင်ချက်များ ပယ်ဖျက်မည်',

        // Stage labels
        'ai_review.stage.stage_1': 'Stage 1',
        'ai_review.stage.stage_2': 'Stage 2',
        'ai_review.stage.stage_3': 'Stage 3',
        'ai_review.stage.stage_4': 'Stage 4',
        'ai_review.stage.unstageable': 'Unstageable',

        // Diagnosis labels
        'ai_review.diag.diag_dfu_w2': 'ဆီးချိုခြေထောက်အနာ (Wagner Grade 2)',
        'ai_review.diag.diag_venous': 'သွေးကြောပြန် အနာ (Venous)',
        'ai_review.diag.diag_pressure': 'ဖိအားကြောင့် အနာ (Pressure)',
        'ai_review.diag.diag_arterial': 'သွေးကြောပိတ် အနာ (Arterial)',
        'ai_review.diag.diag_mixed': 'အမျိုးမျိုးပေါင်း (Mixed)',

        // Healing labels
        'ai_review.heal.heal_improving': 'ကောင်းလာနေသည် (နီရဲမှု လျော့)',
        'ai_review.heal.heal_stable': 'တည်ငြိမ် (ပြောင်းလဲမှု မရှိ)',
        'ai_review.heal.heal_declining': 'ဆိုးလာ (အရွယ်/အရည်တိုး)',
        'ai_review.heal.heal_critical': 'အန္တရာယ် (ကူးစက်မှု সন্দেহ)',
        "review_plan.title": "ကုသမှုအစီအစဉ် စစ်ဆေးခြင်း",
        
        "review_plan.dob": "မွေးနေ့",
        "review_plan.history": "ဆေးမှတ်တမ်း",

        "review_plan.ai_confidence": "AI ယုံကြည်မှု",

        "review_plan.clinical_diagnosis": "ဆေးဘက်ဆိုင်ရာ ခွဲခြားသတ်မှတ်ချက်",
        "review_plan.active_plan": "လက်ရှိကုသမှုအစီအစဉ်",

        "review_plan.followup": "ပြန်လည်စစ်ဆေးရန်",
        "review_plan.every": "တိုင်း",
        "review_plan.days": "နေ့",

        "review_plan.status": "အခြေအနေ",
        "review_plan.plan_notes": "ကုသမှုမှတ်ချက်",

        "review_plan.tasks_for_nurse": "သူနာပြုလုပ်ဆောင်ရန်",

        "review_plan.signature": "ဆရာဝန် လက်မှတ်",
        "review_plan.clear_signature": "လက်မှတ်ဖျက်ရန်",
        "review_plan.draw_signature": "ဒီနေရာမှာ လက်မှတ်ရေးပါ",

        "review_plan.warning":
        "ဤအစီအစဉ်ကို လက်မှတ်ထိုးပြီး ပို့လိုက်သည်နှင့် သူနာပြုအဖွဲ့သည် လုပ်ဆောင်ရန် ခွင့်ပြုချက်ရရှိမည်ဖြစ်သည်။",

        "review_plan.send_plan": "အတည်ပြုပြီး ပို့မည်",
        "review_plan.sign_first": "ကျေးဇူးပြု၍ လက်မှတ်ထိုးပါ",
        "review_plan.plan_sent": "အစီအစဉ် ပို့ပြီးပါပြီ",
        /* ---------- MY ---------- */
        'tp_dispatch.title': 'အစီအစဉ် ပို့ရန်',
        'tp_dispatch.back': 'နောက်သို့',
        'tp_dispatch.case_prefix': 'CASE',

        'tp_dispatch.section.diagnosis_staging': 'ခွဲခြားသတ်မှတ်ချက် နှင့် အဆင့်သတ်မှတ်ခြင်း',
        'tp_dispatch.section.treatment_schedule': 'ကုသမှု အစီအစဉ်',
        'tp_dispatch.section.clinical_cadence': 'ကုသမှု အကြိမ်နှုန်း',
        'tp_dispatch.section.assigned_caregiver': 'တာဝန်ပေးထားသော တာဝန်ခံ',

        'tp_dispatch.badge.action_required': 'အရေးပေါ် လုပ်ဆောင်ရန်',
        'tp_dispatch.badge.stable': 'တည်ငြိမ်',
        'tp_dispatch.badge.ai_suggested': 'AI အကြံပြု',

        'tp_dispatch.tasks': 'TASKS',
        'tp_dispatch.add_task': 'Task ထည့်မည်',
        'tp_dispatch.finalize_send': 'အစီအစဉ်ကို အတည်ပြုပြီး နာစ့်ထံ ပို့မည်',

        'tp_dispatch.info':
            'ဤလုပ်ဆောင်ချက်ကို အတည်ပြုပါက clinical pathway ကို အပြီးသတ်ပြီး case status ကို PLAN_SENT သို့ ပြောင်းလဲမည်ဖြစ်သည်။ '
            'နာစ့်ဖုန်းသို့ အရေးပေါ် အကြောင်းကြားချက်ကို ချက်ချင်း ပို့မည်။',

        'tp_dispatch.frequency': 'အကြိမ်နှုန်း',
        'tp_dispatch.every': 'တိုင်း',
        'tp_dispatch.days': 'နေ့',
        'tp_dispatch.estimate_end_date': 'ပြီးဆုံးမည့်ရက် ခန့်မှန်း',

        'tp_dispatch.change': 'ပြောင်းမည်',

        'tp_dispatch.caregiver.default_name': 'အနာကုသ နာစ့် (တာဝန်ချိန်)',
        'tp_dispatch.caregiver.contact': 'ဆက်သွယ်ရန်',
        'tp_dispatch.caregiver.contact_na': 'ဆက်သွယ်ရန်: -',

        'tp_dispatch.no_tasks': 'ဒီအစီအစဉ်မှာ task မရှိသေးပါ။',
        'tp_dispatch.task': 'Task',
        'tp_dispatch.due': 'သတ်မှတ်ရက်',
        'tp_dispatch.status_label': 'အခြေအနေ',
        'tp_dispatch.status.draft': 'မူကြမ်း',

        'tp_dispatch.snack.add_task': 'Task ထည့်ခြင်း (mock)',
        'tp_dispatch.snack.change_caregiver': 'တာဝန်ခံ ပြောင်းခြင်း (mock)',

        'tp_dispatch.na_diagnosis': 'ခွဲခြားသတ်မှတ်ချက် မရှိပါ',
        'tp_dispatch.urgency.normal': 'ပုံမှန်',
      },
    };

    final lang = locale.languageCode;
    return dict[lang]?[key] ?? dict['en']?[key] ?? key;
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);
}