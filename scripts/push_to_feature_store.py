#!/usr/bin/env python3
import subprocess, boto3, pandas as pd
from datetime import datetime, timezone
from sklearn.datasets import make_regression
from botocore.config import Config

# ── Feature Group name from Terraform ───────────────────────────────
FG_NAME = subprocess.check_output(
    "terraform output -raw feature_group_name", shell=True, text=True
).strip()

# ── generate just 50 synthetic rows × 8 features ────────────────────
ROWS = 50
X, _ = make_regression(n_samples=ROWS, n_features=8, noise=0.1, random_state=0)
df = pd.DataFrame(X, columns=[f"f{i}" for i in range(1, 9)])
df.insert(0, "user_id", range(ROWS))                            # primary key
df.insert(1, "event_ts",
          datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))

# ── push each record into the online store ──────────────────────────
fs = boto3.client("sagemaker-featurestore-runtime",
                  config=Config(retries={"max_attempts": 10}))

for _, row in df.iterrows():
    record = (
        [{"FeatureName": "user_id",   "ValueAsString": str(int(row.user_id))},
         {"FeatureName": "event_ts",  "ValueAsString": row.event_ts}] +
        [{"FeatureName": f"f{i}",     "ValueAsString": str(row[f'f{i}'])}
         for i in range(1, 9)]
    )
    fs.put_record(FeatureGroupName=FG_NAME, Record=record)

print(f"✅ Ingested {ROWS} rows into online Feature Group '{FG_NAME}'")
