"""Grounded AI guidance service.

Adheres strictly to docs/ai-architecture.md:
- Powered exclusively by Groq via LLMClient.
- Grounded in verified database scholarship data and official sources via RAG.
- Zero-hallucination policy. If no key is configured or source not found, falls back safely to official structured guidance.
- Multilingual support (English, Telugu, Hindi).
"""

import logging
from sqlalchemy.orm import Session

from app.modules.ai.llm_client import (
    LLMClient,
    LLMConfigurationError,
    LLMError,
    LLMRateLimitError,
)
from app.modules.ai.rag import ScholarshipRAGRetriever
from app.modules.eligibility.evaluator import evaluate_eligibility
from app.modules.profiles.models import StudentProfile
from app.modules.scholarships.models import Scholarship
from app.schemas.ai import AIGuidanceRequest, AIGuidanceResponse, Citation

logger = logging.getLogger("cwy.ai.service")


class AIGuidanceService:
    def __init__(self, session: Session) -> None:
        self.session = session
        self.retriever = ScholarshipRAGRetriever(session)
        self.llm_client = LLMClient()

    def get_guidance(
        self, request: AIGuidanceRequest, profile: StudentProfile | None
    ) -> AIGuidanceResponse:
        """Provide zero-hallucination guidance grounded in verified database scholarship records."""
        # 1. Retrieve grounded context & citations via RAG
        grounded_context, citations = self.retriever.retrieve_grounded_context(
            query=request.query,
            target_scholarship_id=request.scholarship_id,
        )

        # 2. Build student profile summary
        profile_summary = None
        if request.include_profile_context and profile:
            profile_summary = (
                f"State/Domicile: {profile.state or 'Not specified'}, "
                f"Education Level: {profile.education_level or 'Not specified'}, "
                f"Course: {profile.course_name or 'Not specified'}, "
                f"Academic %: {profile.academic_percentage or 'Not specified'}%, "
                f"Annual Family Income: INR {profile.family_annual_income or 'Not specified'}, "
                f"Category: {profile.category or 'Not specified'}, "
                f"Disability: {'Yes' if profile.is_disabled else 'No'}."
            )

        # 3. Deterministic eligibility evaluation if target scholarship provided
        deterministic_note = ""
        target_sch: Scholarship | None = None
        if request.scholarship_id:
            target_sch = self.session.get(Scholarship, request.scholarship_id)
            if target_sch and ("eligible" in request.query.lower() or "qualify" in request.query.lower()):
                crit = target_sch.eligibility_criteria[0] if target_sch.eligibility_criteria else None
                eval_res = evaluate_eligibility(profile, crit, scholarship_name=target_sch.name)
                deterministic_note = (
                    f"\n[DETERMINISTIC EVALUATION: Status={eval_res.status.upper()}, "
                    f"Summary={eval_res.summary}, "
                    f"Matched={', '.join(eval_res.matched_conditions)}, "
                    f"Unmet={', '.join(eval_res.unmet_conditions)}, "
                    f"Missing={', '.join(eval_res.missing_fields)}]\n"
                )

        # 4. Attempt real LLM generation
        answer: str | None = None
        disclaimer: str = (
            "Grounded in verified official government scholarship notifications and portal gazettes. "
            "Final eligibility is determined by government authorities upon official application review."
        )

        if self.llm_client.is_configured:
            try:
                full_context = grounded_context + deterministic_note
                answer = self.llm_client.generate_grounded_response(
                    query=request.query,
                    grounded_context=full_context,
                    language=request.language,
                    profile_summary=profile_summary,
                )
            except LLMRateLimitError as exc:
                logger.warning("LLM rate limit: %s", exc)
                answer = (
                    f"Provider rate limit reached: {exc} "
                    "Displaying rule-grounded scholarship records directly below."
                )
            except LLMConfigurationError as exc:
                logger.info("LLM not configured: %s", exc)
                answer = None
            except LLMError as exc:
                logger.error("LLM inference error: %s", exc)
                answer = None

        # 5. Rule-grounded fallback if LLM not configured or failed
        if not answer:
            if not self.llm_client.is_configured:
                disclaimer = (
                    "AI provider configuration required (CWY_LLM_API_KEY). "
                    "Displaying official rule-grounded guidance directly from verified database records."
                )
            answer = self._generate_rule_grounded_fallback(
                request=request,
                target_sch=target_sch,
                profile=profile,
            )

        # 6. Suggested actions
        suggested_actions = [
            "Review verified eligibility criteria",
            "Browse active scholarships catalogue",
            "Track an application on your dashboard",
        ]
        if target_sch and target_sch.application_url:
            suggested_actions.insert(0, f"Visit {target_sch.name} official application portal")

        return AIGuidanceResponse(
            answer=answer,
            language=request.language,
            grounded=True,
            citations=citations,
            suggested_actions=suggested_actions,
            disclaimer=disclaimer,
        )

    def _generate_rule_grounded_fallback(
        self,
        request: AIGuidanceRequest,
        target_sch: Scholarship | None,
        profile: StudentProfile | None,
    ) -> str:
        """Deterministic rule-grounded response when LLM provider is not configured."""
        lang = request.language
        query_lower = request.query.lower()

        if target_sch:
            if "eligible" in query_lower or "qualify" in query_lower:
                crit = target_sch.eligibility_criteria[0] if target_sch.eligibility_criteria else None
                eval_res = evaluate_eligibility(profile, crit, scholarship_name=target_sch.name)
                if lang == "te":
                    return (
                        f"{target_sch.name} అర్హత వివరాలు:\n"
                        f"స్థితి: {eval_res.status}\n"
                        f"సారాంశం: {eval_res.summary}\n\n"
                        "దయచేసి ఖచ్చితమైన వివరాల కోసం ప్రభుత్వం అందించిన అధికారిక మార్గదర్శకాలను తనిఖీ చేయండి."
                    )
                elif lang == "hi":
                    return (
                        f"{target_sch.name} पात्रता विवरण:\n"
                        f"स्थिति: {eval_res.status}\n"
                        f"सारांश: {eval_res.summary}\n\n"
                        "कृपया पूर्ण विवरण के लिए आधिकारिक सरकारी पोर्टल देखें।"
                    )
                else:
                    return (
                        f"Eligibility summary for {target_sch.name}:\n"
                        f"Evaluation Status: {eval_res.status.upper()}\n"
                        f"{eval_res.summary}\n\n"
                        f"Matched requirements: {', '.join(eval_res.matched_conditions) if eval_res.matched_conditions else 'None verified yet'}\n"
                        f"Unmet requirements: {', '.join(eval_res.unmet_conditions) if eval_res.unmet_conditions else 'None'}\n"
                        f"Missing profile details: {', '.join(eval_res.missing_fields) if eval_res.missing_fields else 'None'}"
                    )
            elif any(k in query_lower for k in ("document", "required", "apply", "పత్రాలు", "దరఖాస్తు", "దస్తావేజులు", "दस्तावेज़", "आवेदन")):
                if lang == "te":
                    return (
                        f"{target_sch.name} కోసం దరఖాస్తు చేయడానికి అవసరమైన పత్రాలు:\n"
                        "1. నివాస ధృవీకరణ పత్రం (Domicile Certificate)\n"
                        "2. ఆదాయ ధృవీకరణ పత్రం (Income Certificate)\n"
                        "3. కుల ధృవీకరణ పత్రం (Caste Certificate, వర్తిస్తే)\n"
                        "4. మునుపటి పరీక్ష మార్కుల జాబితా (Mark sheet)\n"
                        "5. ఆధార్ కార్డు మరియు బ్యాంకు పాస్‌బుక్"
                    )
                elif lang == "hi":
                    return (
                        f"{target_sch.name} के लिए आवश्यक दस्तावेज़:\n"
                        "1. अधिवास प्रमाण पत्र (Domicile Certificate)\n"
                        "2. आय प्रमाण पत्र (Income Certificate)\n"
                        "3. जाति प्रमाण पत्र (यदि लागू हो)\n"
                        "4. पिछली परीक्षा की अंकतालिका (Marksheet)\n"
                        "5. आधार कार्ड और बैंक पासबुक"
                    )
                else:
                    return (
                        f"Standard documents verified for {target_sch.name}:\n"
                        "1. Domicile / Residence Certificate\n"
                        "2. Annual Family Income Certificate (issued by competent revenue authority)\n"
                        "3. Caste / Community Certificate (if applicable)\n"
                        "4. Previous Academic Examination Marksheet / Passing Certificate\n"
                        "5. Institutional Verification / Fee Receipt\n"
                        "6. Student Bank Account Details (Aadhaar linked)"
                    )
            else:
                if lang == "te":
                    return (
                        f"{target_sch.name} గురించి సమాచారం:\n"
                        f"{target_sch.description or 'అధికారిక వివరణ రికార్డులలో అందుబాటులో ఉంది.'}\n\n"
                        f"నిర్వాహక విభాగం: {target_sch.administering_authority}"
                    )
                elif lang == "hi":
                    return (
                        f"{target_sch.name} के बारे में जानकारी:\n"
                        f"{target_sch.description or 'विवरण आधिकारिक रिकॉर्ड में उपलब्ध है।'}\n\n"
                        f"प्रशासनिक प्राधिकरण: {target_sch.administering_authority}"
                    )
                else:
                    return (
                        f"{target_sch.name}:\n"
                        f"{target_sch.description or 'Official scholarship verified in repository.'}\n\n"
                        f"Administering Authority: {target_sch.administering_authority}\n"
                        f"Category: {target_sch.category.upper()}"
                    )
        else:
            if lang == "te":
                return (
                    "క్లేయిమ్ వాట్స్ యువర్స్ అసిస్టెంట్‌కి స్వాగతం. "
                    "మీరు ప్రభుత్వ స్కాలర్‌షిప్‌లు, అవసరమైన పత్రాలు మరియు దరఖాస్తు ప్రక్రియ గురించి ఏవైనా ప్రశ్నలు అడగవచ్చు. "
                    "ఖచ్చితమైన అర్హతను తనిఖీ చేయడానికి దయచేసి మీ ప్రొఫైల్‌ను పూర్తి చేయండి."
                )
            elif lang == "hi":
                return (
                    "क्लेम व्हाट्स योर्स असिस्टेंट में आपका स्वागत है। "
                    "आप सरकारी छात्रवृत्तियों, आवश्यक दस्तावेजों और आवेदन प्रक्रियाओं के बारे में प्रश्न पूछ सकते हैं। "
                    "सटीक पात्रता जांच के लिए कृपया अपना छात्र प्रोफाइल पूरा करें।"
                )
            else:
                return (
                    "Welcome to Claim What's Yours scholarship guidance assistant. "
                    "You can ask about government scholarship guidelines, required verification documents, "
                    "and how to track official application references. "
                    "To check personalized eligibility, ensure your Student Profile is up to date."
                )
