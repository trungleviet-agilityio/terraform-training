# Partial Backend Configuration

## Introduction

This guide walks you through the process of setting up a partial backend configuration for Terraform. Building on the basic S3 backend setup from the previous exercise, you'll learn how to create separate backend configuration files for development and production environments, and specify which backend configuration file Terraform should use. After completing this guide, you'll have a comprehensive understanding of how to manage different backend configurations for various environments in Terraform.

## Desired Outcome

Here is an overview of what the created solution should deploy:

1. Successfully configure the S3 Backend for Terraform.
2. Create a `dev.tfbackend` file to provide the partial backend configuration for the development environment.
3. Create a `prod.tfbackend` file to provide the partial backend configuration for the production environment.
4. Be able to specify which backend configuration file Terraform should use by passing it as a command line argument.

## Step-by-Step Guide

1. Keep working on the files from the folder `07-s3-backend`.
2. Replace the `backend "s3"` block in your Terraform configuration with the following:

    ```
    backend "s3" {
      bucket = "<your-bucket-name>"
      region = "<your-aws-region>"
    }
    ```

    Note that we've removed the specific backend key and will instead be using a key that includes the environment from a `tfbackend` file.

3. Create a file called `dev.tfbackend`. This file will provide the partial backend configuration for the development environment. In the `dev.tfbackend` file, add the following:

    ```
    key = "08-partial-backend-config/dev/state.tfstate"
    ```

    This sets the S3 key to a path under `08-partial-backend-config/dev`.

4. Create a file called `prod.tfbackend`. This file will provide the partial backend configuration for the production environment. In the `prod.tfbackend` file, add the following:

    ```
    key = "08-partial-backend-config/prod/state.tfstate"
    ```

    This sets the S3 key to a path under `08-partial-backend-config/prod`.

5. Pass the backend file to Terraform. You can specify which backend configuration file Terraform should use by passing it as a command line argument. For example, to use the development backend, you would run the following command:

    `terraform init -backend-config=dev.tfbackend`

    Similarly, to use the production backend, you would run:

    `terraform init -backend-config=prod.tfbackend`

    This will ensure that Terraform uses the correct state file depending on whether you're working in the development or production environment.

    Go ahead and give it a try! With these steps, your S3 Backend is configured for Terraform and you have separate backend configuration files for development and production that will store the state in different paths in the S3 bucket.

6. Make sure to destroy the resources after you complete all the steps!
