resource "aws_iam_role" "ecs_execution" {
    name = "dca-app-ecs-execution-role"

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

    tags = {
        Name = "dca-app-ecs-execution-role"
    }
  
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    role       = aws_iam_role.ecs_execution.name
}
