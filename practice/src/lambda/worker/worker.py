"""
Worker Lambda Handler
Processes messages from SQS queue
"""

import json
import time
from practice_util.dynamodb_client import get_dynamodb_client, get_events_table_name

# Initialize DynamoDB client
dynamodb = get_dynamodb_client()


def lambda_handler(event, context):
    """
    Lambda handler for SQS events

    @param event: SQS event containing Records array
    @param context: Lambda context object
    @return: Response with status and processed count
    """
    processed_count = 0
    errors = []

    # Process each SQS message
    for record in event.get('Records', []):
        try:
            # Parse SQS message body
            message_body = json.loads(record['body'])
            print(f"Processing message: {message_body}")

            # Get events table name
            table_name = get_events_table_name()

            # Generate timestamp
            current_timestamp = int(time.time())

            # Extract event_type from message or use default
            event_type = message_body.get('event_type', 'sqs_message')

            # Write event to DynamoDB events table
            item = {
                'event_type': {'S': event_type},
                'timestamp': {'N': str(current_timestamp)},
                'source': {'S': 'SQS'},
                'request_id': {'S': context.aws_request_id},
                'ttl': {'N': str(current_timestamp + 86400)}  # TTL: 24 hours from now
            }

            # Add message data
            if 'data' in message_body:
                if isinstance(message_body['data'], dict):
                    item['data'] = {'M': {k: {'S': str(v)} for k, v in message_body['data'].items()}}
                else:
                    item['data'] = {'S': json.dumps(message_body['data'])}
            else:
                # Store entire message body as data
                item['data'] = {'S': json.dumps(message_body)}

            # Add message attributes if present
            if 'messageAttributes' in record:
                item['message_attributes'] = {'S': json.dumps(record['messageAttributes'])}

            dynamodb.put_item(
                TableName=table_name,
                Item=item
            )

            print(f"Successfully wrote SQS event to DynamoDB: {event_type} at {current_timestamp}")
            processed_count += 1

        except json.JSONDecodeError as e:
            error_msg = f"Error parsing message body: {str(e)}"
            print(error_msg)
            errors.append(error_msg)
            # Re-raise to trigger retry mechanism
            # After max retries, message will go to DLQ
            raise
        except Exception as e:
            error_msg = f"Error processing message: {str(e)}"
            print(error_msg)
            errors.append(error_msg)
            # Re-raise to trigger retry mechanism
            # After max retries, message will go to DLQ
            raise

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": f"Processed {processed_count} messages",
            "processed": processed_count,
            "errors": errors if errors else None
        })
    }