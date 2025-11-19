"""
API Server Lambda Handler
Simple HTTP API handler (can be upgraded to FastAPI later with Lambda layers)
"""

import json
import time
from practice_util.dynamodb_client import get_dynamodb_client, get_user_data_table_name, get_events_table_name

# Initialize DynamoDB client
dynamodb = get_dynamodb_client()


def lambda_handler(event, context):
    """
    Lambda handler for API Gateway HTTP API events

    @param event: API Gateway event
    @param context: Lambda context object
    @return: API Gateway response
    """
    # Parse the request
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    path = event.get('requestContext', {}).get('http', {}).get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    body = event.get('body', '{}')

    # Health check endpoint
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

    # Users endpoint - GET /users?user_id=<id>
    if path == '/users' and http_method == 'GET':
        try:
            user_id = query_params.get('user_id')
            if not user_id:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "Missing required parameter: user_id"})
                }

            table_name = get_user_data_table_name()
            response = dynamodb.get_item(
                TableName=table_name,
                Key={'user_id': {'S': user_id}}
            )

            if 'Item' in response:
                # Convert DynamoDB item to JSON
                item = {}
                for key, value in response['Item'].items():
                    if 'S' in value:
                        item[key] = value['S']
                    elif 'N' in value:
                        item[key] = value['N']
                    elif 'B' in value:
                        item[key] = value['B']
                    elif 'BOOL' in value:
                        item[key] = value['BOOL']
                    elif 'L' in value:
                        item[key] = [v for v in value['L']]
                    elif 'M' in value:
                        item[key] = {k: v for k, v in value['M'].items()}

                return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps(item)
                }
            else:
                return {
                    "statusCode": 404,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "User not found", "user_id": user_id})
                }
        except Exception as e:
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": str(e)})
            }

    # Users endpoint - POST /users
    if path == '/users' and http_method == 'POST':
        try:
            body_data = json.loads(body)
            user_id = body_data.get('user_id')
            if not user_id:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "Missing required field: user_id"})
                }

            table_name = get_user_data_table_name()
            # Convert JSON to DynamoDB format
            item = {'user_id': {'S': user_id}}
            for key, value in body_data.items():
                if key == 'user_id':
                    continue
                if isinstance(value, str):
                    item[key] = {'S': value}
                elif isinstance(value, (int, float)):
                    item[key] = {'N': str(value)}
                elif isinstance(value, bool):
                    item[key] = {'BOOL': value}
                elif isinstance(value, dict):
                    item[key] = {'M': {k: {'S': str(v)} for k, v in value.items()}}
                elif isinstance(value, list):
                    item[key] = {'L': [{'S': str(v)} for v in value]}

            dynamodb.put_item(
                TableName=table_name,
                Item=item
            )

            return {
                "statusCode": 201,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "User created", "user_id": user_id})
            }
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Invalid JSON in request body"})
            }
        except Exception as e:
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": str(e)})
            }

    # Events endpoint - GET /events?event_type=<type>&timestamp=<ts>
    if path == '/events' and http_method == 'GET':
        try:
            event_type = query_params.get('event_type')
            timestamp = query_params.get('timestamp')

            table_name = get_events_table_name()

            if event_type and timestamp:
                # Query specific event
                response = dynamodb.get_item(
                    TableName=table_name,
                    Key={
                        'event_type': {'S': event_type},
                        'timestamp': {'N': timestamp}
                    }
                )
                if 'Item' in response:
                    item = {}
                    for key, value in response['Item'].items():
                        if 'S' in value:
                            item[key] = value['S']
                        elif 'N' in value:
                            item[key] = value['N']
                        elif 'B' in value:
                            item[key] = value['B']
                        elif 'BOOL' in value:
                            item[key] = value['BOOL']
                        elif 'L' in value:
                            item[key] = [v for v in value['L']]
                        elif 'M' in value:
                            item[key] = {k: v for k, v in value['M'].items()}

                    return {
                        "statusCode": 200,
                        "headers": {"Content-Type": "application/json"},
                        "body": json.dumps(item)
                    }
                else:
                    return {
                        "statusCode": 404,
                        "headers": {"Content-Type": "application/json"},
                        "body": json.dumps({"error": "Event not found"})
                    }
            elif event_type:
                # Query all events of a specific type
                current_timestamp = int(time.time())
                response = dynamodb.query(
                    TableName=table_name,
                    KeyConditionExpression='event_type = :event_type',
                    ExpressionAttributeValues={
                        ':event_type': {'S': event_type}
                    },
                    Limit=100  # Limit results
                )

                items = []
                for item in response.get('Items', []):
                    converted_item = {}
                    for key, value in item.items():
                        if 'S' in value:
                            converted_item[key] = value['S']
                        elif 'N' in value:
                            converted_item[key] = value['N']
                        elif 'B' in value:
                            converted_item[key] = value['B']
                        elif 'BOOL' in value:
                            converted_item[key] = value['BOOL']
                        elif 'L' in value:
                            converted_item[key] = [v for v in value['L']]
                        elif 'M' in value:
                            converted_item[key] = {k: v for k, v in value['M'].items()}
                    items.append(converted_item)

                return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"events": items, "count": len(items)})
                }
            else:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "Missing required parameter: event_type"})
                }
        except Exception as e:
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": str(e)})
            }

    # Events endpoint - POST /events
    if path == '/events' and http_method == 'POST':
        try:
            body_data = json.loads(body)
            event_type = body_data.get('event_type', 'api_event')
            timestamp = body_data.get('timestamp', int(time.time()))

            table_name = get_events_table_name()

            # Convert JSON to DynamoDB format
            item = {
                'event_type': {'S': event_type},
                'timestamp': {'N': str(timestamp)}
            }

            # Add optional fields
            if 'data' in body_data:
                if isinstance(body_data['data'], dict):
                    item['data'] = {'M': {k: {'S': str(v)} for k, v in body_data['data'].items()}}
                else:
                    item['data'] = {'S': json.dumps(body_data['data'])}

            # Set TTL (24 hours from now)
            ttl = int(time.time()) + 86400
            item['ttl'] = {'N': str(ttl)}

            dynamodb.put_item(
                TableName=table_name,
                Item=item
            )

            return {
                "statusCode": 201,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({
                    "message": "Event created",
                    "event_type": event_type,
                    "timestamp": timestamp
                })
            }
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Invalid JSON in request body"})
            }
        except Exception as e:
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": str(e)})
            }

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