# Deployment Guide

## Quick Start

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
After deployment, you'll get a CloudFront URL that serves your frontend application.

## Customer Structure

```
customers/
├── your-customer-name/
│   ├── dev/
│   │   └── terragrunt.hcl
│   ├── staging/
│   │   └── terragrunt.hcl
│   └── prod/
│       └── terragrunt.hcl
```

## Feature Flags

Edit the `terragrunt.hcl` file to enable/disable features:

```hcl
# Frontend only (default)
create_frontend = true
create_vpc = false
create_alb = false
create_asg = false
create_rds = false

# Full stack
create_frontend = true
create_vpc = true
create_alb = true
create_asg = true
create_rds = true
```

## Environment Configuration

- **dev**: Development environment with minimal resources
- **staging**: Production-like environment for testing
- **prod**: Production environment with high availability

