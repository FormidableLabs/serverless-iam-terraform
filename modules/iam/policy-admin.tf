###############################################################################
# Policy: Admin
# -------------
# An admin has all the privileges of a developer and can additionally:
# - Create/Delete the serverless application/stack
# - View metrics from `sls metrics`
###############################################################################
resource "aws_iam_policy" "admin" {
  name   = "${local.tf_service_name}-${local.stage}-admin"
  path   = "/"
  policy = "${data.aws_iam_policy_document.admin.json}"
}

data "aws_iam_policy_document" "admin" {
  # CloudFormation: Allow serverless to create the service CloudFormation stack.
  statement {
    actions = [
      "cloudformation:ListStacks",
      "cloudformation:PreviewStackUpdate",
    ]

    # Necessary wildcards
    # https://iam.cloudonaut.io/reference/cloudformation
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "cloudformation:CreateStack",
      "cloudformation:CreateUploadBucket",
      "cloudformation:ListChangeSets",
      "cloudformation:ListStackResources",
      "cloudformation:Get*",
      "cloudformation:DeleteStack",
    ]

    resources = [
      "${local.sls_cloudformation_arn}",
    ]
  }

  # S3: Allow serverless to upload the packaged service for deployment.
  statement {
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
    ]

    resources = [
      "${local.sls_deploy_bucket_arn}",
    ]
  }

  # Lambda: Create, update, delete the serverless Lambda.
  statement {
    actions = [
      "lambda:CreateFunction",
      "lambda:GetEventSourceMapping",
      "lambda:ListEventSourceMappings",
      "lambda:ListFunctions",
    ]

    # Necessary wildcards
    # https://iam.cloudonaut.io/reference/lambda
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "lambda:DeleteFunction",
    ]

    resources = [
      "${local.sls_lambda_arn}",
    ]
  }

  # IAM: Allow the built-in serverless framework and our custom Lambda Roles
  # to hook up to the Lambda.
  # - https://github.com/serverless/serverless/issues/1439#issuecomment-363383862
  # - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html
  statement {
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DeleteRolePolicy",
    ]

    resources = [
      # Allow both the built-in serverless + our custom enhanced Lambda
      # execution roles.
      # TODO: LAMBDA EXECUTION ROLE POINTER
      "${local.sls_lambda_role_arn}",
    ]
  }

  # Logs (`sls deploy`, `sls logs`)
  statement {
    actions = [
      "logs:DescribeLogStreams", # TODO: CAN THIS GO BELOW ALONG WITH SPECIFIC ARN? OR THE OTHER ONE?
      "logs:DescribeLogGroups",
    ]

    # https://iam.cloudonaut.io/reference/logs.html
    resources = [
      "${local.aws_all_log_streams_arn}", # TODO: CAN WE GET RID OF THIS?
      "${local.sls_log_stream_arn}",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DeleteLogGroup",
      "logs:PutLogEvents",
    ]

    resources = [
      "${local.sls_log_stream_arn}",
    ]
  }

  # CloudWatch Events
  # https://serverless.com/framework/docs/providers/aws/events/cloudwatch-event/
  statement {
    actions = [
      "events:Put*",
      "events:Remove*",
      "events:Delete*",
    ]

    resources = [
      "${local.sls_events_arn}",
    ]
  }

  # CloudWatch Metrics (Needed for `sls metrics`)
  statement {
    # Required to view graphs in other parts of the CloudWatch console and in dashboard widgets.
    actions = [
      "cloudwatch:GetMetricStatistics",
    ]

    # `This service does not have ARNs, so "*" will be used.`
    # https://iam.cloudonaut.io/reference/cloudwatch/GetMetricStatistics.html
    resources = [
      "*",
    ]
  }
}

# IamPolicyAdmin:
#     Type: AWS::IAM::ManagedPolicy
#     Properties:
#       ManagedPolicyName: !Sub "aws-${ServiceName}-${Stage}-admin"
#       PolicyDocument:
#         Version: "2012-10-17"
#         Statement:
#         # CloudFormation: Create the lambda service (DONE)
#         # S3: Upload the lambda service files. (DONE)
#         # Lambda: Create, update, delete the service. (DONE)
#         # IAM (allow creating and use of IAM roles). (DONE)
#         # Logs (`sls logs`). (DONE)
#         # CloudWatch Events. (DONE)
#         # CloudWatch (Needed for `sls metrics`). (DONE)


#         # TODO: Xray: view traces
#         - Effect: Allow
#           Action:
#           - xray:BatchGetTraces
#           - xray:GetServiceGraph
#           - xray:GetTraceGraph
#           - xray:GetTraceSummaries
#           Resource:
#           # Must be wildcard.
#           # https://docs.aws.amazon.com/IAM/latest/UserGuide/list_awsxray.html
#           # https://docs.aws.amazon.com/xray/latest/devguide/xray-permissions.html#xray-permissions-managedpolicies
#           - "*"


#         # TODO: KMS: Manage keys
#         - Effect: Allow
#           Action:
#           - kms:Create*
#           - kms:Describe*
#           - kms:Enable*
#           - kms:List*
#           - kms:Put*
#           - kms:Update*
#           - kms:Revoke*
#           - kms:Disable*
#           - kms:Get*
#           - kms:Delete*
#           - kms:TagResource
#           - kms:UntagResource
#           - kms:ScheduleKeyDeletion
#           - kms:CancelKeyDeletion
#           Resource:
#           - !GetAtt KmsKey.Arn


#         # TODO: SecretsManager: Manage secrets
#         - Effect: Allow
#           Action:
#           - secretsmanager:DescribeSecret
#           - secretsmanager:List*
#           Resource:
#           # Have to wildcard listing...
#           # TODO: ... but could do conditions + tags to limit
#           # https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_identity-based-policies.html
#           - "*"
#         - Effect: Allow
#           Action:
#           - secretsmanager:CreateSecret
#           - secretsmanager:DeleteSecret
#           Resource:
#           - !Sub "arn:aws:secretsmanager:${AwsRegion}:${AWS::AccountId}:secret:${ServiceName}/${Stage}/*"

