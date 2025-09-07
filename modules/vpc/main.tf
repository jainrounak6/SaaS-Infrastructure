# =============================================================================
# VPC MODULE - Flexible VPC Management
# =============================================================================
# This module supports three VPC deployment options:
# 1. create_new: Create a brand new VPC with custom subnets
# 2. use_existing: Use a specific existing VPC (provide VPC ID and subnet IDs)
# 3. use_default: Use AWS default VPC (auto-detects default VPC and subnets)

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get default VPC when using default VPC option
data "aws_vpc" "default" {
  count   = var.vpc_option == "use_default" ? 1 : 0
  default = true
}

# Get default VPC subnets when using default VPC option
data "aws_subnets" "default" {
  count = var.vpc_option == "use_default" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# Get default subnet details when using default VPC option
data "aws_subnet" "default" {
  count = var.vpc_option == "use_default" ? length(data.aws_subnets.default[0].ids) : 0
  id    = data.aws_subnets.default[0].ids[count.index]
}

# Get existing VPC when using existing VPC option
data "aws_vpc" "existing" {
  count = var.vpc_option == "use_existing" ? 1 : 0
  id    = var.existing_vpc_id
}

# Get existing subnets when using existing VPC option
data "aws_subnet" "existing_public" {
  count = var.vpc_option == "use_existing" ? length(var.existing_public_subnet_ids) : 0
  id    = var.existing_public_subnet_ids[count.index]
}

data "aws_subnet" "existing_private" {
  count = var.vpc_option == "use_existing" ? length(var.existing_private_subnet_ids) : 0
  id    = var.existing_private_subnet_ids[count.index]
}

# =============================================================================
# NEW VPC RESOURCES (only when vpc_option = "create_new")
# =============================================================================

# Create new VPC
resource "aws_vpc" "main" {
  count                = var.vpc_option == "create_new" ? 1 : 0
  cidr_block           = var.new_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Purpose     = "custom-vpc"
    Module      = "vpc"
  })
}

# Create Internet Gateway for new VPC
resource "aws_internet_gateway" "main" {
  count  = var.vpc_option == "create_new" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-igw"
    Purpose     = "internet-gateway"
    Module      = "vpc"
  })
}

# Create public subnets for new VPC
resource "aws_subnet" "public" {
  count                   = var.vpc_option == "create_new" ? length(var.new_vpc_public_subnet_cidrs) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.new_vpc_public_subnet_cidrs[count.index]
  availability_zone       = var.new_vpc_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Purpose     = "public-subnet"
    Module      = "vpc"
    Type        = "Public"
  })
}

# Create private subnets for new VPC
resource "aws_subnet" "private" {
  count             = var.vpc_option == "create_new" ? length(var.new_vpc_private_subnet_cidrs) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.new_vpc_private_subnet_cidrs[count.index]
  availability_zone = var.new_vpc_availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Purpose     = "private-subnet"
    Module      = "vpc"
    Type        = "Private"
  })
}

# Create Elastic IPs for NAT Gateways (new VPC only)
resource "aws_eip" "nat" {
  count  = var.vpc_option == "create_new" ? length(var.new_vpc_public_subnet_cidrs) : 0
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eip-${count.index + 1}"
    Purpose     = "nat-gateway-eip"
    Module      = "vpc"
  })
}

# Create NAT Gateways (new VPC only)
resource "aws_nat_gateway" "main" {
  count         = var.vpc_option == "create_new" ? length(var.new_vpc_public_subnet_cidrs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
    Purpose     = "nat-gateway"
    Module      = "vpc"
  })

  depends_on = [aws_internet_gateway.main]
}

# Create route table for public subnets (new VPC only)
resource "aws_route_table" "public" {
  count  = var.vpc_option == "create_new" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Purpose     = "public-route-table"
    Module      = "vpc"
  })
}

# Create route tables for private subnets (new VPC only)
resource "aws_route_table" "private" {
  count  = var.vpc_option == "create_new" ? length(var.new_vpc_private_subnet_cidrs) : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Purpose     = "private-route-table"
    Module      = "vpc"
  })
}

# Associate public subnets with public route table (new VPC only)
resource "aws_route_table_association" "public" {
  count          = var.vpc_option == "create_new" ? length(var.new_vpc_public_subnet_cidrs) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Associate private subnets with private route tables (new VPC only)
resource "aws_route_table_association" "private" {
  count          = var.vpc_option == "create_new" ? length(var.new_vpc_private_subnet_cidrs) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# LOCAL VALUES - Unified VPC and Subnet References
# =============================================================================

locals {
  # VPC ID - unified reference regardless of option
  vpc_id = var.vpc_option == "create_new" ? aws_vpc.main[0].id : (
    var.vpc_option == "use_existing" ? data.aws_vpc.existing[0].id : data.aws_vpc.default[0].id
  )

  # Public subnet IDs - unified reference regardless of option
  public_subnet_ids = var.vpc_option == "create_new" ? aws_subnet.public[*].id : (
    var.vpc_option == "use_existing" ? var.existing_public_subnet_ids : data.aws_subnets.default[0].ids
  )

  # Private subnet IDs - unified reference regardless of option
  private_subnet_ids = var.vpc_option == "create_new" ? aws_subnet.private[*].id : (
    var.vpc_option == "use_existing" ? var.existing_private_subnet_ids : []
  )

  # VPC CIDR - unified reference regardless of option
  vpc_cidr = var.vpc_option == "create_new" ? aws_vpc.main[0].cidr_block : (
    var.vpc_option == "use_existing" ? data.aws_vpc.existing[0].cidr_block : data.aws_vpc.default[0].cidr_block
  )

  # Internet Gateway ID - only available for new VPC
  internet_gateway_id = var.vpc_option == "create_new" ? aws_internet_gateway.main[0].id : null

  # NAT Gateway IDs - only available for new VPC
  nat_gateway_ids = var.vpc_option == "create_new" ? aws_nat_gateway.main[*].id : []
}