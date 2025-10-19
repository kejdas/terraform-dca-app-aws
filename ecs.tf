# security group for the Application Load Balancer

resource "aws_security_group" "alb_sg" {
    name = "dca-app-alb-sg"
    description = "Allow HTTP inbound trafic for ALB"
    vpc_id = aws_vpc.main.id 

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" # it means all protocols
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "dca-app-alb-sg"
    }
}

resource "aws_security_group" "ecs_sg" {
    name = "dca-app-ecs-sg"
    description = "Allow traffic from ALB to Fargate tasks"
    vpc_id  = aws_vpc.main.id


    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_groups = [aws_security_group.alb_sg.id] # link to the ALB's security group
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" # it means all protocols
        cidr_blocks = ["0.0.0.0/0"] # allow all outbound access
    }

    tags = {
        Name = "dca-app-ecs-sg"
    }
}

resource "aws_lb" "main" {
    name = "dca-app-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = [aws_subnet.public.id, aws_subnet.public_2.id]

    tags = {
    Name = "dca-app-alb"
  }
}

resource "aws_lb_target_group" "main" {
    name = "dca-app-tg"
    port = 8080
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id
    target_type = "ip"

    health_check {
        path = "/"
        matcher = "200"
    }
    tags = {
        Name = "dca-app-tg"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }
    tags = {
        Name = "dca-app-listener"
    }
}

resource "aws_ecs_cluster" "main" {
    name = "dca-app-ecs-cluster"

    tags = {
        Name = "dca-app-ecs-cluster"
    }
}

resource "aws_ecs_task_definition" "main" {
    family = "dca-app-task"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_execution.arn

    container_definitions = jsonencode([
        {
        name      = "dca-app-container"
        image     = "${aws_ecr_repository.dca-app.repository_url}:latest"
        essential = true
        portMappings = [
            {
            containerPort = 8080
            hostPort      = 8080
            }
        ]
        }
    ])
    tags = {
        Name = "dca-app-task-definition"
    }
}

resource "aws_ecs_service" "main" {
    name = "dca-app-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.main.arn
    desired_count = 2
    launch_type = "FARGATE"

    network_configuration {
        subnets = [aws_subnet.public.id, aws_subnet.public_2.id]
        security_groups = [aws_security_group.ecs_sg.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.main.arn
        container_name = "dca-app-container"
        container_port = 8080
    }

    # This helps prevent downtime during deployments
    lifecycle {
        ignore_changes = [task_definition]
    }

    tags = {
        Name = "dca-app-ecs-service"
    }
  
}

# Add this to the end of ecs.tf

output "app_url" {
  description = "The public URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}
