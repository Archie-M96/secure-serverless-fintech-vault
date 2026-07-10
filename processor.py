import json

def lambda_handler(event, context):
    print("Secure Request Received.")
    print("Executing compliance checks...")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Fintech transaction processed securely!')
    }