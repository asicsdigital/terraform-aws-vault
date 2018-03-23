# terraform-vault

===========

Terraform Module for deploying Vault on AWS ECS

This module contains a `.terraform-version` file which matches the version of Terraform we currently use to test with.

[![CircleCI](https://circleci.com/gh/FitnessKeeper/terraform-aws-vault.svg?style=svg)](https://circleci.com/gh/FitnessKeeper/terraform-aws-vault)


#### Introduction and Assumptions

This module makes a couple of assumptions and deploy vault based on them.

* Vault will be deployed with a public end public endpoint behind an ALB
* Vault gets deployed and automatically unsealed - as such we break Shamir's Secret by expecting only a single unseal key is required.  
* Vault Traffic is currently *unencrypted* within the VPC, but uses ACM certs on an ALB to encrypt traffic to an external client.
* The Vault ECS Task will run on an ECS Instance with Consul already running.
* Manual initialization of vault is required.  


##### Initialize Vault

Log into an ECS host, or a host that can run docker within your VPC, or within the consul datacenter.

* Start a initial vault container.

`docker run -it --privileged --network=host -e 'VAULT_LOCAL_CONFIG={ "backend": {"consul": {"address": "10.1.10.24:8500", "path": "vault"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h", "listener": [{ "tcp": { "address": "0.0.0.0:8200", "tls_disable": true }}] }'  vault server`


`docker run --rm -it -e VAULT_ADDR='http://127.0.0.1:8200' --privileged --network=host vault init`


`docker run --rm -it -e VAULT_ADDR='http://127.0.0.1:8200' --privileged --network=host vault unseal $KEY`

##### Initialize Vault


Create a Master Key AWS docs can be found here: http://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html

Use the newly created master key to encrypt the vault unseal key.

`aws kms encrypt --key-id $KEY_ID --plaintext 'secret' --encryption-context region=us-east-1,tier=dev --output text --query CiphertextBlob`


Module Input Variables
----------------------
#### Required
- `alb_log_bucket` - s3 bucket to send ALB Logs
- `dns_zone` - Zone where the Consul UI alb will be created. This should *not* be consul.tld.com
- `ecs_cluster_id` - ARN of the ECS ID
- `env` - env to deploy into, should typically dev/staging/prod
- `subnets` - List of subnets used to deploy the Consul alb
- `unseal_keys` - List of 3 Vault Unseal keys
- `vpc_id`  - VPC ID

#### Optional

- `vault_image` - Image to use when deploying vault, (Default: hashicorp/vault)
- `cloudwatch_log_retention` - Specifies the number of days you want to retain log events in the specified log group. (Default: 30)
- `desired_count` - Number of vaults that ECS should run. (Default: 2)
- `extra_tags` - Additional tags to be added to the ECS autoscaling group. Must be in the form of an array of hashes. See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html for examples.
```
extra_tags = [
    {
      key                 = "consul_server"
      value               = "true"
      propagate_at_launch = true
    },
  ]
```
- `hostname` - DNS Hostname for the bastion host. Defaults to ${VPC NAME}.${dns_zone} if hostname is not set
- `iam_path` - IAM path, this is useful when creating resources with the same name across multiple regions. (Default: / )
- `lb_deregistration_delay` - The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. (Default: 300)
- `service_minimum_healthy_percent` - The minimum healthy percent represents a lower limit on the number of your service's tasks that must remain in the RUNNING state during a deployment
- `tags` - A map of tags to add to all resources

Usage
-----

```hcl
module "vault" {
  source         = "github.com/FitnessKeeper/terraform-aws-vault?ref=v0.0.1"
  alb_log_bucket  = "rk-devops-${var.region}"
  vault_image     = "${var.vault_image}"
  ecs_cluster_ids = "${module.ecs_consul.cluster_id}"
  dns_zone        = "${aws_route53_zone.region.name}"
  env             = "${var.env}"
  subnets         = "${module.vpc.public_subnets}"
  unseal_keys     = "${split(",",data.aws_kms_secret.unseal_key.vault)}"
  vpc_id          = "${module.vpc.vpc_id}"

  tags = {
    "foo" = "bar"
  }

}

```

Outputs
=======

- `public_endpoint` - _(String)_ Public FQDN of the ALB. i.e. vault.example.com
- `public_url` - _(String)_ Public URL used to connect to vault. i.e. https://vault.example.com

Authors
=======

* [Tim Hartmann](https://github.com/tfhartmann)

License
=======

[MIT](LICENSE)
