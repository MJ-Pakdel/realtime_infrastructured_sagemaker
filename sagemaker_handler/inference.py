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

# Configure logging - reduce to WARNING to minimize overhead
logger = logging.getLogger()
logger.setLevel(logging.WARNING)

# Global model cache to avoid reloading
_model = None

# These functions are required by the SageMaker scikit-learn container
def model_fn(model_dir):
    """Load model from the model_dir. This is the same model that was saved in
    the train.py example.
    """
    global _model
    if _model is not None:
        return _model
        
    logger.info("🔵 SageMaker container started")
    logger.info(f"📥 Loading model from: {model_dir}")
    model_path = os.path.join(model_dir, "model.joblib")
    _model = joblib.load(model_path)
    logger.info("✅ Model loaded successfully")
    return _model

def input_fn(request_body, request_content_type):
    """Parse input data payload"""
    # Skip verbose logging in production
    # logger.info(f"📥 Received request with content type: {request_content_type}")
    
    # first, normalize to a str
    if isinstance(request_body, (bytes, bytearray)):
        body_str = request_body.decode("utf-8")
    else:
        body_str = request_body

    if request_content_type == "text/csv":
        # Optimize CSV parsing for speed
        try:
            values = body_str.strip().split(",")
            result = np.array([float(x) for x in values])
            return result
        except Exception as e:
            logger.error(f"Error parsing CSV: {e}")
            raise ValueError(f"Invalid CSV format: {e}")

    elif request_content_type == "application/json":
        try:
            payload = json.loads(body_str)
            
            # Fast path for common formats
            if "instances" in payload:
                return np.array(payload["instances"])
            elif isinstance(payload, list):
                return np.array(payload)
            else:
                return np.array(payload.get("features", []))
        except Exception as e:
            logger.error(f"Error parsing JSON: {e}")
            raise ValueError(f"Invalid JSON format: {e}")
    else:
        error_msg = f"Unsupported content type: {request_content_type}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    
    
def predict_fn(input_data, model):
    """Predict using the model and input data
    """
    # Minimize reshaping overhead by checking shape once
    if len(input_data.shape) == 1:
        input_data = input_data.reshape(1, -1)
    
    return model.predict(input_data)

def output_fn(prediction, accept):
    """Format the prediction response
    """
    if accept == 'application/json':
        return json.dumps(prediction.tolist()), accept
    else:
        return str(prediction), accept