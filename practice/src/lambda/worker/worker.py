"""
Worker Lambda Handler
Processes messages from SQS queue
"""
import json

def lambda_handler(event, context):
    """
    Lambda handler for SQS events

    @param event: SQS event containing Records array
    @param context: Lambda context object
    @return: Response with status and processed count
    """
    processed_count = 0

    # Process each SQS message
    for record in event.get('Records', []):
        try:
            # Parse SQS message body
            message_body = json.loads(record['body'])
            print(f"Processing message: {message_body}")

            # TODO:  Implement message processing logic here
            # Example: Process data, update database, etc.

            # TODO: Example DynamoDB write operation (uncomment when ready)
            # # Write event to DynamoDB time-series table
            # # events_table.put_item(
            # #     Item={
            # #         'event_type': message_body.get('event_type', 'unknown'),
            # #         'timestamp': int(context.aws_request_id[-10:]),  # Use request ID as timestamp
            # #         'data': message_body,
            # #         'ttl': int(time.time()) + 86400  # TTL: 24 hours from now
            # #     }
            # # )

            processed_count += 1

        except Exception as e:
            print(f"Error processing message: {str(e)}")
            # TODO:  Re-raise to trigger retry mechanism
            # TODO:  After max retries, message will go to DLQ
            raise

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": f"Processed {processed_count} messages",
            "processed": processed_count
        })
    }
