resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront for ${var.domain_name}"
  aliases         = [var.domain_name, "app.${var.domain_name}"]
  web_acl_id      = aws_wafv2_web_acl.cloudfront_waf.arn

  # Added: This is often required even for SPAs/Flask apps
  # default_root_object = "index.html"

  #### Stays for Lab 2B
  origin {
    domain_name = aws_lb.main.dns_name # Ensure your ALB resource is named 'main'
    origin_id   = "ALB-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = random_password.origin_header.result
    }
  }

  # A) Default Behavior: Treat everything as a safe-by-default API
  default_cache_behavior {
    target_origin_id       = "ALB-Origin"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    # LAB 2B: Attach API Policies
    cache_policy_id          = aws_cloudfront_cache_policy.api_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_request.id

  }

  # B) Ordered Behavior: Target the /api/public-feed path for performance
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "ALB-Origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    # Use the managed policy that respects UseOriginCacheControlHeaders
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_optimized.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_request.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  #### Stays for Lab 2B
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert_us_east_1.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Helper to pull the managed CORS policy for static assets
data "aws_cloudfront_origin_request_policy" "managed_cors" {
  name = "Managed-CORS-S3Origin"
}
