data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${module.network_ireland.vpc_id}"
  service_name = "${data.aws_vpc_endpoint_service.s3.service_name}"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${element(module.network_ireland.private_app_route_tables, count.index)}"
}

data "aws_vpc_endpoint_service" "ssm" {
  service = "ssm"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = "${module.network_ireland.vpc_id}"
  service_name        = "${data.aws_vpc_endpoint_service.ssm.service_name}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.endpoint.id}"]
  subnet_ids          = ["${module.network_ireland.private_app_subnets}"]
  private_dns_enabled = "${local.enable_ssm_endpoint[local.app_env]}"
}

data "aws_vpc_endpoint_service" "ssm_messages" {
  service = "ssmmessages"
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = "${module.network_ireland.vpc_id}"
  service_name        = "${data.aws_vpc_endpoint_service.ssm_messages.service_name}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.endpoint.id}"]
  subnet_ids          = ["${module.network_ireland.private_app_subnets}"]
  private_dns_enabled = "${local.enable_ssm_endpoint[local.app_env]}"
}

data "aws_vpc_endpoint_service" "ec2_messages" {
  service = "ec2messages"
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = "${module.network_ireland.vpc_id}"
  service_name        = "${data.aws_vpc_endpoint_service.ec2_messages.service_name}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.endpoint.id}"]
  subnet_ids          = ["${module.network_ireland.private_app_subnets}"]
  private_dns_enabled = "${local.enable_ssm_endpoint[local.app_env]}"
}

data "aws_vpc_endpoint_service" "cloudwatch_logs" {
  service = "logs"
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = "${module.network_ireland.vpc_id}"
  service_name        = "${data.aws_vpc_endpoint_service.cloudwatch_logs.service_name}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.endpoint.id}"]
  subnet_ids          = ["${module.network_ireland.private_app_subnets}"]
  private_dns_enabled = "${local.enable_ssm_endpoint[local.app_env]}"
}
