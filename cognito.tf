resource "aws_iam_role" "cidp" {
  name = "terraform-example-cognito-raja"
  path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "12345"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "main" {
  name = "terraform-example-cognito-idp"
  role = "${aws_iam_role.cidp.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:publish"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_cognito_user_pool" "pool" {
  name                       = "terraform-example"
  mfa_configuration          = "ON"
  email_verification_subject = "Device Verification Code"
  email_verification_message = "Please use the following code {####}"
  sms_verification_message   = "{####} Baz"
  alias_attributes           = ["email", "preferred_username"]
  auto_verified_attributes   = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  email_configuration {
    reply_to_email_address = "foo.bar@baz"
  }

  password_policy {
    minimum_length    = 30
    require_lowercase = false
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 15
    }
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = true
    mutable                  = true
    name                     = "mynumber"
    required                 = false

    number_attribute_constraints {
      min_value = 2
      max_value = 6
    }
  }

  sms_configuration {
    external_id    = "12345"
    sns_caller_arn = "${aws_iam_role.cidp.arn}"
  }

  tags {
    "Name"    = "FooBar"
    "Project" = "Terraform"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                = "client"
  user_pool_id        = "${aws_cognito_user_pool.pool.id}"
  generate_secret     = true
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
}
