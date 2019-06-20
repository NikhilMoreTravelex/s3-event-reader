module "alb_irland" {
  source                     = "git::github.com/travelex/it-infra-modules.git//terraform_modules/alb?ref=v1.2"
  region                     = "emea"
  app_env                    = "${local.app_env}"
  app_parent                 = "${var.app_parent}"
  app_name                   = "${var.app_name}"
  common_tags                = "${module.network_ireland.vpc_common_tags}"
  alb_security_group_id      = "${aws_security_group.external_access.id}"
  alb_subnet_ids             = ["${module.network_ireland.public_subnets}"]
  enable_deletion_protection = false
  app_paths                  = "${local.app_paths}"
  service                    = "${local.service}"
  web_cert_arn               = "${module.web_cert_ireland.cert_arn}"
  vpc_id                     = "${module.network_ireland.vpc_id}"
}

resource "aws_lb_listener_rule" "appstream" {
  listener_arn = "${module.alb_irland.alb_listener}"
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "${file("${path.module}/templates/appstream.html")}"
      status_code  = "503"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/appstream"]
  }
}

resource "aws_instance" "server" {
#  availability_zone    = "${local.preferred_az[local.app_env]}"
  instance_type         = "${local.instance_type[local.app_env]}"
  ami                   = "${data.aws_ami.argosfx.id}"
  key_name              = "${aws_key_pair.server.key_name}"
  subnet_id             = "${element(module.network_ireland.private_app_subnets, 0 )}"
  get_password_data     = true
  iam_instance_profile  = "${aws_iam_instance_profile.instance_profile.id}"

  vpc_security_group_ids = [
    "${aws_security_group.server.id}",
  ]

  tags = "${merge(
  local.common_tags,
  map(
    "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
  )
  )}"
}



#As argosfx is mutable, removing autoscaling group

#Needed if not using auto scalling group , to register ec2 with target group
resource "aws_lb_target_group_attachment" "argosfx" {
  target_group_arn = "${element(module.alb_irland.alb_tg, 0 )}"
  target_id        = "${aws_instance.server.id}"
}

/*

#auto scalling group with launch configuration
resource "aws_autoscaling_group" "ec2_asg" {
  name                      = "${local.app_env}-${var.app_parent}-${var.app_name}-asg"
  max_size                  = "${local.instance_count[local.app_env] + 1}"
  min_size                  = "${local.instance_count[local.app_env]}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${local.instance_count[local.app_env]}"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ec2_argosfx.name}"
  vpc_zone_identifier       = ["${module.network_ireland.private_app_subnets}"]
  target_group_arns         = ["${module.alb_irland.alb_tg}"]

  termination_policies = ["OldestInstance", "OldestLaunchConfiguration"]

  lifecycle {
    create_before_destroy = true
  }

  #To be setup for scale up and down with new config.

  initial_lifecycle_hook {
    name                 = "asg"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 3600
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }
  tag {
    key                 = "Name"
    value               = "${local.app_env}-${var.app_parent}-${var.app_name}-server"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "ec2_argosfx" {
  name_prefix                 = "${local.app_env}-${var.app_parent}-${var.app_name}-argosfx"
  key_name                    = "${aws_key_pair.server.key_name}"
  image_id                    = "${data.aws_ami.argosfx.id}"
  instance_type               = "${local.instance_type[local.app_env]}"
  security_groups             = ["${aws_security_group.server.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.id}"
  spot_price                  = "0.01"
  associate_public_ip_address = false
  enable_monitoring           = false

  root_block_device {
    volume_size           = "${local.instance_root_volume_size[local.app_env]}"
    volume_type           = "${local.instance_root_volume_type[local.app_env]}"
    delete_on_termination = true
  }

#  user_data = "${data.template_file.user_data_script.rendered}"


  #provisioner "local-exec" {
  #  command = "aws autoscaling set-desired-capacity --auto-scaling-group-name ${local.app_env}-${var.app_parent}-${var.app_name}-asg --desired-capacity ${local.instance_count[local.app_env] + 1} --honor-cooldown"
  #}

  # launch configs can't be updated
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_launch_template" "argosfx_lt" {
  name = "${local.app_env}-${var.app_parent}-${var.app_name}-lt"

#  block_device_mappings {
#    device_name = "/dev/sda1"
#
#    ebs {
#      volume_size = 20
#    }
#  }


#check what it is
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "standard"
  }
  #disableApiTermination' cannot be used when launching a Spot instance
  #disable_api_termination = true

#keeping it to default
#  ebs_optimized = true

#  elastic_gpu_specifications {
#    type = "test"
#  }

#  elastic_inference_accelerator {
#    type = "eia1.medium"
#  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.instance_profile.id}"
  }

  image_id = "${data.aws_ami.windows.id}"

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
  }

  instance_type = "${local.instance_type[local.app_env]}"

#  kernel_id = "test"

  key_name = "${aws_key_pair.server.key_name}"

#  license_specification {
#    license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
#  }

  monitoring {
    enabled = false
  }

#  network_interfaces {
#    associate_public_ip_address = false
#    security_groups = ["${aws_security_group.server.id}"]
#  }

#  placement {
#    availability_zone = "us-west-2a"
#  }

#  ram_disk_id = "test"

  vpc_security_group_ids = ["${aws_security_group.server.id}"]

  tag_specifications {
    resource_type = "instance"
  tags = "${merge(
  local.common_tags,
  map(
    "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
  )
  )}"

  }

#  user_data = "${base64encode(...)}"
}




#autoscalling group with launch template
resource "aws_autoscaling_group" "ec2_asg" {
  name                      = "${local.app_env}-${var.app_parent}-${var.app_name}-asg"
  max_size                  = "${local.instance_count[local.app_env] + 1}"
  min_size                  = "${local.instance_count[local.app_env]}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${local.instance_count[local.app_env]}"
  force_delete              = true
   launch_template = {
    id      = "${aws_launch_template.argosfx_lt.id}"
    version = "$$Latest"
  }
  vpc_zone_identifier       = ["${module.network_ireland.private_app_subnets}"]
  target_group_arns         = ["${module.alb_irland.alb_tg}"]

  termination_policies = ["OldestInstance", "OldestLaunchConfiguration"]

  lifecycle {
    create_before_destroy = true
  }

  #To be setup for scale up and down with new config.

  initial_lifecycle_hook {
    name                 = "asg"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 3600
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }
  tag {
    key                 = "Name"
    value               = "${local.app_env}-${var.app_parent}-${var.app_name}-server"
    propagate_at_launch = true
  }
}
*/
