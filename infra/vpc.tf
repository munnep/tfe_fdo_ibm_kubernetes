########################################################################################################################
# VPC (Virtual Private Cloud), Address Prefix, Public Gateway, Subnet, and Network ACL
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.environment_prefix}-vpc"
  resource_group            = local.resource_group_id
  address_prefix_management = "manual"
  no_sg_acl_rules           = true
  tags                      = var.resource_tags
}

locals {
  zone        = "${var.region}-1"
  subnet_cidr = "10.10.10.0/24"
}

resource "ibm_is_vpc_address_prefix" "address_prefix" {
  name       = "${var.environment_prefix}-vpc-zone-1-1"
  zone       = local.zone
  vpc        = ibm_is_vpc.vpc.id
  cidr       = local.subnet_cidr
  is_default = false
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.environment_prefix}-vpc-public-gateway-zone-1"
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.zone
  resource_group = local.resource_group_id
  tags           = var.resource_tags
}

########################################################################################################################
# Network ACL rules
########################################################################################################################

resource "ibm_is_network_acl" "network_acl" {
  name           = "vpc-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id

  rules {
    name        = "allow-all-inbound"
    action      = "allow"
    direction   = "inbound"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    tcp {
      port_min        = 1
      port_max        = 65535
      source_port_min = 1
      source_port_max = 65535
    }
  }

  rules {
    name        = "allow-all-outbound"
    action      = "allow"
    direction   = "outbound"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    tcp {
      port_min        = 1
      port_max        = 65535
      source_port_min = 1
      source_port_max = 65535
    }
  }

  rules {
    name        = "allow-all-udp-inbound"
    action      = "allow"
    direction   = "inbound"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    udp {
      port_min        = 1
      port_max        = 65535
      source_port_min = 1
      source_port_max = 65535
    }
  }

  rules {
    name        = "allow-all-udp-outbound"
    action      = "allow"
    direction   = "outbound"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    udp {
      port_min        = 1
      port_max        = 65535
      source_port_min = 1
      source_port_max = 65535
    }
  }

  rules {
    name        = "allow-postgres-outbound-to-vpe"
    action      = "allow"
    direction   = "outbound"
    source      = local.subnet_cidr
    destination = local.subnet_cidr
    tcp {
      source_port_min = 1
      source_port_max = 65535
      port_min        = local.postgres_port
      port_max        = local.postgres_port
    }
  }

  rules {
    name        = "allow-postgres-inbound-from-vpe"
    action      = "allow"
    direction   = "inbound"
    source      = local.subnet_cidr
    destination = local.subnet_cidr
    tcp {
      source_port_min = local.postgres_port
      source_port_max = local.postgres_port
      port_min        = 1
      port_max        = 65535
    }
  }

  rules {
    name        = "allow-redis-outbound-to-vpe"
    action      = "allow"
    direction   = "outbound"
    source      = local.subnet_cidr
    destination = local.subnet_cidr
    tcp {
      source_port_min = 1
      source_port_max = 65535
      port_min        = local.redis_port
      port_max        = local.redis_port
    }
  }

  rules {
    name        = "allow-redis-inbound-from-vpe"
    action      = "allow"
    direction   = "inbound"
    source      = local.subnet_cidr
    destination = local.subnet_cidr
    tcp {
      source_port_min = local.redis_port
      source_port_max = local.redis_port
      port_min        = 1
      port_max        = 65535
    }
  }
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.environment_prefix}-vpc-zone-1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = local.zone
  resource_group  = local.resource_group_id
  ipv4_cidr_block = local.subnet_cidr
  network_acl     = ibm_is_network_acl.network_acl.id
  public_gateway  = ibm_is_public_gateway.gateway.id
  tags            = var.resource_tags

  depends_on = [ibm_is_vpc_address_prefix.address_prefix]
}

########################################################################################################################
# Additional Network Resources - Virtual Private Endpoints (VPE) & Security Groups
# 
# Enables private connectivity from IKS cluster pods/workers to IBM Cloud Databases (PostgreSQL and Redis)
########################################################################################################################

########################################################################################################################
# Security Group for VPE Gateways
########################################################################################################################

resource "ibm_is_security_group" "vpe" {
  name           = "${var.environment_prefix}-vpc-vpe-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_security_group_rule" "vpe_postgres_inbound" {
  group     = ibm_is_security_group.vpe.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = local.postgres_port
    port_max = local.postgres_port
  }
}

resource "ibm_is_security_group_rule" "vpe_redis_inbound" {
  group     = ibm_is_security_group.vpe.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = local.redis_port
    port_max = local.redis_port
  }
}

resource "ibm_is_security_group_rule" "vpe_outbound" {
  group     = ibm_is_security_group.vpe.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

########################################################################################################################
# Virtual Private Endpoint (VPE) Gateway - PostgreSQL
########################################################################################################################

resource "ibm_is_virtual_endpoint_gateway" "postgres" {
  name            = "${var.environment_prefix}-postgres-vpe"
  vpc             = ibm_is_vpc.vpc.id
  resource_group  = local.resource_group_id
  security_groups = [ibm_is_security_group.vpe.id]

  target {
    crn           = local.postgres_crn
    resource_type = "provider_cloud_service"
  }

  ips {
    subnet = ibm_is_subnet.subnet.id
    name   = "${var.environment_prefix}-postgres-vpe-ip"
  }

  tags = var.resource_tags
  depends_on = [
    ibm_resource_key.postgres_service_credentials,
    ibm_container_vpc_worker_pool.agent,
  ]
}

########################################################################################################################
# Virtual Private Endpoint (VPE) Gateway - Redis
########################################################################################################################

resource "ibm_is_virtual_endpoint_gateway" "redis" {
  name            = "${var.environment_prefix}-redis-vpe"
  vpc             = ibm_is_vpc.vpc.id
  resource_group  = local.resource_group_id
  security_groups = [ibm_is_security_group.vpe.id]

  target {
    crn           = local.redis_crn
    resource_type = "provider_cloud_service"
  }

  ips {
    subnet = ibm_is_subnet.subnet.id
    name   = "${var.environment_prefix}-redis-vpe-ip"
  }

  tags = var.resource_tags
  depends_on = [
    ibm_resource_key.redis_service_credentials,
    ibm_container_vpc_worker_pool.agent,
  ]
}
