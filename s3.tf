resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_s3_bucket" "dca-app-prices" {
    # We combine a prefix with the random string for a unique name
    bucket = "dca-app-prices-${random_string.bucket_suffix.result}"
    
    tags = {
        Name = "dca-app-s3-bucket"
    }
}
