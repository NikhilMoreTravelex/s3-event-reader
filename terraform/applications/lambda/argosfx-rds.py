import boto3
import socket
import os

db_instance = os.environ['DB_INSTANCE']
targetgroup_arn = os.environ['TARGETGROUP_ARN']

def lambda_handler(event, context):
	
	print("RDS failover has occured; retrieving rds instance details to update new IP address")
	source = boto3.client('rds')
	instances = source.describe_db_instances(DBInstanceIdentifier=db_instance)
	rds_address = instances.get('DBInstances')[0].get('Endpoint').get('Address')
	rds_port = instances.get('DBInstances')[0].get('Endpoint').get('Port')
	
	new_ip_address = socket.gethostbyname(rds_address)
	print("RDS instance IP has been changed to %s" % (new_ip_address))
	
	NetworkELB = boto3.client('elbv2')
	unhealthy_targets_details = NetworkELB.describe_target_health(
		TargetGroupArn=targetgroup_arn,
		)
	old_ip_address = unhealthy_targets_details.get('TargetHealthDescriptions')[0].get('Target').get('Id')
	print("Target with IP details %s is in unhealthy state" % (old_ip_address))
	
	deregister_target = NetworkELB.deregister_targets(
			TargetGroupArn=targetgroup_arn,
			Targets=[
				{
					'Id': old_ip_address,
					'Port': rds_port,
				},
			],
		)
	
	print("Old IP (%s) instance has been deregisted from target group" % (old_ip_address))
	
	register_target = NetworkELB.register_targets(
			TargetGroupArn=targetgroup_arn,
			Targets=[
				{
					'Id': new_ip_address,
					'Port': rds_port,
				},
			],
		)
	
	print("New IP (%s) instance has been registed to target group" % (new_ip_address))

