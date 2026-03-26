# AWS Provider Configuration
provider "aws" {
  region = "eu-west-2" # London
}

# --- DATABASE ---

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

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Project = "task-manager"
  }
}

# --- SECURITY (IAM) ---

# Shared execution role for all Lambda functions
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

# Permissions to allow Lambdas to interact with DynamoDB and CloudWatch Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "task_manager_lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:Query", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
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

# --- LAMBDA FUNCTIONS ---

# GET Logic: Fetches tasks for a specific user
resource "aws_lambda_function" "get_tasks" {
  filename      = "lambda_function_payload.zip"
  function_name = "GetTasksFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "getTasks.handler"
  runtime       = "nodejs20.x"

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.task_table.name }
  }
}

# POST Logic: Adds new tasks to the table
resource "aws_lambda_function" "create_task" {
  filename      = "createTask.zip"
  function_name = "CreateTaskFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "createTask.handler"
  runtime       = "nodejs20.x"

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.task_table.name }
  }
}

# DELETE Logic: Removes tasks based on Partition and Sort keys
resource "aws_lambda_function" "delete_task" {
  filename      = "deleteTask.zip"
  function_name = "DeleteTaskFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "deleteTask.handler"
  runtime       = "nodejs20.x"

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.task_table.name }
  }
}

# --- API GATEWAY (HTTP API) ---

resource "aws_apigatewayv2_api" "http_api" {
  name          = "task-manager-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# API-to-Lambda Integrations
resource "aws_apigatewayv2_integration" "get_int" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_tasks.invoke_arn
}

resource "aws_apigatewayv2_integration" "create_int" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_task.invoke_arn
}

resource "aws_apigatewayv2_integration" "delete_int" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.delete_task.invoke_arn
}

# HTTP Routes
resource "aws_apigatewayv2_route" "get_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.get_int.id}"
}

resource "aws_apigatewayv2_route" "create_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.create_int.id}"
}

resource "aws_apigatewayv2_route" "delete_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.delete_int.id}"
}

# --- INVOKE PERMISSIONS ---

resource "aws_lambda_permission" "api_get" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_tasks.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_post" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_task.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_delete" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_task.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# --- OUTPUTS ---

output "api_url" {
  description = "The endpoint to use in the frontend App.jsx"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/tasks"
}
# --- FRONTEND HOSTING (S3 + CloudFront) ---

# 1. S3 Bucket for Website Files
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "task-manager-frontend-${random_id.id.hex}" # Unique bucket name
}

resource "random_id" "id" {
  byte_length = 4
}

# 2. CloudFront Origin Access Control (Secures the bucket)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Output the live URL
output "frontend_bucket_id" {
  value       = aws_s3_bucket.frontend_bucket.id
  description = "Name of the S3 bucket"
}

output "frontend_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "The live URL"
}

# 4. S3 Bucket Policy
resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}