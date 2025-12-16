import os
import csv
from typing import Any, Dict, List

import firebase_admin
from firebase_admin import credentials, firestore


# Path to your service account JSON (project root)
SERVICE_ACCOUNT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "serviceAccountKey.json",
)

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")


def init_firestore():
    """Initialize Firestore client (singleton)."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()


def normalize_city(city: Any) -> str:
    """Normalize city to a clean string (no trailing spaces)."""
    if not city:
        return ""
    if isinstance(city, str):
        return city.strip()
    return str(city)


def list_to_str(value: Any) -> str:
    """Convert list fields (subjects, grades) to ';'-separated strings."""
    if value is None:
        return ""
    if isinstance(value, list):
        return ";".join(str(v) for v in value)
    return str(value)


def export_users():
    os.makedirs(DATA_DIR, exist_ok=True)
    db = init_firestore()

    users_ref = db.collection("users")
    docs = list(users_ref.stream())
    print(f"[export_users] Found {len(docs)} user docs")

    learners: List[Dict[str, Any]] = []
    tutors: List[Dict[str, Any]] = []

    for doc in docs:
        data = doc.to_dict() or {}
        uid = doc.id

        role = data.get("role")
        completed = data.get("completedProfile")
        city = normalize_city(data.get("city"))

        subjects = data.get("subjects") or data.get("subjectList")
        grades = data.get("grades") or data.get("gradeLevels")

        min_price = data.get("minPricePerHour")
        max_price = data.get("maxPricePerHour")
        available = data.get("available")

        display_name = (
            data.get("displayName")
            or data.get("name")
            or data.get("fullName")
            or ""
        )

        # Base row, we'll adapt the id field name when writing to CSV
        base_row = {
            "role": role,
            "displayName": display_name,
            "city": city,
            "subjects": list_to_str(subjects),
            "grades": list_to_str(grades),
            "minPricePerHour": float(min_price) if isinstance(min_price, (int, float)) else "",
            "maxPricePerHour": float(max_price) if isinstance(max_price, (int, float)) else "",
            "available": bool(available) if isinstance(available, bool) else "",
        }

        # Only export completed profiles
        if completed is True:
            if role in ("student", "parent"):
                # For learners.csv we want 'learnerId'
                row = {"learnerId": uid}
                row.update(base_row)
                learners.append(row)
            elif role == "tutor":
                # For tutors.csv we want 'tutorId'
                row = {"tutorId": uid}
                row.update(base_row)
                tutors.append(row)

    learners_path = os.path.join(DATA_DIR, "learners.csv")
    tutors_path = os.path.join(DATA_DIR, "tutors.csv")

    print(f"[export_users] {len(learners)} learners with completedProfile")
    print(f"[export_users] {len(tutors)} tutors with completedProfile")

    if learners:
        with open(learners_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "learnerId",      # <-- important for generate_synthetic_interactions.py
                    "role",
                    "displayName",
                    "city",
                    "subjects",
                    "grades",
                    "minPricePerHour",
                    "maxPricePerHour",
                    "available",
                ],
            )
            writer.writeheader()
            writer.writerows(learners)
        print(f"[export_users] Wrote learners to {learners_path}")

    if tutors:
        with open(tutors_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "tutorId",        # <-- important for generate_synthetic_interactions.py
                    "role",
                    "displayName",
                    "city",
                    "subjects",
                    "grades",
                    "minPricePerHour",
                    "maxPricePerHour",
                    "available",
                ],
            )
            writer.writeheader()
            writer.writerows(tutors)
        print(f"[export_users] Wrote tutors to {tutors_path}")


if __name__ == "__main__":
    export_users()
