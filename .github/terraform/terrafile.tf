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

module "deploy" {
  source = "./modules/deploy"

  name    = "default-elb"
  vpc_id  = "vpc-6d7d8e14"
  subnets = ["subnet-044a0ca1d353d98a5","subnet-180fcd34"]
  public_port = 80
  private_port = 8000
}


resource "local_file" "env_file" {
    content     = "cluster=${module.base-infra.fargate_name}\necr=${module.base-infra.repo_name}\necs_role=${module.base-infra.ecs_role}\napp_role=${module.deploy.app_role}\ntarget_arn=${module.deploy.lb_target_arn}\nsg_task=${module.deploy.sg_private}"
    filename = "${path.module}/.env"
}
