import os
import json
import pandas as pd

# Paths
BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")

INTERACTIONS_PATH = os.path.join(DATA_DIR, "mf_interactions_real.csv")
MF_RATINGS_PATH = os.path.join(DATA_DIR, "mf_ratings.csv")
LEARNER_MAP_PATH = os.path.join(DATA_DIR, "learner_id_map.json")
TUTOR_MAP_PATH = os.path.join(DATA_DIR, "tutor_id_map.json")


def build_id_maps(df: pd.DataFrame):
    """
    Build integer index mappings for learners and tutors:
      learnerId -> 0..(num_learners-1)
      tutorId   -> 0..(num_tutors-1)
    """
    learner_ids = sorted(df["learnerId"].unique().tolist())
    tutor_ids = sorted(df["tutorId"].unique().tolist())

    learner_id_map = {lid: idx for idx, lid in enumerate(learner_ids)}
    tutor_id_map = {tid: idx for idx, tid in enumerate(tutor_ids)}

    return learner_id_map, tutor_id_map


def main():
    if not os.path.exists(INTERACTIONS_PATH):
        print(f"[prepare_mf_data] ERROR: {INTERACTIONS_PATH} not found.")
        return

    df = pd.read_csv(INTERACTIONS_PATH)
    print(f"[prepare_mf_data] Loaded {len(df)} rows from {INTERACTIONS_PATH}")

    # Safety: drop rows with missing ids or non-positive scores
    before = len(df)
    df = df.dropna(subset=["learnerId", "tutorId", "interaction_score"])
    df = df[df["interaction_score"] > 0]
    after = len(df)
    print(f"[prepare_mf_data] Kept {after}/{before} rows with valid ids and score>0")

    # Build maps
    learner_id_map, tutor_id_map = build_id_maps(df)
    print(f"[prepare_mf_data] Unique learners: {len(learner_id_map)}")
    print(f"[prepare_mf_data] Unique tutors:   {len(tutor_id_map)}")

    # Apply maps
    df["learner_idx"] = df["learnerId"].map(learner_id_map)
    df["tutor_idx"] = df["tutorId"].map(tutor_id_map)

    # Create MF ratings dataframe
    mf_df = df[["learner_idx", "tutor_idx", "interaction_score"]].copy()
    mf_df = mf_df.rename(columns={"interaction_score": "score"})

    # Save data & maps
    os.makedirs(DATA_DIR, exist_ok=True)
    mf_df.to_csv(MF_RATINGS_PATH, index=False)
    print(f"[prepare_mf_data] Wrote MF ratings to {MF_RATINGS_PATH}")

    with open(LEARNER_MAP_PATH, "w") as f:
        json.dump(learner_id_map, f, indent=2)
    with open(TUTOR_MAP_PATH, "w") as f:
        json.dump(tutor_id_map, f, indent=2)

    print(f"[prepare_mf_data] Wrote learner_id_map to {LEARNER_MAP_PATH}")
    print(f"[prepare_mf_data] Wrote tutor_id_map   to {TUTOR_MAP_PATH}")
    print("[prepare_mf_data] Done.")


if __name__ == "__main__":
    main()
