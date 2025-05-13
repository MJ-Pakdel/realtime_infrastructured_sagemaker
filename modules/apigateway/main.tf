# modules/apigateway/main.tf

############################################
# HTTP API → Lambda real-time inference
############################################

# Data source for the current region
data "aws_region" "current" {}

# ------------ HTTP API ------------
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.name_prefix}-api"
  protocol_type = "HTTP"
  tags = merge(
    { Name = "${var.name_prefix}-api" },
    var.tags
  )
}

# ------------ CloudWatch Log Group ------------
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.name_prefix}-api"
  retention_in_days = 3
  tags = merge(
    { Name = "${var.name_prefix}-api-logs" },
    var.tags
  )
}

# ------------ IAM role so API Gateway can push logs ------------
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-api-gw-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-api-gw-logs-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

# ------------ Lambda integration (invoke-path URI) ------------
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

  # 🔑 Use the invoke-path form here
  integration_uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"

  payload_format_version = "2.0"
  connection_type        = "INTERNET"
}

# ------------ Routes ------------
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ------------ Stage ($default, auto-deploy) ------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  # Add throttling configuration for better performance
  default_route_settings {
    throttling_rate_limit  = 10000  # Requests per second
    throttling_burst_limit = 5000   # Maximum concurrent requests
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId         = "$context.requestId",
      httpMethod        = "$context.httpMethod",
      resourcePath      = "$context.resourcePath",
      status            = "$context.status",
      integrationStatus = "$context.integrationStatus",
      integrationError  = "$context.integrationErrorMessage",
      requestTime       = "$context.requestTime",
      responseLatency   = "$context.responseLatency"
    })
  }

  tags = merge(
    { Name = "${var.name_prefix}-api-stage" },
    var.tags
  )
}

# ------------ Allow API Gateway to invoke Lambda ------------
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
