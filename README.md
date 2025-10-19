# Terraform Infrastructure Description for the DCA Application

This Terraform project is used to deploy a containerized application on the AWS platform. The infrastructure is fully defined as code, allowing for its automatic and repeatable creation. Below is a description of the individual components.

## Architecture Summary

The project creates the following resources in the AWS cloud:
* **Network (VPC)**: A private, isolated network for all resources.
* **Image Repository (ECR)**: A private registry to store the application's Docker image.
* **File Storage (S3 Bucket)**: A place to store files, e.g., `bitcoin_prices.xlsx`.
* **Container Service (ECS Fargate)**: Runs the application in a container without the need to manage servers.
* **Load Balancer (ALB)**: Directs internet traffic to the running application.
* **Permissions (IAM)**: Defines the roles and permissions needed to run the application.

---

## 📄 Configuration File Descriptions

### `vpc.tf` - Network Configuration

This file defines the network foundation for the entire application.
* **`aws_vpc`**: Creates the main, isolated network (Virtual Private Cloud) with the `10.0.0.0/16` address pool.
* **`aws_subnet`**: Creates two public subnets (`10.0.1.0/24` and `10.0.2.0/24`) where resources like the Load Balancer and the application will run.
* **`aws_internet_gateway`**: Acts as a "gate" to the public internet, enabling communication with the outside world.
* **`aws_route_table` & `aws_route_table_association`**: Create a routing table that directs all traffic from the subnets (`0.0.0.0/0`) to the internet gateway, effectively making them public.

### `s3.tf` - Data Storage Bucket

This file is responsible for creating a place to store files.
* **`aws_s3_bucket`**: Creates a unique S3 bucket named `dca-app-prices-xxxx`, where `xxxx` is a randomly generated 4-character string. This ensures the bucket name is globally unique.

### `ecr.tf` - Container Image Repository

This file creates a private repository for storing Docker images.
* **`aws_ecr_repository`**: Creates a repository in the Elastic Container Registry (ECR) service named `dca-app`. The application running in ECS will pull its image from here.

### `iam.tf` - Access Management

This file configures permissions for the ECS service.
* **`aws_iam_role`**: Creates a role named `dca-app-ecs-execution-role` that the ECS service can assume (`sts:AssumeRole`).
* **`aws_iam_role_policy_attachment`**: Attaches the AWS-managed policy `AmazonECSTaskExecutionRolePolicy` to this role. This gives the ECS service permissions to, among other things, pull images from ECR and send logs to CloudWatch.

### `ecs.tf` - Application Logic and Execution

This is the most extensive file, defining how the application is launched, managed, and exposed to the world.
* **Security Groups**:
    * `aws_security_group.alb_sg`: A group for the Application Load Balancer (ALB). It allows inbound HTTP traffic on port 80 from anywhere (`0.0.0.0/0`).
    * `aws_security_group.ecs_sg`: A group for the ECS tasks. It allows inbound traffic on port 8080 exclusively from the Load Balancer, securing the application.
* **Load Balancer (ALB)**:
    * `aws_lb.main`: Creates a public Application Load Balancer.
    * `aws_lb_target_group`: Creates a target group that listens on port 8080 and performs health checks on the application at the `/` path.
    * `aws_lb_listener`: Listens on port 80 (HTTP) and forwards all traffic to the defined target group.
* **ECS Cluster and Service**:
    * `aws_ecs_cluster`: Creates a logical ECS cluster named `dca-app-ecs-cluster`.
    * `aws_ecs_task_definition`: Defines a "blueprint" for the application container. It specifies the image to pull from ECR, the required CPU (`256`) and memory (`512`), and port mappings (the container listens on port 8080).
    * `aws_ecs_service`: Launches and maintains a specified number (`desired_count = 2`) of instances of the defined task. It integrates with the ALB, automatically registering new containers with it.
* **Output**:
    * `output "app_url"`: After the infrastructure is successfully created, Terraform will display the public URL where the application is accessible.
