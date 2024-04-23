# CODECOMMIT REPOSITORY
resource "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
}

# CODEBUILD
resource "aws_codebuild_project" "repo-project" {
  name         = var.build_project
  service_role = aws_iam_role.codebuild-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.repo.clone_url_http
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}
# S3 BUCKET FOR ARTIFACTORY_STORE
resource "aws_s3_bucket" "bucket-artifact" {
  bucket_prefix = "osfam-project-"
}

resource "aws_s3_bucket_acl" "bucket_artifact_acl" {
  bucket = aws_s3_bucket.bucket-artifact.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.bucket_artifact_ownership]
}

resource "aws_s3_bucket_ownership_controls" "bucket_artifact_ownership" {
  bucket = aws_s3_bucket.bucket-artifact.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# CODEPIPELINE
resource "aws_codepipeline" "pipeline" {
  name     = "oxfampipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.bucket-artifact.bucket
    type     = "S3"
  }
  # SOURCE
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "${var.repo_name}"
        BranchName     = "${var.branch_name}"
      }
    }
  }
  # BUILD
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "${var.build_project}"
      }
    }
  }
  # DEPLOY
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = "oxfamcluster"
        ServiceName = "oxfam-Service"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}