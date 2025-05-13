import os, json, boto3, logging
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.WARNING)                     # INFO only in dev

# Reuse connection + skip extra retries
runtime = boto3.client(
    "sagemaker-runtime",
    config=Config(retries={"max_attempts": 0})
)

def handler(event, _):
    # 1. Extract features safely
    try:
        body = json.loads(event.get("body", "{}"))
        features = body["features"]                 # KeyError → 400 later
    except (json.JSONDecodeError, KeyError):
        return {"statusCode": 400,
                "body": json.dumps({"error": "Invalid payload"})}

    # 2. Build CSV payload as bytes
    csv_payload = (",".join(map(str, features))).encode()

    # 3. Call SageMaker
    resp = runtime.invoke_endpoint(
        EndpointName=os.environ["SAGEMAKER_ENDPOINT"],
        ContentType="text/csv",
        Body=csv_payload,
    )

    # 4. Stream → str (tiny)
    prediction = resp["Body"].read().decode()

    # 5. Respond
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {"features": features, "prediction": prediction},
            separators=(",", ":")                   # lean JSON
        ),
    }
