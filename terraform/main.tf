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

# 1. Create the HTTP API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "task-manager-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"] # Allows your React app to talk to the API
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

# 2. Create a Stage (The "Environment")
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# 3. Create the Integration (Connects API to Lambda)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_tasks.invoke_arn
}

# 4. Create the Route (The "Path")
resource "aws_apigatewayv2_route" "get_tasks_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Permission for API Gateway to call Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_tasks.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# --- NEW OUTPUT: Your API URL ---
output "api_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/tasks"
}