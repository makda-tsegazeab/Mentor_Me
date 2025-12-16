import os
import json
from typing import Dict, Any, List

import numpy as np
import pandas as pd

import firebase_admin
from firebase_admin import credentials, firestore

print("[build_mf_recommendations] Script imported.")

# ============================
# 0. Paths & constants
# ============================

BASE_DIR = os.path.dirname(__file__)          # .../hey_tutor/ml
DATA_DIR = os.path.join(BASE_DIR, "data")     # .../hey_tutor/ml/data
ARTIFACT_DIR = os.path.join(DATA_DIR, "mf_artifacts")

MF_RATINGS_PATH = os.path.join(DATA_DIR, "mf_ratings.csv")
LEARNERS_CSV = os.path.join(DATA_DIR, "learners.csv")
TUTORS_CSV = os.path.join(DATA_DIR, "tutors.csv")

LEARNER_MAP_PATH = os.path.join(DATA_DIR, "learner_id_map.json")
TUTOR_MAP_PATH   = os.path.join(DATA_DIR, "tutor_id_map.json")

LEARNER_FACTORS_PATH = os.path.join(ARTIFACT_DIR, "learner_factors.npy")
TUTOR_FACTORS_PATH   = os.path.join(ARTIFACT_DIR, "tutor_factors.npy")
LEARNER_BIAS_PATH    = os.path.join(ARTIFACT_DIR, "learner_bias.npy")
TUTOR_BIAS_PATH      = os.path.join(ARTIFACT_DIR, "tutor_bias.npy")
METADATA_PATH        = os.path.join(ARTIFACT_DIR, "mf_metadata.json")

MF_RECS_CSV = os.path.join(DATA_DIR, "mf_recommendations.csv")

SERVICE_ACCOUNT_PATH = os.path.join(
    os.path.dirname(BASE_DIR),  # go up from ml/ → project root
    "serviceAccountKey.json",
)

FIRESTORE_MF_COLLECTION = "mf_recommendations"


# ============================
# 1. Firestore init
# ============================

def init_firestore():
    print("[init_firestore] Initializing Firestore...")
    if not firebase_admin._apps:
        if not os.path.exists(SERVICE_ACCOUNT_PATH):
            raise FileNotFoundError(
                f"Service account JSON not found at {SERVICE_ACCOUNT_PATH}"
            )
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()


# ============================
# 2. Load artifacts & mappings
# ============================

def load_artifacts():
    print("[load_artifacts] Checking required files...")

    required = [
        LEARNER_FACTORS_PATH,
        TUTOR_FACTORS_PATH,
        LEARNER_BIAS_PATH,
        TUTOR_BIAS_PATH,
        METADATA_PATH,
        LEARNER_MAP_PATH,
        TUTOR_MAP_PATH,
    ]
    for p in required:
        print(f"  - {p}: {'OK' if os.path.exists(p) else 'MISSING'}")
        if not os.path.exists(p):
            raise FileNotFoundError(f"Required file missing: {p}")

    print("[load_artifacts] Loading numpy embeddings and biases...")
    learner_factors = np.load(LEARNER_FACTORS_PATH)
    tutor_factors   = np.load(TUTOR_FACTORS_PATH)
    learner_bias    = np.load(LEARNER_BIAS_PATH)
    tutor_bias      = np.load(TUTOR_BIAS_PATH)

    with open(METADATA_PATH, "r") as f:
        meta = json.load(f)

    with open(LEARNER_MAP_PATH, "r") as f:
        learner_id_map = json.load(f)
    with open(TUTOR_MAP_PATH, "r") as f:
        tutor_id_map = json.load(f)

    inv_learner_map = {int(v): k for k, v in learner_id_map.items()}
    inv_tutor_map   = {int(v): k for k, v in tutor_id_map.items()}

    print("[load_artifacts] Loaded artifacts successfully.")
    print(f"  learner_factors shape: {learner_factors.shape}")
    print(f"  tutor_factors   shape: {tutor_factors.shape}")

    return (
        learner_factors,
        tutor_factors,
        learner_bias,
        tutor_bias,
        float(meta["global_bias"]),
        learner_id_map,
        tutor_id_map,
        inv_learner_map,
        inv_tutor_map,
        meta,
    )


# ============================
# 3. User metadata helpers
# ============================

def normalize_city(city: Any) -> str:
    if not city:
        return ""
    if isinstance(city, str):
        return city.strip()
    return str(city)


def detect_id_column(df: pd.DataFrame, kind: str) -> str | None:
    """
    Try to find the column that contains the Firestore user id.
    We support various names: 'userId', 'uid', 'id'.
    """
    candidates = ["userId", "uid", "id","learnerId","tutorId"]
    print(f"[load_user_metadata] {kind} CSV columns: {list(df.columns)}")
    for c in candidates:
        if c in df.columns:
            print(f"[load_user_metadata] Using '{c}' as id column for {kind}.")
            return c
    print(f"[load_user_metadata] No id column found for {kind} (tried {candidates}).")
    return None


def load_user_metadata():
    learner_meta: Dict[str, Dict[str, Any]] = {}
    tutor_meta: Dict[str, Dict[str, Any]] = {}

    # ---- Learners ----
    print(f"[load_user_metadata] Looking for {LEARNERS_CSV}")
    if os.path.exists(LEARNERS_CSV):
        df_learners = pd.read_csv(LEARNERS_CSV)
        print(f"[load_user_metadata] Loaded {len(df_learners)} learners.")
        id_col = detect_id_column(df_learners, "learners")
        if id_col is not None:
            for _, row in df_learners.iterrows():
                uid = str(row[id_col])
                learner_meta[uid] = {
                    "userId": uid,
                    "displayName": str(row.get("displayName", "")),
                    "city": normalize_city(row.get("city", "")),
                    "subjects": str(row.get("subjects", "")),
                    "grades": str(row.get("grades", "")),
                }
        else:
            print("[load_user_metadata] WARNING: learner metadata will not have IDs.")
    else:
        print(f"[WARN] {LEARNERS_CSV} not found – learner metadata will be empty.")

    # ---- Tutors ----
    print(f"[load_user_metadata] Looking for {TUTORS_CSV}")
    if os.path.exists(TUTORS_CSV):
        df_tutors = pd.read_csv(TUTORS_CSV)
        print(f"[load_user_metadata] Loaded {len(df_tutors)} tutors.")
        id_col = detect_id_column(df_tutors, "tutors")
        if id_col is not None:
            for _, row in df_tutors.iterrows():
                uid = str(row[id_col])
                tutor_meta[uid] = {
                    "userId": uid,
                    "displayName": str(row.get("displayName", "")),
                    "city": normalize_city(row.get("city", "")),
                    "subjects": str(row.get("subjects", "")),
                    "grades": str(row.get("grades", "")),
                }
        else:
            print("[load_user_metadata] WARNING: tutor metadata will not have IDs.")
    else:
        print(f"[WARN] {TUTORS_CSV} not found – tutor metadata will be empty.")

    return learner_meta, tutor_meta


# ============================
# 4. Predict scores matrix
# ============================

def predict_scores_for_all(
    learner_factors: np.ndarray,
    tutor_factors: np.ndarray,
    learner_bias: np.ndarray,
    tutor_bias: np.ndarray,
    global_bias: float,
) -> np.ndarray:
    print("[predict_scores_for_all] Computing full score matrix...")
    base = learner_factors @ tutor_factors.T          # [n_learners, n_tutors]
    base += learner_bias.reshape(-1, 1)
    base += tutor_bias.reshape(1, -1)
    base += global_bias
    print("[predict_scores_for_all] Done.")
    return base


# ============================
# 5. Build MF recommendations (NO CITY FILTER)
# ============================

def build_mf_recommendations(
    preds: np.ndarray,
    inv_learner_map: Dict[int, str],
    inv_tutor_map: Dict[int, str],
    learner_meta: Dict[str, Dict[str, Any]],
    tutor_meta: Dict[str, Dict[str, Any]],
    top_k: int = 20,
) -> pd.DataFrame:
    """
    Pure collaborative filtering:
      - NO city filtering at all.
      - For each learner, use ALL tutors, sort by score_mf, keep top_k.
      - City/subjects/grades are just metadata in the output.
    """
    n_learners, n_tutors = preds.shape
    print(f"[build_mf_recommendations] preds shape = {preds.shape}")

    rows: List[Dict[str, Any]] = []

    for u_idx in range(n_learners):
        learner_id = inv_learner_map.get(u_idx)
        if learner_id is None:
            continue

        lmeta = learner_meta.get(learner_id, {})
        learner_city = normalize_city(lmeta.get("city", ""))

        scores = preds[u_idx]

        # ALL tutors as candidates
        candidate_indices = list(range(n_tutors))
        candidate_scores = [(t_idx, scores[t_idx]) for t_idx in candidate_indices]
        candidate_scores.sort(key=lambda x: x[1], reverse=True)

        for t_idx, s in candidate_scores[:top_k]:
            tutor_id = inv_tutor_map.get(t_idx)
            if tutor_id is None:
                continue

            tmeta = tutor_meta.get(tutor_id, {})
            rows.append(
                {
                    "learnerId": learner_id,
                    "learnerCity": learner_city,
                    "tutorId": tutor_id,
                    "tutorCity": normalize_city(tmeta.get("city", "")),
                    "score_mf": float(s),
                    "tutorName": tmeta.get("displayName", ""),
                    "tutorSubjects": tmeta.get("subjects", ""),
                    "tutorGrades": tmeta.get("grades", ""),
                }
            )

    df_recs = pd.DataFrame(rows)
    print(f"[build_mf_recommendations] Built {len(df_recs)} MF rec rows.")
    return df_recs


# ============================
# 6. Save CSV
# ============================

def save_recs_csv(df_recs: pd.DataFrame):
    os.makedirs(DATA_DIR, exist_ok=True)
    df_recs.to_csv(MF_RECS_CSV, index=False)
    print(f"[save_recs_csv] Wrote MF recommendations to {MF_RECS_CSV}")


# ============================
# 7. Push to Firestore
# ============================

def push_to_firestore(df_recs: pd.DataFrame, batch_size: int = 200):
    if df_recs.empty:
        print("[push_to_firestore] No rows to write, skipping Firestore.")
        return

    db = init_firestore()
    coll_ref = db.collection(FIRESTORE_MF_COLLECTION)

    grouped = df_recs.groupby("learnerId")
    total_learners = len(grouped)
    print(f"[push_to_firestore] Writing MF recs for {total_learners} learners...")

    batch = db.batch()
    ops = 0
    written_docs = 0

    for learner_id, group in grouped:
        doc_ref = coll_ref.document(learner_id)

        group_sorted = group.sort_values("score_mf", ascending=False)
        items = []
        for _, row in group_sorted.iterrows():
            items.append(
                {
                    "tutorId": row["tutorId"],
                    "score_mf": float(row["score_mf"]),
                    "tutorName": row.get("tutorName", ""),
                    "tutorCity": row.get("tutorCity", ""),
                    "tutorSubjects": row.get("tutorSubjects", ""),
                    "tutorGrades": row.get("tutorGrades", ""),
                }
            )

        batch.set(
            doc_ref,
            {
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "items": items,
            },
        )
        ops += 1
        written_docs += 1

        if ops >= batch_size:
            batch.commit()
            print(f"[push_to_firestore] Committed batch of {ops} learner docs...")
            batch = db.batch()
            ops = 0

    if ops > 0:
        batch.commit()
        print(f"[push_to_firestore] Committed final batch of {ops} learner docs.")

    print(f"[push_to_firestore] Done. Total learner docs written: {written_docs}")


# ============================
# 8. Main
# ============================

def main():
    print("[main] Starting build_mf_recommendations...")
    print(f"[main] BASE_DIR={BASE_DIR}")
    print(f"[main] DATA_DIR={DATA_DIR}")
    print(f"[main] ARTIFACT_DIR={ARTIFACT_DIR}")

    (
        learner_factors,
        tutor_factors,
        learner_bias,
        tutor_bias,
        global_bias,
        learner_id_map,
        tutor_id_map,
        inv_learner_map,
        inv_tutor_map,
        meta,
    ) = load_artifacts()

    learner_meta, tutor_meta = load_user_metadata()

    preds = predict_scores_for_all(
        learner_factors,
        tutor_factors,
        learner_bias,
        tutor_bias,
        global_bias,
    )

    df_recs = build_mf_recommendations(
        preds,
        inv_learner_map,
        inv_tutor_map,
        learner_meta,
        tutor_meta,
        top_k=20,
    )

    save_recs_csv(df_recs)
    push_to_firestore(df_recs)

    print("[main] All done.")


if __name__ == "__main__":
    main()
