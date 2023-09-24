module "subnets" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = var.cidr

  networks = flatten([
    for k, v in local.subnets : [
      for az in var.azs : {
        name     = "${k}-${az}"
        new_bits = v
      }
    ]
  ])
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  azs                    = var.azs
  cidr                   = var.cidr
  database_subnets       = [for az in var.azs : module.subnets.network_cidr_blocks["database-${az}"]]
  elasticache_subnets    = [for az in var.azs : module.subnets.network_cidr_blocks["elasticache-${az}"]]
  enable_nat_gateway     = true
  intra_subnets          = [for az in var.azs : module.subnets.network_cidr_blocks["intra-${az}"]]
  name                   = var.name
  one_nat_gateway_per_az = false
  private_subnets        = [for az in var.azs : module.subnets.network_cidr_blocks["private-${az}"]]
  public_subnets         = [for az in var.azs : module.subnets.network_cidr_blocks["public-${az}"]]
  single_nat_gateway     = true

  default_security_group_ingress = [
    {
      self = true
    }
  ]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  tags = {
    Network   = var.name
    Terraform = "terraform-aws-network"
  }
}
