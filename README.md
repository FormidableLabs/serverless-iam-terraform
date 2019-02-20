AWS Serverless Infrastructure
=============================
[![Terraform][tf_img]][tf_site]
[![Travis Status][trav_img]][trav_site]

Get your [serverless][] framework application to AWS, the **right way**.

## Overview

Getting a [serverless][] application all the way to production in AWS **correctly** using **securely** can be quite challenging. In particular, things like:

- Locking down IAM permissions to the minimum needed for different conceptual "roles" (e.g., `admin`, `developer`, `ci`).
- Providing a scheme for different environments/stages (e.g., `development`, `staging`, `production`).

... lack reasonable guidance to practically achieve in real world applications.

This [Terraform][] module provides a production-ready base of AWS permissions / resources to support a `serverless` framework application and help manage development / deployment workflows and maintenance. Specifically, it provides:

- **IAM Groups**: Role-specific groups to attach to AWS users to give humans and CI the minimum level of permissions locked to both a specific `serverless` service and stage/environment.

## Concepts

This module allows practical isolation / compartmentalization of privileges within a single AWS account along the folowing axes:

* **Stage/Environment**: An arbitrary environment to isolate -- this module doesn't restrict selection in any way other than there has to be at least one. In practice, a good set of choices may be something like `sandbox`, `development`, `staging`, `production`.
* **IAM Groups**: This module creates/enforces a scheme wherein:
    * **Admin**: AWS users assigned to the `admin` group can create/update/delete a `serverless` application and do pretty much anything that the `serverless` framework permits out of the box.
    * **Developer, CI**: AWS users assigned to the `developer|ci` groups can update a `serverless` application and do non-mutating things like view logs, perform rollbacks, etc.

In this manner, once an AWS superuser deploys a Terraform stack with this module and assigns IAM groups, the rest of the development / devops teams and CI can build and deploy Serverless applications to appropriate cloud targets with the minimum necessary privileges and isolation across services + environments + IAM roles.

## Modules

This project provides a core base module that is the minimum that must be used. Once the core is in place, then other optional submodules can be added.

- **Core (`/*`)**: Provides supporting IAM policies, roles, and groups so that an engineering team / CI can effectively create and maintain `serverless` Framework applications locked down to specific applications + environments with the minimum permissions needed.
- **X-Ray (`modules/xray`)**: TODO

## Integration

Here's a basic integration of the core `serverless` module:

```hcl
################
# variables.tf #
################
variable "stage" {
  description = "The stage/environment to deploy to. Suggest: `sandbox`, `development`, `staging`, `production`."
  default     = "development"
}

###########
# main.tf #
###########
provider "aws" {
  region  = "us-east-1"
  version = "~> 1.19"
}

# Core `serverless` IAM support.
module "serverless" {
  source = "FormidableLabs/serverless/aws"

  region       = "us-east-1"
  service_name = "sparklepants"
  stage        = "${var.stage}"

  # (Default values)
  # iam_region        = `*`
  # iam_partition     = `*`
  # iam_account_id    = `AWS_CALLER account`
  # tf_service_name   = `tf-SERVICE_NAME`
  # sls_service_name  = `sls-SERVICE_NAME`
}
```

That pairs with a `serverless.yml` configuration:

```yml
# This value needs to either be `sls-` + `service_name` module input *or*
# be specified directly as the module input `sls_service_name`.
service: sls-sparklepants

provider:
  name: aws
  runtime: nodejs8.10
  region: "us-east-1"
  stage: ${opt:stage, "development"}

functions:
  # ...
```

Let's unpack the parameters a bit more (located in [variables.tf](variables.tf)):

- `service_name`: A service name is something that defines the unique application that will match up with the serverless application. E.g., something boring like `simple-reference` or `graphql-server` or exciting like `unicorn` or `sparklepants`.
- `stage`: The current stage that will match up with the `serverless` framework deployment. These are arbitrary, but can be something like `development`/`staging`/`production`.
- `region`: The deployed region of the service. Defaults to the current caller's AWS region.
- `iam_region`: The [AWS partition][] to limit IAM privileges to. Defaults to `*`. The difference with `region` is that `region` has to be one specific region like `us-east-1` to match up with Serverless framework resources, whereas `iam_region` can be a single region or `*` wildcard as it's just an IAM restriction.
- `iam_partition`: The AWS partition to limit IAM privileges to. Defaults to `*`.
- `iam_account_id`: The AWS account ID to limit IAM privileges to. Defaults to the current caller's account ID.
- `tf_service_name`: The service name for Terraform-created resources. It is very useful to distinguish between those created by Terraform / this module and those created by the Serverless framework. By default, `tf-${service_name}` for "Terraform". E.g., `tf-simple-reference` or `tf-sparklepants`.
- `sls_service_name`: The service name for Serverless as defined in `serverlss.yml` in the `service` field. Highly recommended to match our default of `sls-${service_name}` for "Serverless".






- [ ] TODO: Mention `[ref_project]`

## TODO_REST_OF_DOCS

[serverless]: https://serverless.com/
[Terraform]: https://www.terraform.io
[AWS partition]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-partition
[AWS X-Ray]: https://aws.amazon.com/xray/

[tf_img]: https://img.shields.io/badge/terraform-published-blue.svg
[tf_site]: https://registry.terraform.io/modules/FormidableLabs/serverless/aws
[trav_img]: https://api.travis-ci.org/FormidableLabs/inspectpack.svg
[trav_site]: https://travis-ci.org/FormidableLabs/inspectpack
[ref_project]: https://github.com/FormidableLabs/aws-lambda-serverless-reference
