"""
DynamoDB Utility Module
Shared utilities for DynamoDB operations across Lambda functions
"""

import os
import boto3
from typing import Optional, Dict, Any


def get_dynamodb_client():
    """
    Returns a boto3 DynamoDB client instance.

    @return: boto3 DynamoDB client
    """
    return boto3.client('dynamodb')


def get_table_name(key: str) -> str:
    """
    Gets DynamoDB table name from environment variable.

    @param key: Table key identifier (e.g., 'user-data', 'events')
    @return: Table name from environment variable
    @raises: ValueError if table name not found in environment
    """
    env_var_map = {
        'user-data': 'USER_DATA_TABLE_NAME',
        'events': 'EVENTS_TABLE_NAME',
    }

    env_var = env_var_map.get(key)
    if not env_var:
        raise ValueError(f"Unknown table key: {key}")

    table_name = os.environ.get(env_var)
    if not table_name:
        raise ValueError(f"Environment variable {env_var} not set")

    return table_name


def get_user_data_table_name() -> str:
    """
    Gets the user data table name from environment variable.

    @return: User data table name
    """
    return get_table_name('user-data')


def get_events_table_name() -> str:
    """
    Gets the events table name from environment variable.

    @return: Events table name
    """
    return get_table_name('events')
