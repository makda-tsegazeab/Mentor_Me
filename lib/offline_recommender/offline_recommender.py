import math
from typing import List, Dict, Any
import os

# 🔧 Make sure we are NOT using the Firestore emulator
for env_var in ["FIRESTORE_EMULATOR_HOST", "FIREBASE_FIRESTORE_EMULATOR_ADDRESS"]:
    if os.environ.get(env_var):
        print(f"⚠️ Clearing {env_var} (was: {os.environ[env_var]})")
        os.environ.pop(env_var, None)

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATH = "../../serviceAccountKey.json"  # adjust if needed

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred, {
    "projectId": "hey-tutor-e382a",
})

db = firestore.client()

print("🐍 Python is using Firebase project:", firebase_admin.get_app().project_id)


# ------------- CONFIG -------------


ALL_SUBJECTS = [
    "Mathematics", "English", "Amharic", "Tigrigna", "Physics", "Chemistry",
    "Biology", "Civics", "History", "Geography", "ICT", "Physical Education",
    "Art", "Ethics", "Social Studies", "Economics",
]

FULL_GRADE_LEVELS = ["KG", "1–4", "5–6", "7–8", "9–10", "11–12"]

ALL_CITIES = [
    "Mekelle", "Aksum", "Adwa", "Abi Adi", "Maychew", "Hagere Selam",
    "Enticho", "Yeha", "Rama", "Adet", "Tanqua Melash", "Laelay Maychew",
    "Tahtay Maychew", "Edaga Arbi", "Adigrat", "Wukro", "Hawzen",
    "Idaga Hamus", "Freweyni", "Zalambessa", "Atsbi", "Agulae", "Bizet",
    "Alamata", "Korem", "Mekoni", "Ofla", "Hiwane", "Waja", "Selewa",
    "Emba Alaje", "Shire (Inda Selassie)", "Sheraro", "Adi Daero",
    "Selekleka", "May Tsebri", "Inda Aba Guna", "Humera", "Dansha",
    "May Kadra", "Adi Remets", "Tsegede", "Tselemti",
]


# ------------- GENERIC HELPERS -------------


def clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


def safe_int(val) -> int:
    if val is None:
        return 0
    try:
        return int(val)
    except Exception:
        return 0


# ------------- SCORE HELPERS (LEARNER → TUTOR) -------------


def price_score_learner_tutor(learner_max, tutor_min) -> float:
    """
    Learner perspective:
    - If either side didn't set price → 1.0
    - If tutor_min <= learner_max → 1.0 (they can afford the tutor)
    - If tutor_min > learner_max → penalize by relative gap
    """
    if learner_max is None or tutor_min is None:
        return 1.0

    try:
        l = float(learner_max)
        t = float(tutor_min)
    except Exception:
        return 1.0

    if l <= 0:
        return 1.0

    if t <= l:
        return 1.0

    diff = t - l
    penalty = clamp01(diff / l)
    return 1.0 - penalty


def capacity_score_learner_tutor(learner_val, tutor_val) -> float:
    """
    For hoursPerDay / daysPerWeek from learner perspective.
    - If learner doesn't specify → 1.0 (no constraint)
    - If tutor >= learner → 1.0
    - If tutor < learner → ratio (tutor / learner)
    """
    if learner_val is None:
        return 1.0

    l = safe_int(learner_val)
    if l <= 0:
        return 1.0

    t = safe_int(tutor_val)
    if t <= 0:
        return 0.0

    if t >= l:
        return 1.0

    return clamp01(t / l)


def gender_score_learner(pref, tutor_sex) -> float:
    if not pref or pref == "no preference":
        return 1.0
    return 1.0 if tutor_sex and tutor_sex == pref else 0.0


def compute_match_score_learner_tutor(learner: Dict[str, Any], tutor: Dict[str, Any]) -> float:
    components: List[float] = []

    # Subjects
    l_subs = set(learner.get("subjects") or [])
    t_subs = set(tutor.get("subjects") or [])
    if l_subs:
        overlap = len(l_subs & t_subs)
        components.append(overlap / len(l_subs))

    # Grades
    l_grades = set(learner.get("gradeLevels") or [])
    t_grades = set(tutor.get("gradeLevels") or [])
    if l_grades:
        overlap = len(l_grades & t_grades)
        components.append(overlap / len(l_grades))

    # Price
    components.append(price_score_learner_tutor(
        learner.get("maxPricePerHour"),
        tutor.get("minPricePerHour"),
    ))

    # Hours / days
    components.append(capacity_score_learner_tutor(
        learner.get("hoursPerDay"),
        tutor.get("hoursPerDay"),
    ))
    components.append(capacity_score_learner_tutor(
        learner.get("daysPerWeek"),
        tutor.get("daysPerWeek"),
    ))

    # Gender preference
    components.append(gender_score_learner(
        learner.get("preferredTutorGender"),
        tutor.get("sex"),
    ))

    if not components:
        return 0.0

    return sum(components) / len(components)


# ------------- SCORE HELPERS (TUTOR → LEARNER) -------------


def price_score_tutor_learner(tutor_min, learner_max) -> float:
    """
    Tutor perspective:
    - If either price missing → 1.0
    - If learner_max >= tutor_min → 1.0 (can afford tutor)
    - If learner_max < tutor_min → penalize by how far below tutor_min they are.
    """
    if tutor_min is None or learner_max is None:
        return 1.0

    try:
        t = float(tutor_min)
        m = float(learner_max)
    except Exception:
        return 1.0

    if t <= 0:
        return 1.0

    if m >= t:
        return 1.0

    deficit = (t - m) / t
    deficit = clamp01(deficit)
    return 1.0 - deficit


def capacity_score_tutor_learner(tutor_val, learner_val) -> float:
    """
    For hoursPerDay / daysPerWeek from tutor perspective.
    Symmetric logic:
    - If learner doesn't specify → 1.0
    - If tutor >= learner → 1.0
    - If tutor < learner → ratio (tutor / learner)
    """
    if learner_val is None:
        return 1.0

    l = safe_int(learner_val)
    if l <= 0:
        return 1.0

    t = safe_int(tutor_val)
    if t <= 0:
        return 0.0

    if t >= l:
        return 1.0

    return clamp01(t / l)


def compute_match_score_tutor_learner(tutor: Dict[str, Any], learner: Dict[str, Any]) -> float:
    components: List[float] = []

    # Subjects: fraction of learner's requested subjects the tutor can teach
    l_subs = set(learner.get("subjects") or [])
    t_subs = set(tutor.get("subjects") or [])
    if l_subs:
        overlap = len(l_subs & t_subs)
        components.append(overlap / len(l_subs))

    # Grades: fraction of learner's grades the tutor covers
    l_grades = set(learner.get("gradeLevels") or [])
    t_grades = set(tutor.get("gradeLevels") or [])
    if l_grades:
        overlap = len(l_grades & t_grades)
        components.append(overlap / len(l_grades))

    # Price from tutor perspective
    components.append(price_score_tutor_learner(
        tutor.get("minPricePerHour"),
        learner.get("maxPricePerHour"),
    ))

    # Hours / days
    components.append(capacity_score_tutor_learner(
        tutor.get("hoursPerDay"),
        learner.get("hoursPerDay"),
    ))
    components.append(capacity_score_tutor_learner(
        tutor.get("daysPerWeek"),
        learner.get("daysPerWeek"),
    ))

    if not components:
        return 0.0

    return sum(components) / len(components)


# ------------- FETCH USERS (with DEBUG) -------------


def fetch_users():
    users_ref = db.collection("users")
    docs = list(users_ref.stream())

    learners: List[Dict[str, Any]] = []
    tutors: List[Dict[str, Any]] = []

    print(f"[fetch_users] Total user docs in 'users' collection: {len(docs)}")

    for doc in docs:
        data = doc.to_dict() or {}
        data["id"] = doc.id

        role = data.get("role")
        completed = bool(data.get("completedProfile"))
        city = (data.get("city") or "").strip() or None
        subjects = data.get("subjects") or []
        grades = data.get("gradeLevels") or data.get("grades") or []
        hours_per_day = data.get("hoursPerDay")
        days_per_week = data.get("daysPerWeek")
        available = bool(data.get("available"))
        min_price = data.get("minPricePerHour")

        # Normalized lists
        if not isinstance(subjects, list):
            subjects = []
        if not isinstance(grades, list):
            grades = []

        def _print_prefix():
            return f"  • User {doc.id}: role={role}, completedProfile={completed}, city={city}, subjects={subjects}, grades={grades}, hpd={hours_per_day}, dpw={days_per_week}, available={available}, minPrice={min_price}"

        # Filter learners (student / parent)
        if role in ("student", "parent"):
            print(_print_prefix())
            # Strict "usable learner" criteria
            if not completed:
                print(f"    → SKIP {doc.id}: completedProfile is not True")
                continue
            if not city:
                print(f"    → SKIP {doc.id}: city is missing")
                continue
            if len(subjects) == 0:
                print(f"    → SKIP {doc.id}: subjects empty")
                continue
            if len(grades) == 0:
                print(f"    → SKIP {doc.id}: gradeLevels empty")
                continue
            if hours_per_day is None or days_per_week is None:
                print(f"    → SKIP {doc.id}: hoursPerDay/daysPerWeek missing")
                continue

            learners.append(data)
            print(f"    → ADD as learner (usable profile)")

        # Filter tutors
        elif role == "tutor":
            print(_print_prefix())
            if not completed:
                print(f"    → SKIP {doc.id}: completedProfile is not True")
                continue
            if not available:
                print(f"    → SKIP {doc.id}: tutor is not available")
                continue
            if not city:
                print(f"    → SKIP {doc.id}: city is missing")
                continue
            if len(subjects) == 0:
                print(f"    → SKIP {doc.id}: subjects empty")
                continue
            if len(grades) == 0:
                print(f"    → SKIP {doc.id}: gradeLevels empty")
                continue
            if hours_per_day is None or days_per_week is None:
                print(f"    → SKIP {doc.id}: hoursPerDay/daysPerWeek missing")
                continue
            # minPricePerHour can be None or > 0 (optional – change if you want it required)
            if min_price is not None and not isinstance(min_price, (int, float)):
                print(f"    → SKIP {doc.id}: minPricePerHour invalid type")
                continue

            tutors.append(data)
            print(f"    → ADD as tutor (available + usable profile)")

        else:
            print(f"  • User {doc.id}: role={role} → SKIP (unknown role)")

    print(f"[fetch_users] Result: {len(learners)} usable learners, {len(tutors)} usable tutors")
    return learners, tutors


# ------------- LEARNER → TUTOR RECOMMENDATIONS -------------


def build_recommendations_for_learners():
    learners, tutors = fetch_users()
    print(f"\n[build_recommendations_for_learners] learners={len(learners)}, tutors={len(tutors)}")

    if not learners or not tutors:
        print("Nothing to do (learners or tutors missing).")
        return

    for l in learners:
        lid = l["id"]
        lname = l.get("name") or "Learner"
        l_city = l.get("city")
        print(f"\n=== Learner {lname} ({lid}) in {l_city} ===")

        scored_items: List[Dict[str, Any]] = []

        total_checked = 0
        skipped_city = 0
        skipped_overlap = 0

        for t in tutors:
            total_checked += 1
            t_city = t.get("city")

            if not l_city or not t_city or l_city != t_city:
                skipped_city += 1
                continue

            l_subs = set(l.get("subjects") or [])
            t_subs = set(t.get("subjects") or [])
            l_grades = set(l.get("gradeLevels") or [])
            t_grades = set(t.get("gradeLevels") or [])

            subjects_overlap = l_subs & t_subs
            grades_overlap = l_grades & t_grades

            if not subjects_overlap and not grades_overlap:
                skipped_overlap += 1
                continue

            score = compute_match_score_learner_tutor(l, t)
            if score <= 0:
                continue

            reasons: List[str] = []

            if subjects_overlap:
                reasons.append("Teaches your subject: " + ", ".join(sorted(subjects_overlap)))

            if grades_overlap:
                reasons.append("Covers your grade level: " + ", ".join(sorted(grades_overlap)))

            if t_city:
                reasons.append(f"Located in {t_city}")

            pref = l.get("preferredTutorGender")
            if pref and pref != "no preference":
                if t.get("sex") == pref:
                    reasons.append(f"Matches your preferred tutor gender ({pref})")
                else:
                    reasons.append(f"Different from your preferred tutor gender ({pref})")

            l_max = l.get("maxPricePerHour")
            t_min = t.get("minPricePerHour")
            if l_max is not None and t_min is not None:
                try:
                    l_val = float(l_max)
                    t_val = float(t_min)
                    if t_val <= l_val:
                        reasons.append(f"Within your budget (ETB {t_val:.0f} ≤ your max {l_val:.0f})")
                    else:
                        reasons.append(f"Slightly above your budget (ETB {t_val:.0f} > {l_val:.0f})")
                except Exception:
                    pass

            lh = safe_int(l.get("hoursPerDay"))
            th = safe_int(t.get("hoursPerDay"))
            if lh > 0 and th > 0:
                if th >= lh:
                    reasons.append("Can teach at least as many hours per day as you want")
                else:
                    reasons.append("Offers fewer hours per day than you requested")

            ld = safe_int(l.get("daysPerWeek"))
            td = safe_int(t.get("daysPerWeek"))
            if ld > 0 and td > 0:
                if td >= ld:
                    reasons.append("Can teach at least as many days per week as you want")
                else:
                    reasons.append("Offers fewer days per week than you requested")

            print(
                f"    ✓ MATCH tutor {t['id']} ({t.get('name')}) "
                f"score={score:.3f}, subjects_overlap={subjects_overlap}, grades_overlap={grades_overlap}"
            )

            scored_items.append({
                "tutorId": t["id"],
                "name": t.get("name") or "Tutor",
                "city": t_city,
                "subjects": list(t_subs),
                "gradeLevels": list(t_grades),
                "minPricePerHour": t.get("minPricePerHour"),
                "score": score,
                "reasons": reasons,
            })

        print(
            f"  Summary for learner {lname} ({lid}): "
            f"checked={total_checked}, skipped_city={skipped_city}, "
            f"skipped_overlap={skipped_overlap}, matched={len(scored_items)}"
        )

        scored_items.sort(key=lambda x: x["score"], reverse=True)

        rec_doc = {
            "items": scored_items,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        print(f"  → Writing {len(scored_items)} recommendations to recommendations/{lid}")
        db.collection("recommendations").document(lid).set(rec_doc)


# ------------- TUTOR → LEARNER RECOMMENDATIONS -------------


def build_recommendations_for_tutors():
    learners, tutors = fetch_users()
    print(f"\n[build_recommendations_for_tutors] learners={len(learners)}, tutors={len(tutors)}")

    if not learners or not tutors:
        print("Nothing to do (learners or tutors missing).")
        return

    for t in tutors:
        tid = t["id"]
        tname = t.get("name") or "Tutor"
        t_city = t.get("city")
        print(f"\n=== Tutor {tname} ({tid}) in {t_city} ===")

        scored_learners: List[Dict[str, Any]] = []

        total_checked = 0
        skipped_city = 0
        skipped_overlap = 0

        for l in learners:
            total_checked += 1
            l_city = l.get("city")

            if not t_city or not l_city or t_city != l_city:
                skipped_city += 1
                continue

            l_subs = set(l.get("subjects") or [])
            t_subs = set(t.get("subjects") or [])
            l_grades = set(l.get("gradeLevels") or [])
            t_grades = set(t.get("gradeLevels") or [])

            subjects_overlap = l_subs & t_subs
            grades_overlap = l_grades & t_grades

            if not subjects_overlap and not grades_overlap:
                skipped_overlap += 1
                continue

            score = compute_match_score_tutor_learner(t, l)
            if score <= 0:
                continue

            reasons: List[str] = []

            if subjects_overlap:
                reasons.append("Wants your subject(s): " + ", ".join(sorted(subjects_overlap)))

            if grades_overlap:
                reasons.append("Matches your grade levels: " + ", ".join(sorted(grades_overlap)))

            if l_city:
                reasons.append(f"Located in {l_city}")

            t_min = t.get("minPricePerHour")
            l_max = l.get("maxPricePerHour")
            if t_min is not None and l_max is not None:
                try:
                    t_val = float(t_min)
                    l_val = float(l_max)
                    if l_val >= t_val:
                        reasons.append(f"Can afford your rate (max {l_val:.0f} ≥ your min {t_val:.0f})")
                    else:
                        reasons.append(f"Budget below your rate (max {l_val:.0f} < your min {t_val:.0f})")
                except Exception:
                    pass

            th = safe_int(t.get("hoursPerDay"))
            lh = safe_int(l.get("hoursPerDay"))
            if lh > 0 and th > 0:
                if th >= lh:
                    reasons.append("Their requested hours per day are within your availability")
                else:
                    reasons.append("They want more hours per day than you currently offer")

            td = safe_int(t.get("daysPerWeek"))
            ld = safe_int(l.get("daysPerWeek"))
            if ld > 0 and td > 0:
                if td >= ld:
                    reasons.append("Their requested days per week are within your availability")
                else:
                    reasons.append("They want more days per week than you currently offer")

            print(
                f"    ✓ MATCH learner {l['id']} ({l.get('name')}) "
                f"score={score:.3f}, subjects_overlap={subjects_overlap}, grades_overlap={grades_overlap}"
            )

            scored_learners.append({
                "learnerId": l["id"],
                "name": l.get("name") or "Learner",
                "city": l_city,
                "subjects": list(l_subs),
                "gradeLevels": list(l_grades),
                "maxPricePerHour": l.get("maxPricePerHour"),
                "score": score,
                "reasons": reasons,
            })

        print(
            f"  Summary for tutor {tname} ({tid}): "
            f"checked={total_checked}, skipped_city={skipped_city}, "
            f"skipped_overlap={skipped_overlap}, matched={len(scored_learners)}"
        )

        scored_learners.sort(key=lambda x: x["score"], reverse=True)

        rec_doc = {
            "items": scored_learners,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        print(f"  → Writing {len(scored_learners)} learners to tutor_recommendations/{tid}")
        db.collection("tutor_recommendations").document(tid).set(rec_doc)


# ------------- MAIN -------------


if __name__ == "__main__":
    print("\n=== RUNNING offline_recommender.py ===")
    # 1) learner → tutor recommendations
    build_recommendations_for_learners()

    # 2) tutor → learner recommendations
    build_recommendations_for_tutors()

    print("=== Done. ===")
