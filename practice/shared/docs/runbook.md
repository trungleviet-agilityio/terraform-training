# Operations Runbook

Minimal operations guidance for developers covering rollback procedures, log inspection, and SQS DLQ handling.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Rollback Workflows](#rollback-workflows)
3. [Log Inspection](#log-inspection)
4. [SQS Dead Letter Queue (DLQ) Handling](#sqs-dead-letter-queue-dlq-handling)
5. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Quick Reference

### Common Terraform Commands by Layer

#### 10_core Layer
```bash
cd practice/deploy/10_core/environments/dev

# Initialize with backend
terraform init -backend-config="bucket=tt-practice-tf-state-dev-<account-id>"

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output
```

#### 20_infra Layer
```bash
cd practice/deploy/20_infra/environments/dev

# Initialize with backend
terraform init -backend-config="bucket=tt-practice-tf-state-dev-<account-id>"

# Plan changes
terraform plan

# Apply changes
terraform apply
```

#### 30_app Layer
```bash
cd practice/deploy/30_app/environments/dev

# Build Lambda packages first
cd ../../../../bin
./cb build

# Initialize with backend
cd ../../deploy/30_app/environments/dev
terraform init -backend-config="bucket=tt-practice-tf-state-dev-<account-id>"

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### GitHub Actions Workflow Triggers

#### CI Workflow (`ci.yml`)
- **Trigger**: Pull requests to any branch
- **Path filters**: `practice/deploy/**`, `.github/workflows/ci.yml`
- **Actions**: Format check, validate, plan
- **Output**: Plan posted as PR comment

#### Apply Workflow (`apply.yml`)
- **Trigger**: 
  - Push to `feat/terraform-practice` branch (auto-deploy)
  - Manual workflow dispatch
- **Path filters**: `practice/deploy/**`, `.github/workflows/apply.yml`
- **Actions**: Apply Terraform changes sequentially (10_core → 20_infra → 30_app)
- **Environments**: dev (auto), stage/prod (manual approval)

### AWS CLI Quick Checks

```bash
# Check Lambda function status
aws lambda get-function --function-name tt-practice-dev-api-server --region ap-southeast-1

# Check SQS queue attributes
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names All

# Check CloudWatch log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/tt-practice-dev" --region ap-southeast-1

# Check Terraform state lock
aws dynamodb scan --table-name tt-practice-tf-locks --region ap-southeast-1
```

### Resource Naming Conventions

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Lambda Function | `{project}-{env}-{name}` | `tt-practice-dev-api-server` |
| SQS Queue | `{project}-{env}-{queue-name}-queue` | `tt-practice-dev-main-queue` |
| SQS DLQ | `{project}-{env}-{queue-name}-dlq` | `tt-practice-dev-main-dlq` |
| CloudWatch Log Group | `/aws/lambda/{function-name}` | `/aws/lambda/tt-practice-dev-api-server` |
| State Bucket | `tt-practice-tf-state-{env}-{account-id}` | `tt-practice-tf-state-dev-057336397237` |
| DynamoDB Lock Table | `tt-practice-tf-locks` | `tt-practice-tf-locks` |

---

## Rollback Workflows

### Terraform Rollback

#### State-Based Rollback (Recommended)

**When to use**: When you need to revert infrastructure changes quickly without modifying code.

**Prerequisites**:
- Access to S3 state bucket
- AWS CLI configured
- Terraform CLI installed

**Procedure**:

1. **Identify the state file version**:
   ```bash
   # List state file versions in S3
   aws s3api list-object-versions \
     --bucket tt-practice-tf-state-dev-<account-id> \
     --prefix core/terraform.tfstate \
     --region ap-southeast-1
   ```

2. **Download previous state version**:
   ```bash
   # Download specific version
   aws s3api get-object \
     --bucket tt-practice-tf-state-dev-<account-id> \
     --key core/terraform.tfstate \
     --version-id <version-id> \
     terraform.tfstate.backup \
     --region ap-southeast-1
   ```

3. **Pull current state**:
   ```bash
   cd practice/deploy/10_core/environments/dev
   terraform state pull > terraform.tfstate.current
   ```

4. **Restore previous state**:
   ```bash
   # Push previous state back
   terraform state push terraform.tfstate.backup
   ```

5. **Verify and apply**:
   ```bash
   # Review what will change
   terraform plan
   
   # Apply to sync infrastructure with state
   terraform apply
   ```

**Important Notes**:
- State rollback should be done in reverse order: **30_app → 20_infra → 10_core**
- Always backup current state before rollback
- Verify state file integrity before pushing
- Test rollback procedure in dev environment first

#### Git-Based Rollback

**When to use**: When you want to revert code changes and re-deploy previous configuration.

**Procedure**:

1. **Identify the commit to revert to**:
   ```bash
   # View commit history
   git log --oneline practice/deploy/
   ```

2. **Revert specific commit**:
   ```bash
   # Revert the problematic commit
   git revert <commit-sha>
   
   # Or checkout previous commit
   git checkout <previous-commit-sha> -- practice/deploy/
   ```

3. **Commit and push**:
   ```bash
   git add practice/deploy/
   git commit -m "Rollback: Revert to previous infrastructure configuration"
   git push origin feat/terraform-practice
   ```

4. **Monitor GitHub Actions**:
   - The apply workflow will automatically trigger
   - Monitor workflow execution in GitHub Actions tab
   - Verify infrastructure changes in AWS Console

#### Layer-Specific Rollback Order

**Critical**: Always rollback in reverse dependency order:

1. **30_app** (Application Layer)
   - Rollback Lambda functions, layers, event source mappings
   - State file: `app/terraform.tfstate`

2. **20_infra** (Platform Services Layer)
   - Rollback API Gateway, SQS, EventBridge, DynamoDB
   - State file: `infra/terraform.tfstate`
   - **Wait**: Ensure 30_app rollback completes first

3. **10_core** (Foundation Layer)
   - Rollback state backend, KMS, DNS, secrets
   - State file: `core/terraform.tfstate`
   - **Wait**: Ensure 20_infra rollback completes first
   - **Warning**: Rolling back 10_core may affect state backend itself

#### State File Locations

| Layer | Environment | S3 Key Path |
|-------|-------------|-------------|
| 10_core | dev | `s3://tt-practice-tf-state-dev-<account-id>/core/terraform.tfstate` |
| 10_core | stage | `s3://tt-practice-tf-state-stage-<account-id>/core/terraform.tfstate` |
| 10_core | prod | `s3://tt-practice-tf-state-prod-<account-id>/core/terraform.tfstate` |
| 20_infra | dev | `s3://tt-practice-tf-state-dev-<account-id>/infra/terraform.tfstate` |
| 20_infra | stage | `s3://tt-practice-tf-state-stage-<account-id>/infra/terraform.tfstate` |
| 20_infra | prod | `s3://tt-practice-tf-state-prod-<account-id>/infra/terraform.tfstate` |
| 30_app | dev | `s3://tt-practice-tf-state-dev-<account-id>/app/terraform.tfstate` |
| 30_app | stage | `s3://tt-practice-tf-state-stage-<account-id>/app/terraform.tfstate` |
| 30_app | prod | `s3://tt-practice-tf-state-prod-<account-id>/app/terraform.tfstate` |

#### State Versioning

S3 state bucket has versioning enabled. Use S3 versioning to restore previous state:

```bash
# List all versions of a state file
aws s3api list-object-versions \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --prefix core/terraform.tfstate \
  --region ap-southeast-1

# Restore specific version
aws s3api restore-object \
  --bucket tt-practice-tf-state-dev-<account-id> \
  --key core/terraform.tfstate \
  --version-id <version-id> \
  --region ap-southeast-1
```

#### Emergency Rollback

**When to use**: Critical production incident requiring immediate rollback.

**Quick Procedure**:

1. **Stop ongoing deployments**:
   - Cancel any running GitHub Actions workflows
   - Check for state locks: `aws dynamodb scan --table-name tt-practice-tf-locks`

2. **Restore previous state** (fastest method):
   ```bash
   # Download last known good state
   aws s3 cp \
     s3://tt-practice-tf-state-prod-<account-id>/app/terraform.tfstate \
     terraform.tfstate.backup \
     --region ap-southeast-1
   
   # Push to restore
   cd practice/deploy/30_app/environments/prod
   terraform state push terraform.tfstate.backup
   terraform apply -auto-approve
   ```

3. **Verify rollback**:
   - Check Lambda function versions
   - Verify API Gateway endpoints
   - Test critical user flows

### GitHub Actions Rollback

#### Revert Commit and Re-Deploy

**Procedure**:

1. **Revert the problematic commit**:
   ```bash
   git revert <commit-sha>
   git push origin feat/terraform-practice
   ```

2. **Monitor workflow**:
   - GitHub Actions will automatically trigger apply workflow
   - Watch workflow execution in Actions tab
   - Verify deployment completes successfully

#### Manual Workflow Dispatch

**When to use**: When you need to deploy a specific commit without modifying current branch.

**Procedure**:

1. **Go to GitHub Actions**:
   - Navigate to repository → Actions tab
   - Select "Terraform Apply" workflow
   - Click "Run workflow"

2. **Configure workflow**:
   - **Branch**: Select branch containing desired commit
   - **Layer**: Select layer to apply (or leave empty for auto-detect)
   - **Environment**: Select target environment (dev/stage/prod)

3. **Execute**:
   - Click "Run workflow"
   - Monitor execution
   - Review logs for any errors

#### Workflow Run History

**Finding previous successful runs**:

1. **GitHub Actions UI**:
   - Go to Actions tab
   - Select workflow (CI or Apply)
   - Filter by status: "Success"
   - Click on run to view details

2. **Get commit SHA from successful run**:
   - Open successful workflow run
   - Check "detect-changes" job output
   - Note the commit SHA

3. **Deploy that commit**:
   ```bash
   git checkout <commit-sha>
   git push origin feat/terraform-practice
   ```

#### Rollback via PR

**Procedure**:

1. **Create rollback branch**:
   ```bash
   git checkout -b rollback/revert-<issue-description>
   git checkout <previous-commit-sha> -- practice/deploy/
   git commit -m "Rollback: Revert to commit <previous-commit-sha>"
   ```

2. **Create PR**:
   - Push branch: `git push origin rollback/revert-<issue-description>`
   - Create PR to `feat/terraform-practice`
   - Review plan output in PR comments
   - Merge PR to trigger apply workflow

---

## Log Inspection

### CloudWatch Logs

#### Log Group Naming

Lambda functions create log groups automatically with the pattern:
```
/aws/lambda/{function-name}
```

**Example log groups**:
- `/aws/lambda/tt-practice-dev-api-server`
- `/aws/lambda/tt-practice-dev-worker`
- `/aws/lambda/tt-practice-dev-cron-server`

#### Viewing Logs via AWS Console

**Step-by-step guide**:

1. **Navigate to CloudWatch**:
   - AWS Console → CloudWatch → Logs → Log groups

2. **Find log group**:
   - Search for `/aws/lambda/tt-practice-dev-{function-name}`
   - Click on log group name

3. **View log streams**:
   - Click on a log stream (timestamp-based)
   - View individual log events

4. **Filter logs**:
   - Use search box to filter by keyword
   - Use time range selector for specific periods

#### AWS CLI Commands

**Real-time log tailing**:
```bash
# Tail logs in real-time
aws logs tail /aws/lambda/tt-practice-dev-api-server \
  --follow \
  --region ap-southeast-1

# Tail with filter pattern
aws logs tail /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "ERROR" \
  --follow \
  --region ap-southeast-1
```

**Search log events**:
```bash
# Filter by error messages
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "ERROR" \
  --region ap-southeast-1

# Filter by time range (last 1 hour)
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region ap-southeast-1
```

**Get historical logs**:
```bash
# Get logs from specific time range
aws logs get-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --log-stream-name <stream-name> \
  --start-time <timestamp> \
  --end-time <timestamp> \
  --region ap-southeast-1

# Get recent logs (last 100 events)
aws logs get-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --log-stream-name <stream-name> \
  --limit 100 \
  --region ap-southeast-1
```

**List log streams**:
```bash
# List all log streams
aws logs describe-log-streams \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --order-by LastEventTime \
  --descending \
  --region ap-southeast-1

# List recent streams (last 10)
aws logs describe-log-streams \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --order-by LastEventTime \
  --descending \
  --max-items 10 \
  --region ap-southeast-1
```

#### Log Retention

- **Default**: 14 days (configurable per function)
- **Configurable values**: 1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731, 1827, 3653 days, or never expire
- **Configuration**: Set in Lambda component via `log_retention_days` variable

**Check retention**:
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/tt-practice-dev" \
  --query 'logGroups[*].[logGroupName,retentionInDays]' \
  --output table \
  --region ap-southeast-1
```

### Log Filtering

#### Filter by Error Messages

```bash
# Filter for ERROR level logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "ERROR" \
  --region ap-southeast-1

# Filter for specific error message
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "ConnectionError" \
  --region ap-southeast-1
```

#### Filter by Request ID

```bash
# Filter by request ID (from API Gateway)
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "request-id-12345" \
  --region ap-southeast-1
```

#### Filter by Time Range

```bash
# Last 30 minutes
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --start-time $(date -u -d '30 minutes ago' +%s)000 \
  --region ap-southeast-1

# Specific time range (ISO 8601)
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --start-time 1704067200000 \
  --end-time 1704070800000 \
  --region ap-southeast-1
```

#### Filter by Log Level

```bash
# ERROR level
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "[level=ERROR]" \
  --region ap-southeast-1

# WARN level
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "[level=WARN]" \
  --region ap-southeast-1

# INFO level
aws logs filter-log-events \
  --log-group-name /aws/lambda/tt-practice-dev-api-server \
  --filter-pattern "[level=INFO]" \
  --region ap-southeast-1
```

---

## SQS Dead Letter Queue (DLQ) Handling

### DLQ Configuration

#### DLQ Naming Convention

**Pattern**: `{project}-{env}-{queue-name}-dlq`

**Examples**:
- `tt-practice-dev-main-dlq` (dev environment)
- `tt-practice-stage-main-dlq` (stage environment)
- `tt-practice-prod-main-dlq` (production environment)

#### DLQ Location

- **Region**: Same region as main queue (default: `ap-southeast-1`)
- **Account**: Same AWS account as main queue

#### Message Retention

- **Default**: 14 days (1,209,600 seconds)
- **Configurable**: Via `dlq_message_retention_seconds` variable in SQS module
- **Maximum**: 14 days (SQS standard queue limit)

#### CloudWatch Alarm

- **Alarm name**: `{dlq-name}-messages-alarm`
- **Metric**: `ApproximateNumberOfMessagesVisible`
- **Threshold**: Default 1 message (configurable)
- **Evaluation period**: 60 seconds (configurable)
- **Evaluation periods**: 1 (configurable)
- **Action**: Optional SNS topic notification

**Check alarm status**:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "tt-practice-dev-main-dlq-messages-alarm" \
  --region ap-southeast-1
```

### DLQ Event Handling

#### Viewing DLQ Messages

**AWS Console**:

1. Navigate to SQS → Queues
2. Find DLQ: `tt-practice-dev-main-dlq`
3. Click "Send and receive messages"
4. Click "Poll for messages"
5. View message details (body, attributes, metadata)

**AWS CLI**:
```bash
# Get DLQ URL
DLQ_URL=$(aws sqs get-queue-url \
  --queue-name tt-practice-dev-main-dlq \
  --region ap-southeast-1 \
  --query 'QueueUrl' \
  --output text)

# Receive messages from DLQ
aws sqs receive-message \
  --queue-url $DLQ_URL \
  --max-number-of-messages 10 \
  --attribute-names All \
  --message-attribute-names All \
  --region ap-southeast-1

# Get approximate number of messages
aws sqs get-queue-attributes \
  --queue-url $DLQ_URL \
  --attribute-names ApproximateNumberOfMessages \
  --region ap-southeast-1
```

#### Message Inspection

**Understanding message attributes**:

- **MessageId**: Unique identifier
- **ReceiptHandle**: Required for deletion
- **Body**: Message content (JSON string)
- **Attributes**: 
  - `ApproximateReceiveCount`: Number of times message was received
  - `SentTimestamp`: When message was sent
  - `ApproximateFirstReceiveTimestamp`: First receive time
  - `MessageDeduplicationId`: Deduplication ID (if FIFO)

**Example message inspection**:
```bash
# Receive and inspect message
MESSAGE=$(aws sqs receive-message \
  --queue-url $DLQ_URL \
  --max-number-of-messages 1 \
  --attribute-names All \
  --region ap-southeast-1)

# Extract message body
echo $MESSAGE | jq -r '.Messages[0].Body'

# Extract receive count
echo $MESSAGE | jq -r '.Messages[0].Attributes.ApproximateReceiveCount'
```

#### Root Cause Analysis

**Common failure reasons**:

1. **Lambda timeout**: Function exceeded timeout limit
   - Check: Lambda function timeout configuration
   - Check: CloudWatch logs for timeout errors
   - Solution: Increase timeout or optimize function

2. **Lambda errors**: Unhandled exceptions in function
   - Check: CloudWatch logs for error stack traces
   - Check: Error messages in log streams
   - Solution: Fix code bugs, add error handling

3. **Memory limit**: Function exceeded memory limit
   - Check: Lambda memory configuration
   - Check: CloudWatch metrics for memory usage
   - Solution: Increase memory allocation

4. **Invalid message format**: Message doesn't match expected schema
   - Check: Message body structure
   - Check: Lambda function input validation
   - Solution: Add message validation, update schema

5. **Dependency failures**: External service unavailable
   - Check: CloudWatch logs for connection errors
   - Check: External service status
   - Solution: Add retry logic, handle service outages

**Investigation steps**:

1. **Check message receive count**:
   ```bash
   # Messages with high receive count indicate persistent failures
   aws sqs receive-message \
     --queue-url $DLQ_URL \
     --attribute-names ApproximateReceiveCount \
     --region ap-southeast-1 | \
     jq '.Messages[] | {ReceiveCount: .Attributes.ApproximateReceiveCount, Body: .Body}'
   ```

2. **Check Lambda logs around message timestamp**:
   ```bash
   # Get message sent timestamp
   SENT_TIME=$(aws sqs receive-message \
     --queue-url $DLQ_URL \
     --attribute-names SentTimestamp \
     --region ap-southeast-1 | \
     jq -r '.Messages[0].Attributes.SentTimestamp')
   
   # Convert to readable format
   date -d @$((SENT_TIME / 1000))
   
   # Check Lambda logs around that time
   aws logs filter-log-events \
     --log-group-name /aws/lambda/tt-practice-dev-worker \
     --start-time $((SENT_TIME - 300000)) \
     --end-time $((SENT_TIME + 300000)) \
     --region ap-southeast-1
   ```

#### Message Reprocessing

**Manual Reprocessing via AWS Console**:

1. Navigate to SQS → Queues → DLQ
2. Click "Send and receive messages"
3. Click "Poll for messages"
4. Select message(s) to reprocess
5. Copy message body
6. Navigate to main queue
7. Click "Send message"
8. Paste message body
9. Click "Send message"
10. Delete message from DLQ

**Reprocessing via AWS CLI**:

```bash
# Get main queue URL
MAIN_QUEUE_URL=$(aws sqs get-queue-url \
  --queue-name tt-practice-dev-main-queue \
  --region ap-southeast-1 \
  --query 'QueueUrl' \
  --output text)

# Receive message from DLQ
MESSAGE=$(aws sqs receive-message \
  --queue-url $DLQ_URL \
  --max-number-of-messages 1 \
  --region ap-southeast-1)

# Extract message body and receipt handle
MESSAGE_BODY=$(echo $MESSAGE | jq -r '.Messages[0].Body')
RECEIPT_HANDLE=$(echo $MESSAGE | jq -r '.Messages[0].ReceiptHandle')

# Send to main queue
aws sqs send-message \
  --queue-url $MAIN_QUEUE_URL \
  --message-body "$MESSAGE_BODY" \
  --region ap-southeast-1

# Delete from DLQ
aws sqs delete-message \
  --queue-url $DLQ_URL \
  --receipt-handle "$RECEIPT_HANDLE" \
  --region ap-southeast-1
```

**Reprocessing via Lambda Function**:

Create a Lambda function to automatically reprocess DLQ messages:

```python
import boto3
import json

sqs = boto3.client('sqs')

def lambda_handler(event, context):
    dlq_url = 'https://sqs.ap-southeast-1.amazonaws.com/<account-id>/tt-practice-dev-main-dlq'
    main_queue_url = 'https://sqs.ap-southeast-1.amazonaws.com/<account-id>/tt-practice-dev-main-queue'
    
    # Receive messages from DLQ
    response = sqs.receive_message(
        QueueUrl=dlq_url,
        MaxNumberOfMessages=10,
        AttributeNames=['All']
    )
    
    messages = response.get('Messages', [])
    reprocessed = 0
    
    for message in messages:
        # Send to main queue
        sqs.send_message(
            QueueUrl=main_queue_url,
            MessageBody=message['Body']
        )
        
        # Delete from DLQ
        sqs.delete_message(
            QueueUrl=dlq_url,
            ReceiptHandle=message['ReceiptHandle']
        )
        
        reprocessed += 1
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Reprocessed {reprocessed} messages')
    }
```

#### Bulk Reprocessing Script

```bash
#!/bin/bash
# reprocess-dlq.sh - Bulk reprocess DLQ messages

DLQ_NAME="tt-practice-dev-main-dlq"
MAIN_QUEUE_NAME="tt-practice-dev-main-queue"
REGION="ap-southeast-1"
MAX_MESSAGES=10

# Get queue URLs
DLQ_URL=$(aws sqs get-queue-url \
  --queue-name $DLQ_NAME \
  --region $REGION \
  --query 'QueueUrl' \
  --output text)

MAIN_QUEUE_URL=$(aws sqs get-queue-url \
  --queue-name $MAIN_QUEUE_NAME \
  --region $REGION \
  --query 'QueueUrl' \
  --output text)

echo "DLQ URL: $DLQ_URL"
echo "Main Queue URL: $MAIN_QUEUE_URL"

# Process messages in batches
while true; do
  # Receive messages
  RESPONSE=$(aws sqs receive-message \
    --queue-url $DLQ_URL \
    --max-number-of-messages $MAX_MESSAGES \
    --region $REGION)
  
  MESSAGES=$(echo $RESPONSE | jq -r '.Messages // []')
  
  if [ "$(echo $MESSAGES | jq 'length')" -eq 0 ]; then
    echo "No more messages to process"
    break
  fi
  
  # Process each message
  echo $MESSAGES | jq -c '.[]' | while read -r message; do
    BODY=$(echo $message | jq -r '.Body')
    RECEIPT_HANDLE=$(echo $message | jq -r '.ReceiptHandle')
    
    # Send to main queue
    aws sqs send-message \
      --queue-url $MAIN_QUEUE_URL \
      --message-body "$BODY" \
      --region $REGION
    
    # Delete from DLQ
    aws sqs delete-message \
      --queue-url $DLQ_URL \
      --receipt-handle "$RECEIPT_HANDLE" \
      --region $REGION
    
    echo "Reprocessed message: $(echo $message | jq -r '.MessageId')"
  done
  
  echo "Processed batch, checking for more messages..."
  sleep 1
done

echo "Bulk reprocessing complete"
```

### Error Retry Strategies

#### Max Receive Count

- **Default**: 3 attempts
- **Configuration**: Set via `max_receive_count` variable in SQS module
- **Behavior**: After 3 failed attempts, message moves to DLQ

**Check current configuration**:
```bash
aws sqs get-queue-attributes \
  --queue-url $MAIN_QUEUE_URL \
  --attribute-names RedrivePolicy \
  --region ap-southeast-1 | \
  jq -r '.Attributes.RedrivePolicy' | \
  jq '.maxReceiveCount'
```

#### Visibility Timeout

- **Default**: 360 seconds (6 minutes)
- **Configuration**: Set via `visibility_timeout_seconds` variable
- **AWS Recommendation**: 6× Lambda function timeout
- **Purpose**: Hides message from other consumers while Lambda processes it

**Important**: If Lambda timeout is 60 seconds, visibility timeout should be at least 360 seconds.

**Check current configuration**:
```bash
aws sqs get-queue-attributes \
  --queue-url $MAIN_QUEUE_URL \
  --attribute-names VisibilityTimeout \
  --region ap-southeast-1 | \
  jq -r '.Attributes.VisibilityTimeout'
```

#### Retry Logic

**Lambda retry behavior**:

1. **Synchronous invocations**: No automatic retries
2. **Asynchronous invocations** (SQS): Automatic retries with exponential backoff
3. **Event source mapping**: SQS handles retries automatically

**SQS retry flow**:

1. Message received by Lambda via event source mapping
2. Lambda processes message
3. If Lambda succeeds: Message deleted from queue
4. If Lambda fails: Message becomes visible again after visibility timeout
5. Message retried up to `max_receive_count` times
6. After max retries: Message moved to DLQ

#### Exponential Backoff

SQS automatically implements exponential backoff:

- **First retry**: Immediate (if visibility timeout expired)
- **Subsequent retries**: Exponential backoff applied by SQS
- **Backoff calculation**: Based on message age and receive count

**Manual retry with backoff** (in Lambda code):

```python
import time
import random

def process_message_with_retry(message, max_retries=3):
    for attempt in range(max_retries):
        try:
            # Process message
            result = process_message(message)
            return result
        except Exception as e:
            if attempt == max_retries - 1:
                raise  # Re-raise on final attempt
            
            # Exponential backoff: 2^attempt seconds + jitter
            backoff = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(backoff)
    
    raise Exception("Max retries exceeded")
```

#### Manual Retry

**Moving messages back to main queue**:

```bash
# Receive message from DLQ
MESSAGE=$(aws sqs receive-message \
  --queue-url $DLQ_URL \
  --max-number-of-messages 1 \
  --region ap-southeast-1)

# Extract message body
MESSAGE_BODY=$(echo $MESSAGE | jq -r '.Messages[0].Body')
RECEIPT_HANDLE=$(echo $MESSAGE | jq -r '.Messages[0].ReceiptHandle')

# Send to main queue (resets receive count)
aws sqs send-message \
  --queue-url $MAIN_QUEUE_URL \
  --message-body "$MESSAGE_BODY" \
  --region ap-southeast-1

# Delete from DLQ
aws sqs delete-message \
  --queue-url $DLQ_URL \
  --receipt-handle "$RECEIPT_HANDLE" \
  --region ap-southeast-1
```

---

## Troubleshooting Common Issues

### Terraform Issues

#### State Lock Conflicts

**Symptoms**: 
```
Error: Error acquiring the state lock
Error: LockID: ...
```

**Causes**:
- Another Terraform operation in progress
- Previous operation crashed without releasing lock
- Concurrent operations on same state

**Solutions**:

1. **Check for active locks**:
   ```bash
   aws dynamodb scan \
     --table-name tt-practice-tf-locks \
     --region ap-southeast-1
   ```

2. **Wait for lock release** (if operation is legitimate):
   ```bash
   # Lock will auto-release after timeout (default: 10 minutes)
   # Or when operation completes
   ```

3. **Force unlock** (emergency only):
   ```bash
   # Get lock ID from error message
   terraform force-unlock <lock-id>
   
   # Or manually delete from DynamoDB
   aws dynamodb delete-item \
     --table-name tt-practice-tf-locks \
     --key '{"LockID": {"S": "<lock-id>"}}' \
     --region ap-southeast-1
   ```

**Prevention**:
- Use `-lock-timeout` flag: `terraform apply -lock-timeout=60s`
- Avoid concurrent operations on same layer/environment
- Use Terraform workspaces for parallel development

#### Backend Connection Errors

**Symptoms**:
```
Error: error configuring S3 Backend: no valid credential sources
Error: Failed to get existing workspaces
```

**Causes**:
- Missing AWS credentials
- Incorrect backend bucket name
- Network connectivity issues
- IAM permissions insufficient

**Solutions**:

1. **Verify AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

2. **Check backend configuration**:
   ```bash
   # Verify bucket exists
   aws s3 ls s3://tt-practice-tf-state-dev-<account-id>/
   
   # Check bucket permissions
   aws s3api get-bucket-policy \
     --bucket tt-practice-tf-state-dev-<account-id>
   ```

3. **Reinitialize backend**:
   ```bash
   terraform init -backend-config="bucket=tt-practice-tf-state-dev-<account-id>" -reconfigure
   ```

#### Permission Errors (IAM)

**Symptoms**:
```
Error: AccessDeniedException: User is not authorized to perform: <action>
```

**Causes**:
- IAM role lacks required permissions
- Policy doesn't include specific resource ARN
- OIDC authentication failed

**Solutions**:

1. **Check IAM role permissions**:
   ```bash
   # For CI/CD: Check terraform-plan or terraform-apply role
   aws iam get-role-policy \
     --role-name tt-practice-dev-terraform-apply \
     --policy-name <policy-name>
   ```

2. **Verify OIDC configuration** (for CI/CD):
   - Check GitHub Actions workflow logs
   - Verify `AWS_ROLE_ARN` secret is correct
   - Check OIDC provider trust policy

3. **Add missing permissions**:
   - Update IAM policy in `20_infra/modules/policies/main.tf`
   - Apply policy changes: `terraform apply` in 20_infra layer
   - Re-run failed workflow

#### State Drift Detection

**Symptoms**:
```
Plan shows unexpected changes even though code hasn't changed
```

**Causes**:
- Resources modified outside Terraform
- Manual changes in AWS Console
- Other automation tools modifying resources

**Solutions**:

1. **Refresh state**:
   ```bash
   terraform refresh
   terraform plan
   ```

2. **Import manually created resources**:
   ```bash
   terraform import aws_lambda_function.example arn:aws:lambda:...
   ```

3. **Prevent drift**:
   - Use Terraform for all infrastructure changes
   - Enable resource tagging for tracking
   - Use AWS Config for compliance monitoring

### Lambda Issues

#### Function Timeout Errors

**Symptoms**:
```
Task timed out after 30.00 seconds
```

**Causes**:
- Function execution time exceeds timeout
- External service slow/unavailable
- Inefficient code logic

**Solutions**:

1. **Increase timeout**:
   ```bash
   # Update timeout in Lambda component
   # In practice/deploy/components/lambda_*/variables.tf
   timeout = 60  # Increase from 30 to 60 seconds
   ```

2. **Optimize function**:
   - Review CloudWatch logs for bottlenecks
   - Optimize database queries
   - Add caching where appropriate
   - Use async processing for long operations

3. **Check SQS visibility timeout**:
   - Ensure visibility timeout >= 6× Lambda timeout
   - Update in SQS module if needed

#### Memory Limit Errors

**Symptoms**:
```
Runtime.ExitError: signal: killed
```

**Causes**:
- Function exceeded allocated memory
- Memory leak in code
- Insufficient memory allocation

**Solutions**:

1. **Check memory usage**:
   ```bash
   # View CloudWatch metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name MemoryUtilization \
     --dimensions Name=FunctionName,Value=tt-practice-dev-api-server \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Maximum \
     --region ap-southeast-1
   ```

2. **Increase memory**:
   ```bash
   # Update in Lambda component
   # In practice/deploy/components/lambda_*/variables.tf
   memory_size = 256  # Increase from 128 to 256 MB
   ```

3. **Fix memory leaks**:
   - Review code for unclosed connections
   - Check for growing data structures
   - Use memory profiling tools

#### Cold Start Issues

**Symptoms**:
- First request after idle period is slow
- Intermittent high latency

**Causes**:
- Lambda container initialization
- Dependency loading
- VPC cold starts (if using VPC)

**Solutions**:

1. **Optimize package size**:
   - Minimize dependencies
   - Use Lambda layers for common dependencies
   - Remove unused code

2. **Use provisioned concurrency** (if needed):
   ```hcl
   # In Lambda component
   provisioned_concurrent_executions = 2
   ```

3. **Optimize imports**:
   - Lazy load heavy dependencies
   - Initialize connections outside handler
   - Use connection pooling

#### Dependency Errors

**Symptoms**:
```
ModuleNotFoundError: No module named 'xxx'
ImportError: cannot import name 'xxx'
```

**Causes**:
- Missing dependencies in Lambda package
- Incorrect layer configuration
- Version mismatch

**Solutions**:

1. **Rebuild Lambda package**:
   ```bash
   cd practice/bin
   ./cb build
   ```

2. **Verify layer configuration**:
   ```bash
   # Check Lambda function layers
   aws lambda get-function \
     --function-name tt-practice-dev-api-server \
     --region ap-southeast-1 | \
     jq -r '.Configuration.Layers'
   ```

3. **Check layer contents**:
   ```bash
   # List layer versions
   aws lambda list-layer-versions \
     --layer-name api_server_dependencies \
     --region ap-southeast-1
   ```

### SQS Issues

#### Message Visibility Timeout

**Symptoms**:
- Messages processed multiple times
- Duplicate processing

**Causes**:
- Visibility timeout too short
- Lambda processing time exceeds visibility timeout

**Solutions**:

1. **Check current timeout**:
   ```bash
   aws sqs get-queue-attributes \
     --queue-url $MAIN_QUEUE_URL \
     --attribute-names VisibilityTimeout \
     --region ap-southeast-1
   ```

2. **Increase visibility timeout**:
   - Update in SQS module: `visibility_timeout_seconds = 600` (10 minutes)
   - Apply changes: `terraform apply` in 20_infra layer

3. **Extend visibility timeout programmatically**:
   ```python
   import boto3
   
   sqs = boto3.client('sqs')
   
   # Extend visibility timeout for long-running tasks
   sqs.change_message_visibility(
       QueueUrl=queue_url,
       ReceiptHandle=receipt_handle,
       VisibilityTimeout=600  # 10 minutes
   )
   ```

#### DLQ Message Accumulation

**Symptoms**:
- DLQ alarm triggered
- Many messages in DLQ
- CloudWatch alarm notifications

**Causes**:
- Systematic failure in Lambda function
- Invalid message format
- External service outage

**Solutions**:

1. **Investigate root cause**:
   - Check CloudWatch logs for errors
   - Inspect DLQ message bodies
   - Review Lambda function code

2. **Fix underlying issue**:
   - Update Lambda function code
   - Fix message format validation
   - Add error handling

3. **Reprocess messages** (after fix):
   - Use bulk reprocessing script
   - Or manual reprocessing via AWS Console

4. **Monitor DLQ**:
   ```bash
   # Set up CloudWatch dashboard
   # Monitor ApproximateNumberOfMessagesVisible metric
   ```

#### Event Source Mapping Errors

**Symptoms**:
- Messages not being processed
- Lambda not triggered by SQS

**Causes**:
- Event source mapping disabled
- Incorrect queue ARN
- Lambda function errors

**Solutions**:

1. **Check event source mapping status**:
   ```bash
   aws lambda list-event-source-mappings \
     --function-name tt-practice-dev-worker \
     --region ap-southeast-1
   ```

2. **Verify mapping configuration**:
   ```bash
   aws lambda get-event-source-mapping \
     --uuid <mapping-uuid> \
     --region ap-southeast-1
   ```

3. **Enable mapping if disabled**:
   ```bash
   aws lambda update-event-source-mapping \
     --uuid <mapping-uuid> \
     --enabled \
     --region ap-southeast-1
   ```

4. **Recreate mapping** (if needed):
   - Update Terraform configuration
   - Apply changes: `terraform apply` in 30_app layer

#### Queue Policy Issues

**Symptoms**:
```
AccessDeniedException: Access to the resource <queue-arn> is denied
```

**Causes**:
- Queue policy too restrictive
- IAM role lacks SQS permissions
- Source account mismatch

**Solutions**:

1. **Check queue policy**:
   ```bash
   aws sqs get-queue-attributes \
     --queue-url $MAIN_QUEUE_URL \
     --attribute-names Policy \
     --region ap-southeast-1 | \
     jq -r '.Attributes.Policy' | \
     jq '.'
   ```

2. **Verify IAM permissions**:
   ```bash
   # Check Lambda execution role
   aws iam get-role-policy \
     --role-name tt-practice-dev-lambda-worker-role \
     --policy-name <policy-name>
   ```

3. **Update queue policy** (if needed):
   - Modify in SQS module: `practice/deploy/20_infra/modules/sqs/main.tf`
   - Apply changes: `terraform apply` in 20_infra layer

---

## Additional Resources

- **Architecture Documentation**: `shared/docs/architecture.md`
- **CI/CD Documentation**: `shared/docs/ci-cd.md`
- **Remote State Documentation**: `shared/docs/remote-state.md`
- **AWS SQS Developer Guide**: https://docs.aws.amazon.com/sqs/
- **AWS Lambda Developer Guide**: https://docs.aws.amazon.com/lambda/
- **CloudWatch Logs User Guide**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/

---

## Emergency Contacts

For critical production issues:
1. Check CloudWatch alarms
2. Review recent deployments in GitHub Actions
3. Check DLQ for failed messages
4. Review CloudWatch logs for errors
5. Escalate to infrastructure team if needed

---

*Last Updated: 2025-11-13*
