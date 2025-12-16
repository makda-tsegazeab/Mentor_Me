#!/usr/bin/env python
"""
generate_synthetic_interactions.py

Reads learners.csv and tutors.csv from ./data and generates a synthetic
mf_interactions_real.csv with interaction_score based on:

  - viewCount
  - messageCount
  - requestCount
  - rating
  - recency (lastInteractionAt)

This does NOT touch Firestore. It's purely offline synthetic data generation
for training a demo MF model.

Run from the ml/ folder:
    python generate_synthetic_interactions.py
"""

import os
import math
import random
from datetime import datetime, timedelta

import pandas as pd

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")

LEARNERS_CSV = os.path.join(DATA_DIR, "learners.csv")
TUTORS_CSV = os.path.join(DATA_DIR, "tutors.csv")
OUTPUT_CSV = os.path.join(DATA_DIR, "mf_interactions_real.csv")

# ------------------------------
# Hyperparameters for generation
# ------------------------------

# How many tutors to consider per learner on average
MAX_TUTORS_PER_LEARNER = 10

# Probability to create an interaction if learner & tutor are in same city
P_INTERACT_SAME_CITY = 0.8

# Probability to create an interaction if different city
P_INTERACT_DIFF_CITY = 0.2

# Weights as agreed
W_VIEW = 0.5
W_MESSAGE = 1.0
W_REQUEST = 3.0
W_RATING = 1.5

# Recency scale (days)
RECENCY_SCALE_DAYS = 90.0


def _find_id_column(df: pd.DataFrame, preferred_names):
    """
    Try to find an ID column name from a list of preferred names.
    """
    for name in preferred_names:
        if name in df.columns:
            return name
    raise ValueError(f"Could not find any of {preferred_names} in columns: {df.columns.tolist()}")


def load_learners_and_tutors():
    if not os.path.exists(LEARNERS_CSV):
        raise FileNotFoundError(f"{LEARNERS_CSV} not found. Did you run export_learners_tutors.py?")
    if not os.path.exists(TUTORS_CSV):
        raise FileNotFoundError(f"{TUTORS_CSV} not found. Did you run export_learners_tutors.py?")

    learners = pd.read_csv(data/learners.csv)
    tutors = pd.read_csv(data/tutors.csv)

    # --- Adjust these depending on your export script ---
    learner_id_col = _find_id_column(learners, ["learnerId", "uid", "id"])
    tutor_id_col = _find_id_column(tutors, ["tutorId", "uid", "id"])
    # City columns (case-insensitive fallbacks)
    learner_city_col = _find_id_column(
        learners, ["city", "City"]
    )
    tutor_city_col = _find_id_column(
        tutors, ["city", "City"]
    )

    learners = learners[[learner_id_col, learner_city_col]].rename(
        columns={learner_id_col: "learnerId", learner_city_col: "learnerCity"}
    )
    tutors = tutors[[tutor_id_col, tutor_city_col]].rename(
        columns={tutor_id_col: "tutorId", tutor_city_col: "tutorCity"}
    )

    # Normalize cities to lowercase for matching
    learners["learnerCity"] = learners["learnerCity"].astype(str).str.strip().str.lower()
    tutors["tutorCity"] = tutors["tutorCity"].astype(str).str.strip().str.lower()

    return learners, tutors


def sample_counts_and_rating():
    """
    Sample synthetic (viewCount, messageCount, requestCount, rating).
    Heuristic:
      - most pairs have some views
      - fewer have messages
      - even fewer have requests & ratings
    """
    # at least some views
    view_count = random.randint(1, 5)

    # 60% chance to have messages
    if random.random() < 0.6:
        message_count = random.randint(1, 5)
    else:
        message_count = 0

    # 30% chance to have a request if there are messages
    if message_count > 0 and random.random() < 0.3:
        request_count = random.randint(1, 3)
    else:
        request_count = 0

    # 40% chance to have a rating if there's at least one request
    if request_count > 0 and random.random() < 0.4:
        # slightly biased high (3–5 stars)
        rating = random.randint(3, 5)
    else:
        rating = None

    return view_count, message_count, request_count, rating


def compute_interaction_score(view_count, message_count, request_count, rating, days_ago):
    """
    Compute your agreed interaction_score.
    """
    view_term = W_VIEW * min(view_count, 5)
    message_term = W_MESSAGE * min(message_count, 5)
    request_term = W_REQUEST * min(request_count, 3)
    rating_term = 0.0
    if rating is not None:
        rating_term = W_RATING * (float(rating) / 5.0)

    raw_score = view_term + message_term + request_term + rating_term

    age_days = float(days_ago)
    recency_factor = math.exp(-age_days / RECENCY_SCALE_DAYS)

    return raw_score * recency_factor


def generate_synthetic_interactions(learners: pd.DataFrame, tutors: pd.DataFrame):
    """
    Generate a synthetic interactions DataFrame with columns:
      learnerId, tutorId, viewCount, messageCount, requestCount, rating,
      lastInteractionAt (ISO date), interaction_score
    """
    rows = []
    now = datetime.utcnow()

    learner_ids = learners["learnerId"].tolist()
    tutor_ids = tutors["tutorId"].tolist()

    print(f"[generate] learners={len(learner_ids)}, tutors={len(tutor_ids)}")

    for _, lrow in learners.iterrows():
        lid = lrow["learnerId"]
        lcity = lrow["learnerCity"]

        # For each learner, pick a subset of tutors to consider (up to MAX_TUTORS_PER_LEARNER)
        # Prefer tutors in the same city.
        same_city_tutors = tutors[tutors["tutorCity"] == lcity]["tutorId"].tolist()
        other_tutors = tutors[tutors["tutorCity"] != lcity]["tutorId"].tolist()

        selected_tutors = []

        # First sample from same city
        random.shuffle(same_city_tutors)
        selected_tutors.extend(same_city_tutors[: MAX_TUTORS_PER_LEARNER])

        # If not enough, pad with other tutors
        if len(selected_tutors) < MAX_TUTORS_PER_LEARNER:
            random.shuffle(other_tutors)
            needed = MAX_TUTORS_PER_LEARNER - len(selected_tutors)
            selected_tutors.extend(other_tutors[:needed])

        # Now decide for each selected tutor whether to create an interaction row
        for tid in selected_tutors:
            tcity = tutors.loc[tutors["tutorId"] == tid, "tutorCity"].iloc[0]

            same_city = (lcity == tcity)
            p_interact = P_INTERACT_SAME_CITY if same_city else P_INTERACT_DIFF_CITY

            if random.random() > p_interact:
                continue  # no interaction for this pair

            view_count, message_count, request_count, rating = sample_counts_and_rating()

            # Sample how many days ago this interaction "happened"
            days_ago = random.randint(0, 365)
            last_interaction_dt = now - timedelta(days=days_ago)
            last_interaction_iso = last_interaction_dt.date().isoformat()

            score = compute_interaction_score(
                view_count=view_count,
                message_count=message_count,
                request_count=request_count,
                rating=rating,
                days_ago=days_ago,
            )

            if score <= 0:
                continue

            rows.append(
                {
                    "learnerId": lid,
                    "tutorId": tid,
                    "viewCount": view_count,
                    "messageCount": message_count,
                    "requestCount": request_count,
                    "rating": rating,
                    "lastInteractionAt": last_interaction_iso,
                    "interaction_score": score,
                }
            )

    df = pd.DataFrame(rows)
    print(f"[generate] created {len(df)} synthetic interaction rows.")
    return df


def main():
    os.makedirs(DATA_DIR, exist_ok=True)

    learners, tutors = load_learners_and_tutors()
    df = generate_synthetic_interactions(learners, tutors)

    if df.empty:
        print("[generate] WARNING: no synthetic interactions generated.")
    else:
        df.to_csv(OUTPUT_CSV, index=False)
        print(f"[generate] Wrote synthetic interactions to {OUTPUT_CSV}")


if __name__ == "__main__":
    main()
