variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
   region = "us-east-1"
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
}

resource "aws_cloudfront_distribution" "thaicloudguru" {
  
  origin {
    domain_name = "eks-cluster-a.paocloud.in.th"
    origin_id   = "eks-cluster-a.paocloud.in.th"
    custom_origin_config {
        http_port   = "80"
        https_port = "443"
        origin_protocol_policy = "https-only"
        origin_ssl_protocols = ["TLSv1.2"]
        origin_keepalive_timeout = "30"
        origin_read_timeout = "30"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  comment             = "thaicloudguru"

  aliases = ["thaicloudguru.net", "www.thaicloudguru.net","developers.thaicloudguru.net"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "lightsail-prod.paocloud.in.th"

    forwarded_values {
      query_string = true
      headers      = ["Origin","Host","Referer"]
      cookies {
        forward = "all"
      }
    }
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 1800
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method = "sni-only"
    acm_certificate_arn = "arn:aws:acm:us-east-1:xxxxxxx:certificate/xxxxxx"
  }
}