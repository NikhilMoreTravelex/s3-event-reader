data "aws_ami" "argosfx" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ami-${var.target_region}-${local.app_env}-${var.app_parent}-${local.argosfx_common_tags["Application"]}-windows-server-2016*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${data.aws_caller_identity.this.account_id}"] # Self Account.
}


resource "tls_private_key" "jump_host_common" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "jump_host_common" {
  key_name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-jumphost-key-"
  public_key      = "${tls_private_key.jump_host_common.public_key_openssh}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-instance-"
  role        = "${aws_iam_role.instance_role.name}"
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "server" {
  key_name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-app-key-"
  public_key      = "${tls_private_key.server.public_key_openssh}"
}

#Main instance now covered in asg launch config


# To be deleted once everything is setup properly.
resource "aws_instance" "jump_host_common" {
# once rts ami created from packer then replace it with below one
#  ami                         = "${data.aws_ami.rts.id}"
  ami                         = "${data.aws_ami.windows.id}"
  availability_zone           = "${local.launch_az_1b}"
  instance_type               = "${local.instance_type[local.app_env]}"
  key_name                    = "${aws_key_pair.jump_host_common.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.external_access.id}"]
  subnet_id                   = "${element(module.network_ireland.public_subnets, 1 )}"
  associate_public_ip_address = true
  source_dest_check           = false
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.id}"
  tags = "${merge(
  local.common_tags,
  map(
    "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-jumphost"
  )
  )}"
}





