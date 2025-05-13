import boto3
import os
import subprocess
import json

# Use AWS profile "mj"
session = boto3.Session(profile_name="mj")
s3 = session.client("s3")

# Get the bucket name from Terraform outputs
tf_output = subprocess.check_output(["terraform", "output", "-json"]).decode("utf-8")
outputs = json.loads(tf_output)
bucket_name = outputs["artifact_bucket_name"]["value"]

# File details
local_file = os.path.join("sagemaker_handler", "model.tar.gz")
s3_key = "model/model.tar.gz"

# Upload file
s3.upload_file(local_file, bucket_name, s3_key)
print(f"✅ Uploaded to s3://{bucket_name}/{s3_key}")
