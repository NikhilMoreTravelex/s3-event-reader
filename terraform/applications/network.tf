# Below module  will create vpc, internet gateway, (3-tier - public, app and db ) subnets, route tables.
# network-3-tier module can create nat gateway as well, but we want to keep nat gateway limited to points. so it is included in network-extended.tf
# As we want to have separate subnet for points, and to map both rts-services and rts-points route tables to s3 endpoint, we would call endpoint module directly from root instead of network.

module "network_ireland" {
  source             = "git::github.com/travelex/it-infra-modules.git//terraform_modules/network_2_tier?ref=v1.1"
  app_env            = "${local.app_env}"
  app_parent         = "${var.app_parent}"
  app_name           = "${var.app_name}"
  app_costcode       = "${local.app_costcode}"
  cidr_block         = "${local.cidr_block[local.app_env]}"
  availability_zones = "${local.selected_azs}"
  subnets_per_az     = "${local.subnet_count_per_az}"
  newbits            = "${local.subnet_new_bits}"
  netnum             = "${local.subnet_netnum_start_index}"
}


module "nat_gateway" {
  # Ireland
  source             = "git::github.com/travelex/it-infra-modules.git//terraform_modules/sub_modules/ngw?ref=v1.1"
  app_env            = "${local.app_env}"
  app_parent         = "${var.app_parent}"
  app_name           = "${var.app_name}"
  vpc_common_tags    = "${module.network_ireland.vpc_common_tags}"
  availability_zones = "${local.selected_azs}"
  subnets_per_az     = "${local.subnet_count_per_az["public"]}"
  type               = "public"
  enable_nat_gateway = "${local.enable_nat_gateway[local.app_env]}"
  single_nat_gateway = "${local.single_nat_gateway[local.app_env]}"

  # Change here to switch AZ.
  public_subnets       = ["${module.network_ireland.public_subnets}"]
  private_route_tables = ["${module.network_ireland.private_app_route_tables}"]
}


/*
######################
######################
# Keep this block commented to create endpoint, if the infrastructure is being deployed first time.
# This is required until v0.12 release is out due to limitation to evaluate count parameter on runtime.
# Once the infra is run first time, this can be left uncommented and the terraform can evaluate count from is state file.
# Long run, this can be included directly inside the network module.

# Even after v0.12 specifically for RTS services, we don't want to create endpoint directly from network module.
# As we want to have separate subnet for points, and to map both rts-services and rts-points route tables to s3 endpoint, we would call endpoint module directly from root instead of network.

# However, network module is dynamic (post v0.12) release, as it creates endpoint only when enable_s3_endpoint, enable_ssm_endpoint are set to true from ROOT locals.

######################
######################
*/

/*
module "endpoint_ireland" {
  source                      = "git::github.com/travelex/it-infra-modules.git//terraform_modules/sub_modules/endpoint?ref=v1.1"
  app_env                     = "${local.app_env}"
  app_parent                  = "${var.app_parent}"
  app_name                    = "${var.app_name}"
  vpc_common_tags             = "${module.network_ireland.vpc_common_tags}"
  vpc_id                      = "${module.network_ireland.vpc_id}"
  type                        = "private"
  subnet_suffix               = "app"
  availability_zones          = "${local.selected_azs}"
  enable_s3_endpoint          = "${local.enable_s3_endpoint[local.app_env]}"
  enable_ssm_endpoint         = "${local.enable_ssm_endpoint[local.app_env]}"
  enable_ssmmessages_endpoint = "${local.enable_ssmmessages_endpoint[local.app_env]}"
  enable_ec2messages_endpoint = "${local.enable_ec2messages_endpoint[local.app_env]}"
  enable_squid_endpoint       = "${local.enable_squid_endpoint[local.app_env]}"
  squid_sg_cidr_block         = "${local.cidr_block[local.app_env]}"
  squid_service_name          = "${local.squid_service_name[var.target_infra]}"

  # This is required for s3 endpoint.
  private_route_tables = [ "${module.network_ireland.private_app_route_tables}"]
}
*/
