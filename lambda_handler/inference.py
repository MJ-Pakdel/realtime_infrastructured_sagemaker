import os, json, boto3, logging, time
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)   # always log our timing info

# Reuse connection + skip extra retries
runtime = boto3.client(
    "sagemaker-runtime",
    config=Config(retries={"max_attempts": 0})
)

def handler(event, _):
    # 1. Extract features safely
    try:
        body = json.loads(event.get("body", "{}"))
        features = body["features"]
    except (json.JSONDecodeError, KeyError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid payload"})
        }

    # 2. Build CSV payload as bytes
    csv_payload = ",".join(map(str, features)).encode()

    # 3. Call SageMaker with timing
    t0 = time.perf_counter()
    resp = runtime.invoke_endpoint(
        EndpointName=os.environ["SAGEMAKER_ENDPOINT"],
        ContentType="text/csv",
        Body=csv_payload,
    )
    t1 = time.perf_counter()
    logger.info(f"invoke_endpoint took {(t1 - t0)*1000:.1f} ms")

    # 4. Stream → str (tiny)
    prediction = resp["Body"].read().decode()

    # 5. Respond
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {"features": features, "prediction": prediction},
            separators=(",", ":")
        ),
    }
