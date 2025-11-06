"""
API Server Lambda Handler
Simple HTTP API handler (can be upgraded to FastAPI later with Lambda layers)
"""
import json

def lambda_handler(event, context):
    """
    Lambda handler for API Gateway HTTP API events

    @param event: API Gateway event
    @param context: Lambda context object
    @return: API Gateway response
    """
    # TODO:  Parse the request
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path = event.get('requestContext', {}).get('http', {}).get('path', '/')

    # TODO:  Implement simple routing
    if path == '/' or path == '/health':
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Hello from API Server",
                "status": "ok",
                "path": path,
                "method": http_method
            })
        }

    # TODO: Example DynamoDB operations (uncomment when ready)
    # if path == '/users' and http_method == 'GET':
    #     # Example: Read from DynamoDB
    #     # user_id = event.get('queryStringParameters', {}).get('user_id')
    #     # if user_id:
    #     #     response = user_data_table.get_item(Key={'user_id': user_id})
    #     #     return {
    #     #         "statusCode": 200,
    #     #         "headers": {"Content-Type": "application/json"},
    #     #         "body": json.dumps(response.get('Item', {}))
    #     #     }
    #     pass
    #
    # if path == '/users' and http_method == 'POST':
    #     # Example: Write to DynamoDB
    #     # body = json.loads(event.get('body', '{}'))
    #     # user_id = body.get('user_id')
    #     # if user_id:
    #     #     user_data_table.put_item(Item=body)
    #     #     return {
    #     #         "statusCode": 201,
    #     #         "headers": {"Content-Type": "application/json"},
    #     #         "body": json.dumps({"message": "User created", "user_id": user_id})
    #     #     }
    #     pass

    return {
        "statusCode": 404,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "error": "Not Found",
            "path": path
        })
    }
