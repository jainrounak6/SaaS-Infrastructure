# TODO - Module Integration

## 🚧 Pending Module Integrations

The following modules exist in the `modules/` directory but are not yet integrated in `main.tf`. They need to be added to complete the full infrastructure stack.

### Priority 1: Core Infrastructure

#### 1. Monitoring Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/monitoring/`
**Dependencies**: None
**Effort**: Low
**Description**: Add CloudWatch dashboards and alarms to main.tf

```hcl
# TODO: Add to main.tf
module "monitoring" {
  count  = var.create_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}
```

#### 2. RDS Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/rds/`
**Dependencies**: VPC module
**Effort**: Medium
**Description**: Add database infrastructure to main.tf

```hcl
# TODO: Add to main.tf
module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
  
  # VPC Configuration
  vpc_id              = module.vpc[0].vpc_id
  private_subnet_ids  = module.vpc[0].private_subnet_ids
}
```

### Priority 2: Security & Access

#### 3. Bastion Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/bastion/`
**Dependencies**: VPC module
**Effort**: Medium
**Description**: Add bastion host for secure SSH access

```hcl
# TODO: Add to main.tf
module "bastion" {
  count  = var.create_bastion ? 1 : 0
  source = "./modules/bastion"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
  
  # VPC Configuration
  vpc_id            = module.vpc[0].vpc_id
  public_subnet_ids = module.vpc[0].public_subnet_ids
}
```

#### 4. Secrets Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/secrets/`
**Dependencies**: None
**Effort**: Low
**Description**: Add secrets management infrastructure

```hcl
# TODO: Add to main.tf
module "secrets" {
  count  = var.create_secrets ? 1 : 0
  source = "./modules/secrets"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}
```

### Priority 3: DevOps & Operations

#### 5. CI/CD Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/cicd/`
**Dependencies**: ALB/ASG module
**Effort**: High
**Description**: Add CI/CD pipeline infrastructure

```hcl
# TODO: Add to main.tf
module "cicd" {
  count  = var.create_cicd ? 1 : 0
  source = "./modules/cicd"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
  
  # ALB Configuration
  alb_target_group_arn = module.alb_asg[0].target_group_arn
}
```

#### 6. Backup & Replication Module
**Status**: 🚧 **TODO** - Integration in main.tf
**Module Path**: `modules/backup_replication/`
**Dependencies**: RDS module, S3 buckets
**Effort**: Medium
**Description**: Add backup and disaster recovery infrastructure

```hcl
# TODO: Add to main.tf
module "backup_replication" {
  count  = var.create_backup_replication ? 1 : 0
  source = "./modules/backup_replication"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
  
  # Dependencies
  rds_instance_id = module.rds[0].instance_id
  s3_bucket_arns  = [
    module.frontend[0].bucket_arn,
    module.content_storage[0].public_bucket_arn,
    module.content_storage[0].private_bucket_arn
  ]
}
```

## 📋 Integration Checklist

### For Each Module Integration:

- [ ] **Add module block to main.tf**
- [ ] **Add feature flag variable to variables.tf**
- [ ] **Add feature flag to root.hcl**
- [ ] **Add feature flag to customer terragrunt.hcl**
- [ ] **Test module integration with terragrunt plan**
- [ ] **Update documentation (README.md, ARCHITECTURE.md)**
- [ ] **Add module outputs to outputs.tf if needed**
- [ ] **Test cross-module dependencies**

### Variables to Add to variables.tf:

```hcl
# TODO: Add these variables to variables.tf
variable "create_monitoring" {
  description = "Whether to create monitoring infrastructure"
  type        = bool
  default     = false
}

variable "create_rds" {
  description = "Whether to create RDS database"
  type        = bool
  default     = false
}

variable "create_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = false
}

variable "create_secrets" {
  description = "Whether to create secrets management"
  type        = bool
  default     = false
}

variable "create_cicd" {
  description = "Whether to create CI/CD pipeline"
  type        = bool
  default     = false
}

variable "create_backup_replication" {
  description = "Whether to create backup and replication"
  type        = bool
  default     = false
}
```

### Feature Flags to Add to root.hcl:

```hcl
# TODO: Add these to root.hcl inputs
create_monitoring = false
create_rds = false
create_bastion = false
create_secrets = false
create_cicd = false
create_backup_replication = false
```

## 🎯 Implementation Order

1. **Monitoring** (Low effort, no dependencies)
2. **RDS** (Medium effort, VPC dependency)
3. **Bastion** (Medium effort, VPC dependency)
4. **Secrets** (Low effort, no dependencies)
5. **Backup & Replication** (Medium effort, RDS dependency)
6. **CI/CD** (High effort, ALB/ASG dependency)

## 📝 Notes

- All modules already exist in the `modules/` directory
- Each module has its own `main.tf`, `variables.tf`, and `outputs.tf`
- Integration involves adding module blocks to root `main.tf`
- Feature flags provide flexibility for different customer requirements
- Cross-module dependencies need to be carefully managed
- Testing should be done incrementally for each module integration
