# Ansible role for tf_int OU
  - ## tf_init:
      - this role is used for bootstrapping for terraform.       
      - `circleci-nonprod` role is used for kms keys encryption and S3 bucket policies in `bootstrap.yml`
      - This role will create s3 bucket named `terraform-bootstrap-nonprod-XXXXXX` in org account as per the `hostname` i.e. Account name.This S3 buckets are used to store statefiles of the terraform executions 
      - ![S3 bucket structure in org account ](../../../images/S3.JPG)          
      - ![Unique tfstate.tfstate for each child account ](../../../images/S3-2.JPG)
      - This S3 bucket is encrypted with KMS key which is created in bootstrap.yml role and only circleci user can have access to modify/update/delete that bucket externally.
          
