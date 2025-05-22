# lambda_handler/inference.py
import os, json, boto3, logging, time
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)               # keep timing logs visible

# ── AWS clients (reuse connection) ──────────────────────────────────
sm_runtime = boto3.client(
    "sagemaker-runtime",
    config=Config(retries={"max_attempts": 0})   # low latency, no retry
)
fs_runtime = boto3.client(
    "sagemaker-featurestore-runtime",
    config=Config(retries={"max_attempts": 3})   # a few retries OK
)

# env‑vars injected in Terraform
SAGEMAKER_ENDPOINT = os.environ["SAGEMAKER_ENDPOINT"]
FEATURE_GROUP      = os.environ["SM_FEATURE_GROUP"]   # new

# helper to pull ordered features f1..f8
def fetch_features(user_id: int) -> list[float]:
    t0 = time.perf_counter()
    rec = fs_runtime.get_record(
        FeatureGroupName=FEATURE_GROUP,
        RecordIdentifierValueAsString=str(user_id)
    )
    t1 = time.perf_counter()
    logger.info(f"get_record took {(t1 - t0)*1000:.1f} ms")

    # build a name‑>value map without casting event_ts
    fmap = {f["FeatureName"]: f["ValueAsString"] for f in rec["Record"]}

    # cast only the numeric features
    try:
        return [float(fmap[f"f{i}"]) for i in range(1, 9)]
    except KeyError as e:
        raise ValueError(f"Missing feature {e} for user_id={user_id}")

# Lambda entry‑point
def handler(event, _):
    # 1. Parse body -> user_id
    try:
        body    = json.loads(event.get("body", "{}"))
        user_id = body["user_id"]
    except (json.JSONDecodeError, KeyError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Payload must be JSON with numeric 'user_id'"})
        }

    # 2. Fetch features from Online Feature Store
    try:
        features = fetch_features(user_id)
    except Exception as e:
        logger.error(f"Feature lookup failed: {e}")
        return {"statusCode": 404,
                "body": json.dumps({"error": f"Features for user_id={user_id} not found"})}

    # 3. Build CSV payload
    csv_payload = ",".join(map(str, features)).encode()

    # 4. Call SageMaker endpoint with timing
    t0 = time.perf_counter()
    resp = sm_runtime.invoke_endpoint(
        EndpointName=SAGEMAKER_ENDPOINT,
        ContentType="text/csv",
        Body=csv_payload,
    )
    t1 = time.perf_counter()
    logger.info(f"invoke_endpoint took {(t1 - t0)*1000:.1f} ms")

    prediction = resp["Body"].read().decode()

    # 5. Return prediction (+ echo input for debugging)
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {"user_id": user_id, "features": features, "prediction": prediction},
            separators=(",", ":")
        ),
    }
