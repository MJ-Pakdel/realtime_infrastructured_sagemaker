# inference.py

import os
import json
import boto3
import logging

# Configure logging - reduce logging in production
logger = logging.getLogger()
logger.setLevel(logging.WARNING)

# Initialize SageMaker runtime client - create once at init time
runtime = boto3.client('sagemaker-runtime')

def handler(event, context):
    """
    Lambda handler function that receives requests from API Gateway
    and forwards them to SageMaker endpoint.
    """
    try:
        # Get the SageMaker endpoint name from environment variable
        endpoint_name = os.environ['SAGEMAKER_ENDPOINT']
        
        # Parse the incoming request body - fast path
        if 'body' in event:
            body = json.loads(event['body'])
            features = body.get('features', [])
        else:
            # Handle direct invocation case
            features = event.get('features', [])
        
        # Create instances format expected by SageMaker endpoint
        # Use JSON for better performance (avoids string parsing overhead)
        payload = json.dumps({"instances": [features]})
        
        # Invoke SageMaker endpoint with JSON instead of CSV
        response = runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='application/json',
            Body=payload
        )
        
        # Parse the prediction result
        result = response['Body'].read().decode('utf-8')
        
        # Return successful response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # For CORS support
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'prediction': result
            })
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        # Return error response
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
