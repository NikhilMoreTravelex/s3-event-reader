
#To be deleted to allow outbound RDP from public resource to paf server, as for management like RDP we will be via SSM.
resource "aws_security_group_rule" "external_access_rdp2_out" {
  type                     = "egress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.server.id}"
  security_group_id        = "${aws_security_group.external_access.id}"
  description              = "ToBeDeleted - Allow outbound RDP to access paf server, temporarily - long term SSM."
}

/*
#To be deleted to allow inbound RDP from public_resources to paf server, as for management like RDP we will be via SSM.
resource "aws_security_group_rule" "server_rdp_in" {
  type                     = "ingress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.external_access.id}"
  security_group_id        = "${aws_security_group.server.id}"
  description              = "ToBeDeleted - Allow RDP IN from public resources to access private resources, temporarily - long term SSM."
}
*/


#to be deleted, and create a sg for alb
resource "aws_security_group" "external_access" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-external-access-"
  vpc_id      = "${module.network_ireland.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-external-access"
    )
  )}"
}

# To be deleted - as for management like RDP we will be via SSM.
resource "aws_security_group_rule" "external_access_rdp_in" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = "${local.inbound_tvx_whiltelist_ips[var.target_infra]}"
  security_group_id = "${aws_security_group.external_access.id}"
  description       = "Allow RDP IN from Travelex network to access public resources like jump-host/ALB, temporarily - long term SSM."
}

# To be deleted - as for management like RDP will be via SSM.
resource "aws_security_group_rule" "external_access_rdp1_in" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.external_access.id}"
  description       = "ToBeDeleted - Allow RDP IN from All CIDR to access public resources like jump-host/ALB, temporarily - long term SSM."
}

resource "aws_security_group_rule" "external_access_https_out" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.server.id}"
  security_group_id        = "${aws_security_group.external_access.id}"
  description              = "Allow 443 OUT from public resources to private server."
}

resource "aws_security_group_rule" "server_https1_in" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.external_access.id}"
  security_group_id        = "${aws_security_group.server.id}"
  description              = "Allow 443 IN from public resources to private server."
}



#to be deleted - to access internet from jump host temporarily.
resource "aws_security_group_rule" "external_access_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.external_access.id}"
  description       = "ToBeDeleted - Allow all outbound to access internet, temporarily."
}


#### Rules above this line will be deleted.

#restrict only TVX external IP address once tested - modify cidr_blocks.
resource "aws_security_group_rule" "external_access_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = "${local.inbound_tvx_whiltelist_ips[var.target_infra]}"
  security_group_id = "${aws_security_group.external_access.id}"
  description       = "Allow HTTP IN from Travelex network to access public resources like jump-host/ALB."
}


resource "aws_security_group" "server" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-server-"
  vpc_id      = "${module.network_ireland.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
    )
  )}"
}



#Needed for rds nlb , so that target group can update ip of rds.
resource "aws_security_group_rule" "rds_nlb_targetgroup_mssql_in" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = ["${local.cidr_block[local.app_env]}"]
  security_group_id = "${module.rts_db_ireland.db_security_group_id}"
  description       = "Allow 1433 from nlb for health check for rds"
}

#decide whether to keep or not
resource "aws_security_group_rule" "allow_external_access_in_sql_database" {
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.external_access.id}"
  security_group_id        = "${module.rts_db_ireland.db_security_group_id}"
  description              = "Allow 1433 IN from Jump host server to database server."
}

#Security group for VPC endpoints
resource "aws_security_group" "endpoint" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-endpoint-"
  vpc_id      = "${module.network_ireland.vpc_id}"

  tags = "${
    merge(
      local.common_tags,
      map(
        "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-endpoint"
      )
    )
  }"
}

# this is required for ssm and s3 endpoint
resource "aws_security_group_rule" "allow_private_server_out_https_all" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.endpoint.id}"
  description       = "Allow HTTPS OUT from private server to all traffic required to access SSM and S3 endpoint service."
}

# this is required for ssm endpoint

resource "aws_security_group_rule" "allow_all_in_https_private_server" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.endpoint.id}"
  description       = "Allow HTTPS IN from all traffic to private server required for SSM endpoint service."
}










resource "aws_security_group_rule" "server_https1_out" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.server.id}"
  description       = "Allow HTTPS OUT from private server to all traffic required to access SSM and S3 endpoint service."
}


#This is required for ssm endpoint
resource "aws_security_group_rule" "server_https2_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.server.id}"
  description       = "Allow HTTPS IN from all traffic to private server required for SSM endpoint service."
}


resource "aws_security_group_rule" "allow_private_server_out_sql_database" {
  type                     = "egress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${module.rts_db_ireland.db_security_group_id}"
  security_group_id        = "${aws_security_group.server.id}"
  description              = "Allow 1433 IN from private server to access database server."
}

resource "aws_security_group_rule" "allow_private_server_in_sql_database" {
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.server.id}"
  security_group_id        = "${module.rts_db_ireland.db_security_group_id}"
  description              = "Allow 1433 IN from private server to database server."
}

