"""
Practice Utility Module
Shared utilities for Lambda functions
"""

from practice_util.dynamodb_client import (
    get_dynamodb_client,
    get_table_name,
    get_user_data_table_name,
    get_events_table_name,
)

__all__ = [
    "get_dynamodb_client",
    "get_table_name",
    "get_user_data_table_name",
    "get_events_table_name",
]
