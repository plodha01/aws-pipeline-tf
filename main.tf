data "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
}
resource "aws_codebuild_project" "example" {
  name         = var.codebuild_project_name
  service_role = aws_iam_role.example.arn
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type         = "LINUX_CONTAINER"
  }
  source {
    type            = "CODECOMMIT"
    location        = data.aws_codecommit_repository.repo.clone_url_http
    git_clone_depth = 1
    buildspec       = <<-EOF
      version: 0.2
      phases:
        build:
          commands:
            - sudo yum update -y
            - sudo yum install -y unzip
            - curl -O https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip
            - unzip terraform_0.15.4_linux_amd64.zip
            - sudo mv terraform /usr/local/bin/
            - terraform version
            - terraform init
            - terraform apply --auto-approve
    EOF
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source_version = "main"
}

resource "aws_codepipeline" "example" {
  name = "terraform-pipeline"

  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.example_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name     = "SourceAction"
      category = "Source"
      owner    = "AWS"
      provider = "CodeCommit"
      version  = "1"
      configuration = {
        RepositoryName = var.repo_name
        BranchName     = "main"
      }

      output_artifacts = ["source_artifact"]
    }
  }

  stage {
    name = "Build"

    action {
      name            = "BuildAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_artifact"]
      configuration = {
        ProjectName = aws_codebuild_project.example.name
      }
    }
  }
}