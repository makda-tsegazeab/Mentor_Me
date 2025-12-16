# ============================
# 0. Imports & config
# ============================
import os
import json
import numpy as np
import pandas as pd

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader, random_split

DATA_DIR = "data/"  # <--- CHANGE as needed

MF_RATINGS_PATH = os.path.join(DATA_DIR, "mf_ratings.csv")
LEARNER_MAP_PATH = os.path.join(DATA_DIR, "learner_id_map.json")
TUTOR_MAP_PATH   = os.path.join(DATA_DIR, "tutor_id_map.json")

ARTIFACT_DIR = os.path.join(DATA_DIR, "mf_artifacts")
os.makedirs(ARTIFACT_DIR, exist_ok=True)

print("DATA_DIR:", DATA_DIR)
print("ARTIFACT_DIR:", ARTIFACT_DIR)

# ============================
# 1. Load ratings data
# ============================
df = pd.read_csv(MF_RATINGS_PATH)
print(df.head())
print(f"Total interactions: {len(df)}")

# We expect columns: learner_idx, tutor_idx, score
assert all(c in df.columns for c in ["learner_idx", "tutor_idx", "score"]), \
    "mf_ratings.csv must have columns learner_idx,tutor_idx,score"

n_learners = int(df["learner_idx"].max()) + 1
n_tutors   = int(df["tutor_idx"].max()) + 1
print(f"n_learners = {n_learners}, n_tutors = {n_tutors}")

# ============================
# 2. Torch Dataset
# ============================
class MFDataset(Dataset):
    def __init__(self, ratings_df: pd.DataFrame):
        self.user = ratings_df["learner_idx"].values.astype(np.int64)
        self.item = ratings_df["tutor_idx"].values.astype(np.int64)
        self.y    = ratings_df["score"].values.astype(np.float32)

    def __len__(self):
        return len(self.y)

    def __getitem__(self, idx):
        return (
            self.user[idx],
            self.item[idx],
            self.y[idx],
        )

full_dataset = MFDataset(df)

# ============================
# 3. Train/val split
# ============================
val_ratio = 0.2
val_size = int(len(full_dataset) * val_ratio)
train_size = len(full_dataset) - val_size

train_dataset, val_dataset = random_split(
    full_dataset,
    [train_size, val_size],
    generator=torch.Generator().manual_seed(42),
)

print(f"Train size: {len(train_dataset)}, Val size: {len(val_dataset)}")

batch_size = 256
train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
val_loader   = DataLoader(val_dataset,   batch_size=batch_size, shuffle=False)

# ============================
# 4. MF Model
# ============================
class MFModel(nn.Module):
    def __init__(self, n_users, n_items, n_factors=32):
        super().__init__()
        self.user_factors = nn.Embedding(n_users, n_factors)   # P
        self.item_factors = nn.Embedding(n_items, n_factors)   # Q
        self.user_bias    = nn.Embedding(n_users, 1)
        self.item_bias    = nn.Embedding(n_items, 1)
        self.global_bias  = nn.Parameter(torch.zeros(1))

        # Init
        nn.init.normal_(self.user_factors.weight, std=0.05)
        nn.init.normal_(self.item_factors.weight, std=0.05)
        nn.init.zeros_(self.user_bias.weight)
        nn.init.zeros_(self.item_bias.weight)

    def forward(self, user_idx, item_idx):
        # user_idx, item_idx: [batch]
        p_u = self.user_factors(user_idx)  # [batch, k]
        q_i = self.item_factors(item_idx)  # [batch, k]
        b_u = self.user_bias(user_idx).squeeze(-1)  # [batch]
        b_i = self.item_bias(item_idx).squeeze(-1)  # [batch]

        dot = (p_u * q_i).sum(dim=1)
        return dot + b_u + b_i + self.global_bias


device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Using device:", device)

model = MFModel(n_learners, n_tutors, n_factors=32).to(device)

# ============================
# 5. Training setup
# ============================
criterion = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-2, weight_decay=1e-4)

n_epochs = 50
patience = 5
best_val_loss = float("inf")
epochs_no_improve = 0

# ============================
# 6. Training loop
# ============================
for epoch in range(1, n_epochs + 1):
    # ---- Train ----
    model.train()
    train_losses = []

    for user_idx, item_idx, y in train_loader:
        user_idx = user_idx.to(device)
        item_idx = item_idx.to(device)
        y = y.to(device)

        optimizer.zero_grad()
        y_hat = model(user_idx, item_idx)
        loss = criterion(y_hat, y)
        loss.backward()
        optimizer.step()

        train_losses.append(loss.item())

    train_loss = np.mean(train_losses) if train_losses else float("inf")

    # ---- Validation ----
    model.eval()
    val_losses = []
    with torch.no_grad():
        for user_idx, item_idx, y in val_loader:
            user_idx = user_idx.to(device)
            item_idx = item_idx.to(device)
            y = y.to(device)

            y_hat = model(user_idx, item_idx)
            loss = criterion(y_hat, y)
            val_losses.append(loss.item())

    val_loss = np.mean(val_losses) if val_losses else float("inf")

    print(f"Epoch {epoch:03d} | train_loss={train_loss:.4f} | val_loss={val_loss:.4f}")

    # Early stopping
    if val_loss < best_val_loss - 1e-4:  # small improvement threshold
        best_val_loss = val_loss
        epochs_no_improve = 0

        # Save checkpoint
        best_model_path = os.path.join(ARTIFACT_DIR, "mf_model_best.pt")
        torch.save(model.state_dict(), best_model_path)
        print(f"  ↳ New best model saved to {best_model_path}")
    else:
        epochs_no_improve += 1
        if epochs_no_improve >= patience:
            print("Early stopping.")
            break

# ============================
# 7. Load best model & export artifacts
# ============================
best_model_path = os.path.join(ARTIFACT_DIR, "mf_model_best.pt")
model.load_state_dict(torch.load(best_model_path, map_location=device))
model.eval()

# Export parameters
user_factors = model.user_factors.weight.detach().cpu().numpy()
item_factors = model.item_factors.weight.detach().cpu().numpy()
user_bias    = model.user_bias.weight.detach().cpu().numpy().squeeze(-1)
item_bias    = model.item_bias.weight.detach().cpu().numpy().squeeze(-1)
global_bias  = float(model.global_bias.detach().cpu().numpy()[0])

np.save(os.path.join(ARTIFACT_DIR, "learner_factors.npy"), user_factors)
np.save(os.path.join(ARTIFACT_DIR, "tutor_factors.npy"),   item_factors)
np.save(os.path.join(ARTIFACT_DIR, "learner_bias.npy"),    user_bias)
np.save(os.path.join(ARTIFACT_DIR, "tutor_bias.npy"),      item_bias)

metadata = {
    "n_learners": int(n_learners),
    "n_tutors":   int(n_tutors),
    "n_factors":  int(user_factors.shape[1]),
    "global_bias": global_bias,
    "mf_ratings_path": MF_RATINGS_PATH,
}
with open(os.path.join(ARTIFACT_DIR, "mf_metadata.json"), "w") as f:
    json.dump(metadata, f, indent=2)

print("Saved artifacts to:", ARTIFACT_DIR)
print("Done.")

# ============================
# 7. Evaluation on train & val
# ============================
def evaluate(loader, name: str):
    model.eval()
    mse_losses = []
    abs_errors = []

    with torch.no_grad():
        for user_idx, item_idx, y in loader:
            user_idx = user_idx.to(device)
            item_idx = item_idx.to(device)
            y = y.to(device)

            y_hat = model(user_idx, item_idx)

            # per-batch MSE and MAE
            mse_losses.append(((y_hat - y) ** 2).mean().item())
            abs_errors.append((y_hat - y).abs().mean().item())

    mse = float(np.mean(mse_losses)) if mse_losses else float("inf")
    rmse = float(np.sqrt(mse)) if mse < float("inf") else float("inf")
    mae = float(np.mean(abs_errors)) if abs_errors else float("inf")

    print(f"[EVAL] {name}: MSE={mse:.4f}, RMSE={rmse:.4f}, MAE={mae:.4f}")


# evaluate on the same splits we used during training
evaluate(train_loader, "Train")
evaluate(val_loader,   "Val (Test)")


