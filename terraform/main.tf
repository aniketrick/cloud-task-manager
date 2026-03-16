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

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Environment = "dev"
    Project     = "task-manager"
  }
}

# --- NEW: LAMBDA & IAM LOGIC ---

# 3. ZIP the code automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../backend/functions/getTasks.mjs"
  output_path = "lambda_function_payload.zip"
}

# 4. Create the IAM Role (The "Identity")
resource "aws_iam_role" "iam_for_lambda" {
  name = "task_manager_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 5. Create the Policy (The "Permission")
resource "aws_iam_role_policy" "lambda_policy" {
  name = "task_manager_lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:Query", "dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.task_table.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 6. Create the Lambda Function
resource "aws_lambda_function" "get_tasks" {
  filename      = "lambda_function_payload.zip"
  function_name = "GetTasksFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "getTasks.handler"
  runtime       = "nodejs20.x"

  # This forces an update if your .mjs code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.task_table.name
    }
  }
}

# --- OUTPUTS ---

output "dynamodb_table_name" {
  value = aws_dynamodb_table.task_table.name
}

output "lambda_function_arn" {
  value = aws_lambda_function.get_tasks.arn
}