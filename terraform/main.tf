# 1. Define the Provider (AWS)
provider "aws" {
  region = "eu-west-2" # London
}

# 2. Define the DynamoDB Table
resource "aws_dynamodb_table" "task_table" {
  name         = "Tasks-Terraform"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "taskId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "taskId"
    type = "S"
  }

  # Protect against accidental deletes
  point_in_time_recovery {
    enabled = true
  }

  # Auto-expire completed tasks (optional, remove if not needed)
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Environment = "dev"
    Project     = "task-manager"
  }
}

# 3. Output the Table Name
output "dynamodb_table_name" {
  value = aws_dynamodb_table.task_table.name
}