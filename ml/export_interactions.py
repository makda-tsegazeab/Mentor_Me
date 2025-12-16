import os
import csv
from typing import Any, Dict, List

import firebase_admin
from firebase_admin import credentials, firestore


SERVICE_ACCOUNT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "serviceAccountKey.json",
)

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")


def init_firestore():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()


def num(value: Any) -> int:
    if isinstance(value, (int, float)):
        return int(value)
    return 0


def export_interactions():
    os.makedirs(DATA_DIR, exist_ok=True)
    db = init_firestore()

    coll_ref = db.collection("learner_tutor_interactions")
    docs = list(coll_ref.stream())
    print(f"[export_interactions] Found {len(docs)} interaction docs")

    rows: List[Dict[str, Any]] = []

    for doc in docs:
        data = doc.to_dict() or {}
        learner_id = data.get("learnerId")
        tutor_id = data.get("tutorId")

        if not learner_id or not tutor_id:
            continue

        row = {
            "learnerId": learner_id,
            "tutorId": tutor_id,
            "viewCount": num(data.get("viewCount")),
            "messageCount": num(data.get("messageCount")),
            "requestCount": num(data.get("requestCount")),
            "rating": float(data.get("rating")) if isinstance(data.get("rating"), (int, float)) else "",
            "firstInteractionAt": data.get("firstInteractionAt").isoformat()
            if data.get("firstInteractionAt")
            else "",
            "lastInteractionAt": data.get("lastInteractionAt").isoformat()
            if data.get("lastInteractionAt")
            else "",
            "lastEventType": data.get("lastEventType") or "",
        }

        rows.append(row)

    interactions_path = os.path.join(DATA_DIR, "interactions.csv")

    if rows:
        with open(interactions_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "learnerId",
                    "tutorId",
                    "viewCount",
                    "messageCount",
                    "requestCount",
                    "rating",
                    "firstInteractionAt",
                    "lastInteractionAt",
                    "lastEventType",
                ],
            )
            writer.writeheader()
            writer.writerows(rows)

        print(f"[export_interactions] Wrote {len(rows)} rows to {interactions_path}")
    else:
        print("[export_interactions] No interaction rows to write.")


if __name__ == "__main__":
    export_interactions()
