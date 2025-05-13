# inference.py

import os
import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize SageMaker runtime client
runtime = boto3.client('sagemaker-runtime')

def handler(event, context):
    """
    Lambda handler function that receives requests from API Gateway
    and forwards them to SageMaker endpoint.
    """
    logger.info("🔵 Lambda function started")
    logger.info(f"📥 Received event: {json.dumps(event)}")
    
    try:
        # Get the SageMaker endpoint name from environment variable
        endpoint_name = os.environ['SAGEMAKER_ENDPOINT']
        logger.info(f"🎯 Target SageMaker endpoint: {endpoint_name}")
        
        # Parse the incoming request body
        body = json.loads(event.get('body', '{}'))
        features = body.get('features', [])
        logger.info(f"📊 Features received: {features}")
        
        # Convert features to CSV format for SageMaker
        csv_payload = ','.join(map(str, features))
        logger.info(f"📤 Sending to SageMaker: {csv_payload}")
        
        # Invoke SageMaker endpoint
        logger.info("🚀 Invoking SageMaker endpoint...")
        response = runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='text/csv',
            Body=csv_payload
        )
        
        # Parse the prediction result
        result = response['Body'].read().decode('utf-8')
        logger.info(f"📥 Received from SageMaker: {result}")
        
        # Return successful response
        response_body = {
            'features': features,
            'prediction': result
        }
        logger.info(f"📤 Returning response: {json.dumps(response_body)}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(response_body)
        }
        
    except Exception as e:
        logger.error(f"❌ Error occurred: {str(e)}", exc_info=True)
        # Return error response
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
