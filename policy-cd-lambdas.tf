###############################################################################
# Policy: Create/Delete Lambdas
###############################################################################
resource "aws_iam_policy" "cd_lambdas" {
  name   = "${local.tf_service_name}-${local.stage}-cd-lambdas"
  path   = "/"
  policy = "${data.aws_iam_policy_document.cd_lambdas.json}"
}

data "aws_iam_policy_document" "cd_lambdas" {
  # Lambda: Create, delete the serverless Lambda.
  statement {
    actions = [
      "lambda:CreateFunction",
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
}
