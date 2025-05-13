import os
import json
import boto3
import joblib
import numpy as np
import io
import logging

# Environment variable must be set in Terraform/Lambda config
ENDPOINT_NAME = os.environ.get("SAGEMAKER_ENDPOINT")

# SageMaker Runtime client
runtime = boto3.client("sagemaker-runtime")

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# These functions are required by the SageMaker scikit-learn container
def model_fn(model_dir):
    """Load model from the model_dir. This is the same model that was saved in
    the train.py example.
    """
    logger.info("🔵 SageMaker container started")
    logger.info(f"📥 Loading model from: {model_dir}")
    model_path = os.path.join(model_dir, "model.joblib")
    model = joblib.load(model_path)
    logger.info("✅ Model loaded successfully")
    return model

def input_fn(request_body, request_content_type):
    """Parse input data payload"""
    logger.info(f"📥 Received request with content type: {request_content_type}")
    logger.info(f"📦 Raw request body: {request_body}")

    # first, normalize to a str
    if isinstance(request_body, (bytes, bytearray)):
        body_str = request_body.decode("utf-8")
    else:
        body_str = request_body

    logger.info(f"📝 Normalized body: {body_str}")

    if request_content_type == "text/csv":
        # split on commas, turn into floats
        values = body_str.strip().split(",")
        result = np.array([float(x) for x in values])
        logger.info(f"📊 Parsed CSV input: {result}")
        return result

    elif request_content_type == "application/json":
        payload = json.loads(body_str)
        logger.info(f"📦 Parsed JSON payload: {payload}")
        
        # support both {"instances":[[...]]} and {"features":[...]}
        if "instances" in payload:
            result = np.array(payload["instances"])
        elif isinstance(payload, list):
            result = np.array(payload)
        else:
            result = np.array(payload.get("features", []))
        
        logger.info(f"📊 Parsed JSON input: {result}")
        return result

    else:
        error_msg = f"Unsupported content type: {request_content_type}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    
    
def predict_fn(input_data, model):
    """Predict using the model and input data
    """
    logger.info(f"🔮 Predicting with input shape: {input_data.shape}")
    # Reshape the input if needed
    if len(input_data.shape) == 1:
        input_data = input_data.reshape(1, -1)
        logger.info(f"📐 Reshaped input to: {input_data.shape}")
    
    prediction = model.predict(input_data)
    logger.info(f"✨ Prediction result: {prediction}")
    return prediction

def output_fn(prediction, accept):
    """Format the prediction response
    """
    logger.info(f"📤 Formatting response for accept type: {accept}")
    if accept == 'application/json':
        result = json.dumps(prediction.tolist()), accept
    else:
        result = str(prediction), accept
    
    logger.info(f"✅ Returning response: {result[0]}")
    return result