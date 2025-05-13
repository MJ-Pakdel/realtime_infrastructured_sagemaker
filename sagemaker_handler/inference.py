import os, json, joblib, logging, numpy as np

logger = logging.getLogger()
logger.setLevel(logging.WARNING)

_model = None

def model_fn(model_dir):
    global _model
    if _model is None:
        model_path = os.path.join(model_dir, "model.joblib")
        _model = joblib.load(model_path, mmap_mode="r")  # mmap = faster cold‑start
    return _model

def input_fn(request_body, content_type):
    body = request_body.decode() if isinstance(request_body, (bytes, bytearray)) else request_body

    if content_type == "text/csv":
        # C‑speed CSV → ndarray
        return np.fromstring(body, sep=",", dtype=np.float32)

    if content_type == "application/json":
        payload = json.loads(body)
        feats = (
            payload.get("instances")
            or payload.get("features")
            or payload
        )
        return np.asarray(feats, dtype=np.float32)

    raise ValueError(f"Unsupported content type: {content_type}")

def predict_fn(data, model):
    return model.predict(np.atleast_2d(data))

def output_fn(pred, accept):
    if accept == "application/json":
        return json.dumps(pred.tolist(), separators=(",", ":")), accept
    return str(pred), accept
