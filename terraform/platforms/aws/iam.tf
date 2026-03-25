locals {
  oidc_provider_host = replace(module.eks.oidc_provider, "https://", "")
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:monitoring:loki"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count              = var.create_backup_bucket ? 1 : 0
  name               = "${var.cluster_name}-loki"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = local.tags
}

resource "aws_iam_user" "cnpg_backup" {
  count = var.create_backup_bucket ? 1 : 0
  name  = "${var.cluster_name}-cnpg-backup"
  path  = "/starter-kit/"

  tags = local.tags
}

resource "aws_iam_access_key" "cnpg_backup" {
  count = var.create_backup_bucket ? 1 : 0
  user  = aws_iam_user.cnpg_backup[0].name
}

data "aws_iam_policy_document" "cnpg_storage" {
  count = var.create_backup_bucket ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.backups[0].arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.backups[0].arn}/postgres/*"]
  }
}

data "aws_iam_policy_document" "monitoring_storage" {
  count = var.create_backup_bucket ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.backups[0].arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.backups[0].arn}/loki/*",
      "${aws_s3_bucket.backups[0].arn}/ruler/*",
      "${aws_s3_bucket.backups[0].arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "cnpg_storage" {
  count  = var.create_backup_bucket ? 1 : 0
  name   = "${var.cluster_name}-cnpg-storage"
  policy = data.aws_iam_policy_document.cnpg_storage[0].json
  tags   = local.tags
}

resource "aws_iam_policy" "monitoring_storage" {
  count  = var.create_backup_bucket ? 1 : 0
  name   = "${var.cluster_name}-loki-storage"
  policy = data.aws_iam_policy_document.monitoring_storage[0].json
  tags   = local.tags
}

resource "aws_iam_user_policy_attachment" "cnpg_storage" {
  count      = var.create_backup_bucket ? 1 : 0
  user       = aws_iam_user.cnpg_backup[0].name
  policy_arn = aws_iam_policy.cnpg_storage[0].arn
}

resource "aws_iam_role_policy_attachment" "monitoring_storage" {
  count      = var.create_backup_bucket ? 1 : 0
  role       = aws_iam_role.monitoring[0].name
  policy_arn = aws_iam_policy.monitoring_storage[0].arn
}
