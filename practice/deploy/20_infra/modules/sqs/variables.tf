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
  default     = 345600  # 4 days
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue (default: 30 seconds)"
  type        = number
  default     = 30
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
  default     = 1209600  # 14 days
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
