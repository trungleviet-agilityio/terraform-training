"""
Cron Server Lambda Handler
Scheduled tasks via EventBridge
"""
import json
import time
from practice_util.dynamodb_client import get_dynamodb_client, get_events_table_name

# Initialize DynamoDB client
dynamodb = get_dynamodb_client()


def lambda_handler(event, context):
    """
    Lambda handler for EventBridge scheduled events

    @param event: EventBridge event (typically empty dict for scheduled events)
    @param context: Lambda context object
    @return: Response with status and message
    """
    print(f"Received EventBridge event: {json.dumps(event)}")

    try:
        # Get events table name
        table_name = get_events_table_name()

        # Generate timestamp (use current time)
        current_timestamp = int(time.time())

        # Write scheduled event to DynamoDB events table
        item = {
            'event_type': {'S': 'scheduled_task'},
            'timestamp': {'N': str(current_timestamp)},
            'task_name': {'S': 'daily_cleanup'},
            'source': {'S': 'EventBridge'},
            'request_id': {'S': context.aws_request_id},
            'ttl': {'N': str(current_timestamp + 86400)}  # TTL: 24 hours from now
        }

        # Add event data if present
        if event:
            item['event_data'] = {'S': json.dumps(event)}

        dynamodb.put_item(
            TableName=table_name,
            Item=item
        )

        print(f"Successfully wrote scheduled event to DynamoDB: {current_timestamp}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Cron job executed successfully",
                "timestamp": current_timestamp,
                "request_id": context.aws_request_id
            })
        }
    except Exception as e:
        print(f"Error executing cron job: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "message": "Cron job execution failed",
                "request_id": context.aws_request_id
            })
        }
