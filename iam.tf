data "aws_iam_policy_document" "datadog_integration_policy" {
  statement {
    sid       = "DatadogIntegration"
    resources = ["*"]
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "autoscaling:Describe*",
      "backup:List*",
      "budgets:ViewBudget",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codedeploy:List*",
      "codedeploy:BatchGet*",
      "directconnect:Describe*",
      "dynamodb:List*",
      "dynamodb:Describe*",
      "ec2:Describe*",
      "ec2:GetTransitGatewayPrefixListReferences",
      "ec2:SearchTransitGatewayRoutes",
      "ecs:Describe*",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticloadbalancing:Describe*",
      "elasticmapreduce:List*",
      "elasticmapreduce:Describe*",
      "es:ListTags",
      "es:ListDomainNames",
      "es:DescribeElasticsearchDomains",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "health:DescribeEvents",
      "health:DescribeEventDetails",
      "health:DescribeAffectedEntities",
      "kinesis:List*",
      "kinesis:Describe*",
      "lambda:GetPolicy",
      "lambda:List*",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "oam:ListSinks",
      "oam:ListAttachedLinks",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:List*",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "s3:GetBucketLogging",
      "s3:GetBucketLocation",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "ses:Get*",
      "sns:List*",
      "sns:Publish",
      "sns:GetSubscriptionAttributes",
      "sqs:ListQueues",
      "states:ListStateMachines",
      "states:DescribeStateMachine",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "wafv2:ListLoggingConfigurations",
      "wafv2:GetLoggingConfiguration",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries",
      "tag:GetResources"
    ]
  }
  statement {
    sid       = "DatadogResourceCollection"
    resources = ["*"]
    effect = "Allow"
    actions = [
      "backup:ListRecoveryPointsByBackupVault",
      "bcm-data-exports:GetExport",
      "bcm-data-exports:ListExports",
      "cassandra:Select",
      "cur:DescribeReportDefinitions",
      "ec2:GetSnapshotBlockPublicAccessState",
      "glacier:GetVaultNotifications",
      "glue:ListRegistries",
      "lightsail:GetInstancePortStates",
      "savingsplans:DescribeSavingsPlanRates",
      "savingsplans:DescribeSavingsPlans",
      "timestream:DescribeEndpoints",
      "waf-regional:ListRuleGroups",
      "waf-regional:ListRules",
      "waf:ListRuleGroups",
      "waf:ListRules",
      "wafv2:GetIPSet",
      "wafv2:GetRegexPatternSet",
      "wafv2:GetRuleGroup"
    ]
  }
}

data "aws_iam_policy_document" "datadog_assume_role" {
  statement {
    sid = "DatadogAssumeRole"
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [ "arn:aws:iam::464622532012:root" ]
    }
    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"
      values = [var.datadog_external_id]
    }
  }
}

resource "aws_iam_policy" "datadog_integration_policy" {
  name = "DatadogIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_integration_policy.json
}

resource "aws_iam_role" "datadog_integration_role" {
  name = "DatadogIntegrationRole"
  assume_role_policy = data.aws_iam_policy_document.datadog_assume_role.json
}

resource "aws_iam_role_policy_attachment" "datadog_integration_role" {
  role = aws_iam_role.datadog_integration_role.name
  policy_arn = aws_iam_policy.datadog_integration_policy.arn
}
