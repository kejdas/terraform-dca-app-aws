# DCA Application - AWS Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-Automated-green)](https://en.wikipedia.org/wiki/Infrastructure_as_code)

A complete Infrastructure as Code solution for deploying a Dollar Cost Averaging (DCA) Bitcoin tracker application on AWS. This project demonstrates production-ready practices for container orchestration, networking, and security on AWS using Terraform.

## 📖 About the Project

This repository contains Terraform configuration files that automatically provision and manage a complete AWS infrastructure for running the DCA application - a tool for tracking Bitcoin investments using the Dollar Cost Averaging strategy. The application reads Bitcoin price data from an Excel file stored in S3 and provides investment insights.

### What is Dollar Cost Averaging (DCA)?

DCA is an investment strategy where you invest a fixed amount of money at regular intervals, regardless of the asset's price. This project's application helps track and analyze Bitcoin investments made using this strategy.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP (Port 80)
                    ┌────────▼─────────┐
                    │  Load Balancer   │
                    │      (ALB)       │
                    └────────┬─────────┘
                             │
            ┌────────────────┴────────────────┐
            │                                 │
     ┌──────▼──────┐                  ┌──────▼──────┐
     │  ECS Task   │                  │  ECS Task   │
     │   (AZ-1a)   │                  │   (AZ-1b)   │
     │  Port 8080  │                  │  Port 8080  │
     └──────┬──────┘                  └──────┬──────┘
            │                                 │
            └────────────────┬────────────────┘
                             │
                    ┌────────▼─────────┐
                    │   ECR Registry   │
                    │  (Docker Image)  │
                    └──────────────────┘
                             
         ┌─────────────────┐          ┌─────────────────┐
         │   S3 Bucket     │          │   IAM Roles     │
         │ bitcoin_prices  │          │  & Policies     │
         │     .xlsx       │          │                 │
         └─────────────────┘          └─────────────────┘
```

### Infrastructure Components

The infrastructure consists of:

- **VPC Network** (10.0.0.0/16) with 2 public subnets across different availability zones
- **Application Load Balancer** - Distributes traffic across container instances
- **ECS Fargate Cluster** - Runs 2 instances of the DCA application container
- **ECR Repository** - Stores the DCA application Docker image
- **S3 Bucket** - Stores Bitcoin price data (`bitcoin_prices.xlsx`)
- **IAM Roles** - Manages permissions for ECS task execution
- **Security Groups** - Controls network access and traffic flow

## 🚀 Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS Account** with administrative access
2. **Terraform** installed (version 1.0 or higher)
   ```bash
   terraform --version
   ```
3. **AWS CLI** configured with your credentials
   ```bash
   aws configure
   ```
4. **Docker** installed (for building and pushing the DCA app image)
5. **DCA Application Docker Image** ready to deploy

## 📦 What Gets Deployed

When you run this Terraform project, the following resources are created:

| Resource Type | Name | Purpose |
|--------------|------|---------|
| VPC | `dca-app-vpc` | Isolated network environment |
| Subnets | `dca-app-public-subnet` (×2) | Network segments in different AZs |
| Internet Gateway | `dca-app-gateway` | Internet connectivity |
| Security Groups | `dca-app-alb-sg`, `dca-app-ecs-sg` | Firewall rules |
| Load Balancer | `dca-app-alb` | Traffic distribution |
| Target Group | `dca-app-tg` | Container routing |
| ECS Cluster | `dca-app-ecs-cluster` | Container orchestration |
| ECS Service | `dca-app-service` | Maintains 2 running tasks |
| Task Definition | `dca-app-task` | Container configuration |
| ECR Repository | `dca-app` | Docker image storage |
| S3 Bucket | `dca-app-prices-xxxx` | Bitcoin price data |
| IAM Role | `dca-app-ecs-execution-role` | ECS permissions |

## 🎯 Deployment Guide

### Step 1: Clone and Initialize

```bash
# Clone the repository
git clone <your-repo-url>
cd <repository-name>

# Initialize Terraform
terraform init
```

### Step 2: Prepare Your DCA Application Image

First, you need to build and push your DCA application Docker image to ECR:

```bash
# Build your DCA application Docker image
docker build -t dca-app:latest .

# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="eu-central-1"

# Create ECR repository (or use Terraform-created one after first apply)
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Tag the image
docker tag dca-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/dca-app:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/dca-app:latest
```

### Step 3: Review Infrastructure Plan

```bash
# Preview what Terraform will create
terraform plan
```

Review the output to ensure all resources are correctly configured.

### Step 4: Deploy Infrastructure

```bash
# Create all AWS resources
terraform apply
```

Type `yes` when prompted.

### Step 5: Upload Bitcoin Price Data

After deployment, upload your Bitcoin price data to the S3 bucket:

```bash
# Get the bucket name (it includes a random suffix)
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Upload your Excel file
aws s3 cp bitcoin_prices.xlsx s3://$BUCKET_NAME/bitcoin_prices.xlsx
```

### Step 6: Access Your Application

```bash
# Get the application URL
terraform output app_url
```

Open the URL in your browser. The DCA application should now be accessible!

Example output:
```
app_url = "http://dca-app-alb-1234567890.eu-central-1.elb.amazonaws.com"
```

## 📁 Project Structure

```
.
├── vpc.tf              # Network infrastructure (VPC, subnets, gateway)
├── s3.tf               # S3 bucket for Bitcoin price data
├── ecr.tf              # Docker image repository
├── iam.tf              # IAM roles and policies
├── ecs.tf              # ECS cluster, tasks, service, and load balancer
└── README.md           # This file
```

## 🔧 Configuration Details

### Network Configuration (`vpc.tf`)

- **VPC CIDR**: 10.0.0.0/16 (65,536 IP addresses)
- **Subnet 1**: 10.0.1.0/24 in `eu-central-1a` (256 IPs)
- **Subnet 2**: 10.0.2.0/24 in `eu-central-1b` (256 IPs)
- **Route**: All traffic (0.0.0.0/0) → Internet Gateway

### Container Configuration (`ecs.tf`)

- **CPU**: 256 units (0.25 vCPU)
- **Memory**: 512 MB
- **Container Port**: 8080
- **Desired Count**: 2 tasks
- **Health Check**: HTTP GET on `/` (expects 200 status)

### Security Configuration

**ALB Security Group**:
- Ingress: Port 80 from 0.0.0.0/0 (internet)
- Egress: All traffic

**ECS Security Group**:
- Ingress: Port 8080 from ALB only
- Egress: All traffic

This setup ensures that:
1. The application is only accessible through the load balancer
2. Direct access to containers is blocked
3. Containers can make outbound requests (e.g., to ECR, CloudWatch)

### Storage Configuration (`s3.tf`)

- **Bucket Name**: `dca-app-prices-{random-4-chars}`
- Random suffix ensures globally unique bucket name
- Stores the `bitcoin_prices.xlsx` file

## 🔄 Updating the Application

To deploy a new version of your DCA application:

```bash
# Build new version
docker build -t dca-app:latest .

# Tag and push to ECR
docker tag dca-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/dca-app:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/dca-app:latest

# Force ECS to deploy new version
aws ecs update-service \
  --cluster dca-app-ecs-cluster \
  --service dca-app-service \
  --force-new-deployment
```

The load balancer will perform rolling updates with zero downtime.

> 💡 **Tip**: Run `terraform destroy` when not using the infrastructure to avoid charges.

## 🧹 Cleanup

To remove all resources and stop charges:

```bash
# Destroy all infrastructure
terraform destroy
```

Type `yes` to confirm. This will delete:
- All ECS tasks and services
- Load balancer and target groups
- ECR repository (including images)
- S3 bucket (must be empty first)
- VPC, subnets, and networking components
- IAM roles and policies

**Important**: Empty the S3 bucket before running destroy:
```bash
aws s3 rm s3://dca-app-prices-xxxx --recursive
```

## 🛠️ Troubleshooting

### Container won't start
- Check ECR for the image: `aws ecr describe-images --repository-name dca-app`
- View ECS task logs in CloudWatch Logs
- Verify IAM role has correct permissions

### Application not accessible
- Ensure security groups allow traffic on port 80 (ALB) and 8080 (ECS)
- Check target group health in AWS Console
- Verify tasks are running: `aws ecs list-tasks --cluster dca-app-ecs-cluster`

### S3 access issues
- Confirm bucket name: `terraform output s3_bucket_name`
- Verify file uploaded: `aws s3 ls s3://dca-app-prices-xxxx/`
- Check ECS task role has S3 read permissions (add if needed)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! This project is designed for learning and showcasing Infrastructure as Code skills.

## 📄 License

This project is open source and available under the MIT License.


---

⭐ **If you found this project helpful, please give it a star!** It helps others discover this resource for learning Terraform and AWS.
