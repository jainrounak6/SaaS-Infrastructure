# Multi-Tenant SaaS Infrastructure

A modular Terraform and Terragrunt setup for deploying scalable SaaS applications on AWS with flexible customer onboarding and feature flags.

## 🚀 Quick Start

### 1. Create a New Customer
```bash
./scripts/create-customer.sh "your-customer-name" "dev"
```

### 2. Deploy Infrastructure
```bash
cd customers/your-customer-name/dev
terragrunt apply
```

### 3. Access Your Application
After deployment, you'll get CloudFront URLs for your frontend and content storage.

## 📁 Project Structure

```
├── customers/                    # Customer-specific configurations
│   └── your-customer-name/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── modules/                      # Reusable Terraform modules
│   ├── vpc/                      # VPC and networking (flexible options)
│   ├── frontend/                 # S3 + CloudFront for static websites
│   ├── content_storage/          # S3 + CloudFront with signed URLs
│   ├── alb_asg/                  # Unified ALB + ASG with Node.js app
│   ├── monitoring/               # CloudWatch dashboards and alarms
│   ├── rds/                      # Database (TODO: Not yet integrated)
│   ├── bastion/                  # Bastion host (TODO: Not yet integrated)
│   ├── cicd/                     # CI/CD pipeline (TODO: Not yet integrated)
│   ├── secrets/                  # Secrets management (TODO: Not yet integrated)
│   └── backup_replication/       # Backup and replication (TODO: Not yet integrated)
├── scripts/                      # Automation scripts
├── docs/                         # Documentation
└── root.hcl                      # Root Terragrunt configuration
```

## 🎛️ Feature Flags

Control which resources are created by editing the `terragrunt.hcl` file:

```hcl
# Current implemented modules
create_frontend = true           # S3 + CloudFront for static websites
create_content_storage = true    # S3 + CloudFront with signed URLs
create_alb_asg = true           # Unified ALB + ASG with Node.js application
create_monitoring = false       # CloudWatch dashboards and alarms

# VPC Configuration (always created, but with flexible options)
vpc_option = "use_default"      # Options: "use_default", "use_existing", "create_new"

# TODO: Modules not yet integrated in main.tf
# create_rds = false            # Database
# create_bastion = false        # Bastion host
# create_cicd = false           # CI/CD pipeline
# create_secrets = false        # Secrets management
# create_backup_replication = false # Backup and replication
```

## 🏗️ Implemented Modules

### 1. VPC Module
**Status**: ✅ **Implemented**
- **Flexible VPC Options**: Use default VPC, existing VPC, or create new VPC
- **Subnet Management**: Public and private subnets with proper routing
- **Security**: Internet Gateway, NAT Gateway, Route Tables
- **Multi-AZ Support**: Spans multiple availability zones

### 2. Frontend Module
**Status**: ✅ **Implemented**
- **S3 Bucket**: Private bucket for static website hosting
- **CloudFront CDN**: Global content delivery with HTTP/2 and HTTP/3
- **Origin Access Control**: Secure access from CloudFront to S3
- **Custom Error Pages**: SPA-friendly error handling

### 3. Content Storage Module
**Status**: ✅ **Implemented**
- **Dual S3 Buckets**: Public and private content storage
- **CloudFront Signed URLs**: Secure access to private content
- **Key Management**: Automatic CloudFront key generation and management
- **Lifecycle Policies**: Automated content lifecycle management

### 4. ALB + ASG Module (Unified)
**Status**: ✅ **Implemented**
- **Application Load Balancer**: Distributes traffic across instances
- **Auto Scaling Group**: Automatically scales based on demand
- **Node.js Application**: Pre-configured with PM2 and CloudWatch
- **Health Checks**: Comprehensive health monitoring
- **SSH Key Management**: Flexible SSH key options

### 5. Monitoring Module
**Status**: ✅ **Available** (Not yet integrated in main.tf)
- **CloudWatch Dashboards**: Comprehensive monitoring views
- **Custom Alarms**: Proactive alerting
- **Log Aggregation**: Centralized logging
- **Performance Metrics**: Application and infrastructure metrics

## 🚧 Pending Modules (TODO)

### 6. RDS Module
**Status**: 🚧 **TODO** - Module exists but not integrated in main.tf
- **Aurora MySQL**: Managed database service
- **Read Replicas**: For read scaling
- **Automated Backups**: Point-in-time recovery
- **Multi-AZ Deployment**: High availability

### 7. Bastion Module
**Status**: 🚧 **TODO** - Module exists but not integrated in main.tf
- **Secure SSH Access**: Jump host for private instances
- **SSH Key Management**: Flexible key options
- **Security Groups**: Restricted access controls
- **Audit Logging**: SSH session logging

### 8. CI/CD Module
**Status**: 🚧 **TODO** - Module exists but not integrated in main.tf
- **CodePipeline**: Automated deployment pipeline
- **CodeBuild**: Build and test automation
- **CodeDeploy**: Application deployment
- **S3 Artifacts**: Build artifact storage

### 9. Secrets Module
**Status**: 🚧 **TODO** - Module exists but not integrated in main.tf
- **AWS Secrets Manager**: Secure secret storage
- **Automatic Rotation**: Secret rotation policies
- **IAM Integration**: Service-specific access
- **Audit Trail**: Secret access logging

### 10. Backup & Replication Module
**Status**: 🚧 **TODO** - Module exists but not integrated in main.tf
- **Cross-Region Replication**: Disaster recovery
- **Automated Backups**: Scheduled backup policies
- **Point-in-Time Recovery**: Data recovery options
- **Backup Monitoring**: Backup success tracking

## ⚙️ Application Configuration

### Node.js Version Management

Control the Node.js version installed on your application servers using the NodeSource Repository method:

```hcl
# In your terragrunt.hcl file
nodejs_version = "22"  # Options: "22" (default), or specific version like "18", "20"
```

### Application Port Configuration

The Node.js application port is configurable with a default of 3000 (non-privileged port) for security best practices:

```hcl
# In your terragrunt.hcl file
app_port = 3000  # Options: 3000 (default), or any valid port number (1-65535)
```

**How it works:**
- **Application runs on specified port** (default: 3000)
- **Load balancer health checks the same port**
- **All AWS resources automatically sync** (target group, security groups, health checks)

**Benefits:** 
- ✅ **Flexible port configuration** - run on any port you need
- ✅ **Automatic synchronization** - all AWS resources use the same port
- ✅ **Security best practice** - default port 3000 is non-privileged
- ✅ **Standard port 80 access** - external users access via load balancer

### VPC Configuration Options

Flexible VPC configuration to suit different deployment scenarios:

```hcl
# Option 1: Use AWS Default VPC (simplest)
vpc_option = "use_default"

# Option 2: Use existing VPC (provide details)
vpc_option = "use_existing"
existing_vpc_id = "vpc-12345678"
existing_public_subnet_ids = ["subnet-12345678", "subnet-87654321"]
existing_private_subnet_ids = ["subnet-11111111", "subnet-22222222"]

# Option 3: Create new VPC (full control)
vpc_option = "create_new"
new_vpc_cidr = "10.0.0.0/16"
new_vpc_public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
new_vpc_private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
new_vpc_availability_zones = ["us-east-1a", "us-east-1b"]
```

## 🔐 Security Features

### Key Management
- **SSH Keys**: Flexible SSH key management (create new, use existing AWS, use existing local)
- **CloudFront Keys**: Automatic key generation for signed URLs
- **Structured Storage**: Organized key storage in project root

### Network Security
- **Security Groups**: Least privilege access controls
- **Private Subnets**: Database and internal services isolation
- **VPC Options**: Flexible networking configuration

### Data Protection
- **Encryption**: S3 server-side encryption (AES256)
- **Private Buckets**: No public access to sensitive data
- **Signed URLs**: Secure access to private content

## 🏢 Customer Management

Each customer gets their own directory with environment-specific configurations:

```
customers/your-customer-name/
├── dev/terragrunt.hcl      # Development environment
├── staging/terragrunt.hcl  # Staging environment
└── prod/terragrunt.hcl     # Production environment
```

## 📚 Documentation

- [Architecture Overview](docs/ARCHITECTURE.md) - Infrastructure components and patterns
- [Deployment Guide](docs/DEPLOYMENT.md) - How to deploy and manage infrastructure

## 🔧 Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Terragrunt >= 0.50

## 📝 License

This project is licensed under the MIT License.