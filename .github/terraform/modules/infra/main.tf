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
  name = "Ecs-Task-Execution-Role"

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

resource "aws_iam_policy" "policy" {
  name        = "catalog-sync-elastic-execution-policy"
  description = "Db migrate flyway execution policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "secretsmanager:*",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.policy.arn
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
