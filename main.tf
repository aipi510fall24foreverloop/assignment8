# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-app-cluster"
}

# Create an ECR repository
resource "aws_ecr_repository" "my_repo" {
  name = "my-app-repo"
}

# Build and push Docker image to ECR
resource "null_resource" "docker_build_push" {
  provisioner "local-exec" {
    command = <<EOF
      aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.my_repo.repository_url}
      docker build -t ${aws_ecr_repository.my_repo.repository_url}:latest ../step2-containerize
      docker push ${aws_ecr_repository.my_repo.repository_url}:latest
    EOF
  }

  triggers = {
    dockerfile_hash = filemd5("../step2-containerize/Dockerfile")
    app_code_hash   = md5(join("", [for f in fileset(".", "../step1-dev/*.py"): filemd5(f)]))
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "${aws_ecr_repository.my_repo.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

# Create an ECS service
resource "aws_ecs_service" "my_service" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = ["subnet-0ccbdbd3e1ec92c76", "subnet-0a5aba5d4f420640b", "subnet-003b02c1c8a866134", "subnet-01a702534fab082e2", "subnet-08cb1454107382f0e", "subnet-00b0cdd933c5dcdef"] # Replace with your subnet IDs
    assign_public_ip = true
  }
}
