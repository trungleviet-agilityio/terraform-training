# OIDC Provider Module
# Creates AWS IAM OIDC identity provider for GitHub Actions

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = var.thumbprint_list

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}
