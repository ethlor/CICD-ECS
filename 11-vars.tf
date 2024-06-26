variable "repo_name" {
  type    = string
  default = "dev-repo"
}

variable "branch_name" {
  type    = string
  default = "master"
}

variable "build_project" {
  type    = string
  default = "dev-build-repo"
}

variable "uri_repo" {
  type = string
  default = "<account-id>.dkr.ecr.<region>.amazonaws.com/ecr-repo"
  #The URI_REPO value is in a TF_VAR in my PC
}