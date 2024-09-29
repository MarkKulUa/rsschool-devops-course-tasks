# provider "aws" {
#   region = "eu-central-1"
# }
#
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "terraform-state-bucket-name-mark-devops"
#
#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = "Dev"
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "block" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   block_public_acls       = false
#   ignore_public_acls      = false
#   block_public_policy     = false
#   restrict_public_buckets = false
# }
#
# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = "*"
#         Action = "s3:GetObject"
#         Resource = "${aws_s3_bucket.terraform_state.arn}/*"
#       }
#     ]
#   })
# }
#
#
# resource "aws_s3_bucket_versioning" "versioning" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
#


provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bucket-name-mark-devops"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Dev"
  }
}

# Включение версионирования для бакета
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Настройка шифрования на стороне сервера
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Блокировка публичного доступа к бакету
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# (Опционально) Если требуется политика бакета, обеспечивающая доступ определённым пользователям или ролям
# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/YOUR_ROLE_NAME"
#         },
#         Action   = "s3:*",
#         Resource = [
#           "${aws_s3_bucket.terraform_state.arn}",
#           "${aws_s3_bucket.terraform_state.arn}/*"
#         ]
#       }
#     ]
#   })
# }
