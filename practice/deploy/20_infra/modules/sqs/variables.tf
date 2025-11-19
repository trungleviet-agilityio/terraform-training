variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "queue_name" {
  description = "Name of the main SQS queue (without prefix)"
  type        = string
  default     = "main"
}

variable "enable_dlq" {
  description = "Whether to create a Dead Letter Queue"
  type        = bool
  default     = true
}

variable "message_retention_seconds" {
  description = "The number of seconds to retain messages in the queue (default: 4 days)"
  type        = number
  default     = 345600 # 4 days
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue (default: 360 seconds - AWS recommends 6x Lambda timeout for event source mapping)"
  type        = number
  default     = 360 # 6 minutes - recommended for Lambda functions with up to 60s timeout
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (0-20, default: 0 for short polling)"
  type        = number
  default     = 0
}

variable "max_receive_count" {
  description = "The number of times a message can be received before being moved to DLQ (default: 3)"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds to retain messages in the DLQ (default: 14 days)"
  type        = number
  default     = 1209600 # 14 days
}

variable "enable_dlq_alarm" {
  description = "Whether to create a CloudWatch alarm for DLQ messages"
  type        = bool
  default     = true
}

variable "dlq_alarm_threshold" {
  description = "Number of messages in DLQ that triggers the alarm"
  type        = number
  default     = 1
}

variable "dlq_alarm_period" {
  description = "Period in seconds for the DLQ alarm evaluation"
  type        = number
  default     = 60
}

variable "dlq_alarm_evaluation_periods" {
  description = "Number of periods over which data is compared to the threshold"
  type        = number
  default     = 1
}

variable "dlq_alarm_sns_topic_arn" {
  description = "ARN of SNS topic to notify when DLQ alarm triggers (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
