resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
  capacity_providers =["FARGATE"]
}

resource "aws_ecr_repository" "repo" {
  name                 = var.repo_name
   image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "task_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = file("${path.module}/base_role.json")

}
resource "aws_iam_role_policy_attachment" "task_role_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "task_role_attach2" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

output "fargate_name" {
  value = aws_ecs_cluster.cluster.name
}

output "repo_name" {
  value = aws_ecr_repository.repo.repository_url
}

output "ecs_role" {
  value = aws_iam_role.task_role.name
}
