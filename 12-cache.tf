# Cache Policy for Static Content (Aggressive)
resource "aws_cloudfront_cache_policy" "static_optimized" {
  name        = "${var.project_name}-static-cache-policy"
  comment     = "Policy for high-performance static asset caching"
  default_ttl = 86400    # 24 hours
  max_ttl     = 31536000 # 1 year
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
    # Failure C Fix: Disabling these prevents cache fragmentation
  }
}

# Cache Policy for API (Disabled)
resource "aws_cloudfront_cache_policy" "api_disabled" {
  name        = "${var.project_name}-api-no-cache"
  comment     = "Safe default: ensures API calls always hit the origin"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

# Origin Request Policy for API (Forward what the Flask app needs)
resource "aws_cloudfront_origin_request_policy" "api_request" {
  name    = "${var.project_name}-api-origin-policy"
  comment = "Forwards Auth and Query Strings to the ALB"

  cookies_config { cookie_behavior = "all" }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Accept"]
    }
  }
  query_strings_config { query_string_behavior = "all" }
}

# Be A Man Challenge: Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "static_security" {
  name    = "${var.project_name}-static-headers"
  comment = "Enforces secure Cache-Control for static assets"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=31536000, immutable"
    }
  }

  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
  }
}

# ================================================================ #
# Lab 2B Be a man A: Cache Policy
# ================================================================ #

# Grab the AWS Managed Policy for Caching Optimized (Respects Origin Headers)
data "aws_cloudfront_cache_policy" "managed_optimized" {
  name = "Managed-CachingOptimized"
}
