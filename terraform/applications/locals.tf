locals {
  app_env      = "${terraform.workspace}"
  app_costcode = "IT-ARGOS"
  regions      = ["emea"]

  common_tags = {
    Family      = "${var.app_parent}"
    Application = "${var.app_name}"
    Environment = "${local.app_env}"
    CostCode    = "${local.app_costcode}"
  }

  argosfx_common_tags = {
    Family      = "${var.app_parent}"
    Application = "${var.app_name}"
    Environment = "${local.app_env}"
    CostCode    = "${local.app_costcode}"
  }

  contact_list = {
    DevTeam     = "GDCRetailDevelopmentTeam@travelex.com"
    SupportTeam = "GDCRetailAppsSupport@travelex.com"
  }

  infra_support_email = ["cloudengineeringteam@travelex.com"]

  # VPC / Network
  cidr_block = {
    uat = "10.72.6.0/24"
    production = "10.72.6.0/24"
  }

  # Selected / Stripped AZ list from all available AZs on which resources will be scaled.
  # 0 to 2 will return first two AZ from the list.
  selected_azs = "${slice(data.aws_availability_zones.available.names, 0, 3)}"

  # Preferred AZ to launch ec2 instance, rds instance: For example, eu-west-1a
  # 0 will fetch the first AZ from the selected AZ variable where EC2, RDS will be launched.
  launch_az    = "${element(local.selected_azs, 0)}"
  launch_az_1b = "${element(local.selected_azs, 1)}"

  # Preferred AZ for ec2 instance and rds instance: For example, eu-west-1a
  preferred_az = {
    uat = "${var.target_region}"
  }

  # Number of subnets per availability zone
  subnet_count_per_az = {
    public      = 1
    private_db  = 1
    private_app = 1
  }

  # New bits to be added to vpc cidr for subnetting i.e. from /24 to /28
  subnet_new_bits = 4

  # Network address starting range for each subnet type.
  subnet_netnum_start_index = {
    public      = 0
    private_db  = 4
    private_app = 8
  }

  # Argosfx network
  argosfx_network = {
    app_name           = "argosfx"
    count_per_az       = 1
    netnum_start_index = 12
  }



  # NAT Gateway
  # Should be true if you want to provision NAT Gateways for each of your private networks
  enable_nat_gateway = {
    uat = true
    production = true
  }

  # Should be true if you want to provision a single shared NAT Gateway across all of your private networks
  single_nat_gateway = {
    uat = true
    production = false
  }

  # Should be true if you want only one NAT Gateway per availability zone as per (local.selected_azs). Requires `local.selected_azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `local.selected_azs`.
  one_nat_gateway_per_az = {
    uat = false
  }

  # Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable
  reuse_nat_ips = {
    uat = false
  }

  #Endpoint

  # Should be true if you want to provision an S3 endpoint to the VPC
  enable_s3_endpoint = {
    uat = true
    production = true
  }
  # Should be true if you want to provision an SSM endpoint to the VPC
  enable_ssm_endpoint = {
    uat = true
    production = true
  }
  # Should be true if you want to provision an ssmmessages endpoint to the VPC
  enable_ssmmessages_endpoint = {
    uat = true
    production = true
  }
  # Should be true if you want to provision an ec2messages endpoint to the VPC
  enable_ec2messages_endpoint = {
    uat = true
    production = true
  }
  # Should be true if you want to provision a squid endpoint to the VPC
  enable_squid_endpoint = {
    uat = true
    production = true
  }
  # Security group
  inbound_tvx_whiltelist_ips = {
    nonprod = [
      # GDC
      "121.244.32.128/27",

      # WWH
      "195.99.138.0/24",

      # Digital PaaS UAT
      "52.50.91.209/32",

      "34.250.76.94/32",
      "52.211.11.169/32",
    ]

    prod = [
      # GDC
      "121.244.32.128/27",

      # WWH
      "195.99.138.0/24",
    ]
  }

  # RDS

  rds_multi_az = {
    uat = false
    production = true
  }
  rds_instance_type = {
    uat = "db.t2.medium"
    production = "db.t2.small"
  }
  rds_backup_retention = {
    uat = 7
    production = 30
  }
  rds_backup_window = {
    uat = "23:30-00:00"
    production = "23:30-00:00"
  }
  rds_option_group_engine = {
    uat = "13.00"
    production = "13:00"
  }
  rds_maintenance_window = {
    uat = "SAT:23:00-SAT:23:30"
    production = "SAT:23:00-SAT:23:30"
  }
  rds_storage_type = {
    uat = "gp2"
    production = "gp2"
  }
  rds_engine = {
    uat = "sqlserver-web"
    production = "sqlserver-web"
  }
  rds_engine_version = {
    uat = "13.00.5216.0.v1"
    production = "13.00.5216.0.v1"
  }
  rds_vol_size = {
    uat = 20
    production = 40
  }
  rds_username  = "db_admin"
  license_model = "license-included"

  #EC2

  # Common Services EC2
  instance_type = {
    uat = "t2.micro"
  }
  instance_root_volume_type = {
    uat  = "standard"
    prod = "gp2"
  }
  instance_root_volume_size = {
    uat  = 30
    prod = 30
  }
  instance_ebs_volume_type = {
    uat  = "standard"
    prod = "gp2"
  }
  instance_ebs_volume_size = {
    uat = 10
  }
  instance_count = {
    uat = 1
  }
  # POINTS Services EC2
  points_instance_type = {
    uat = "t2.micro"
  }
  points_instance_root_volume_type = {
    uat  = "standard"
    prod = "gp2"
  }
  points_instance_root_volume_size = {
    uat  = 30
    prod = 30
  }
  points_instance_ebs_volume_type = {
    uat  = "standard"
    prod = "gp2"
  }
  points_instance_ebs_volume_size = {
    uat = 10
  }
  points_instance_count = {
    uat = 1
  }
  #ALB
  alb_enable_delete_protection = {
    uat = false
  }
  #Squid Enpoint
  squid_service_name = {
    nonprod = "com.amazonaws.vpce.eu-west-1.vpce-svc-00dc1c7a12c8abcec"
    prod    = "com.amazonaws.vpce.eu-west-1.vpce-svc-00dc1c7a12c8abcec"
  }
  #DNS Root Zone names.
  dns_roots = {
    nonprod = "tvx-test.cloud"
    prod    = "tvx.cloud"
  }
  #DNS Records Fepends on alb module
  dns_records_cname = {
    web = "${module.alb_irland.dns_name}"
  }

  # Service name to use in ACM & Route 53.
  service_name = "web"
  new_service_name = "app"

  # This is to limit the permissions to policy attached to IAM instance role or RDS option group role.
  s3_prefix = {
    scheduler = "scheduler-config"
    rds       = "rds-config"
  }
  # some variables  referred in Main user-data script.
  app_dir_layout = {
    app_home = "C:\\Travelex"
    temp_dir = "C:\\Temp\\Launch_Config"
    app_logs = "C:\\Travelex\\Logs"
  }
  # Target Group application path.
  app_paths = [
    #"/Account/LogOn.aspx"
    "/*"
  ]
  service = ["argosfxservice"]

}
