provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "database-backups.kabum.com.br"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}


module "base-infra" {
  source = "./modules/infra"

  cluster_name = "tst-clt"
  repo_name    = "python-api"
}

module "c" {
  source = "./modules/deploy"

  name    = "default-elb"
  vpc_id  = "vpc-6d7d8e14"
  subnets = ["subnet-1df27155","subnet-f0c710dc"]
}

resource "local_file" "env_file" {
    content     = "cluster=${module.base-infra.fargate_name}\necr=${module.base-infra.repo_name}\necs_role=${module.base-infra.ecs_role}\ntarget_arn=${module.deploy.lb_target_arn}"
    filename = "${path.module}/.env"
}
