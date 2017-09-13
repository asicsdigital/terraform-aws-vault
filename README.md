# terraform-vault

===========

Terraform Module for deploying Vault on AWS ECS

docker run -it --rm -d --network=host --cap-add=IPC_LOCK -e 'VAULT_LOCAL_CONFIG={"backend": {"consul": {"address": "127.0.0.1:8500", "path": "vault"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}'  vault server

> CircleCI


This Module currently supports Terraform 0.10.x, but does not require it. If you use tfenv, this module contains a `.terraform-version` file which matches the version of Terraform we currently use to test with.


Module Input Variables
----------------------
#### Required
- `alb_log_bucket` - s3 bucket to send ALB Logs
- `dns_zone` - Zone where the Consul UI alb will be created. This should *not* be consul.tld.com
- `ecs_cluster_id` - ARN of the ECS ID
- `env` - env to deploy into, should typically dev/staging/prod
- `join_ec2_tag` - EC2 Tags which consul will search for in order to generate a list of IP's to join. See https://github.com/hashicorp/consul-ec2-auto-join-example for more examples.
- `subnets` - List of subnets used to deploy the Consul alb
- `vpc_id`  - VPC ID
- `sha_htpasswd_hash` - Entries must be created with htpasswd -s for SHA encryption
- `oauth2_proxy_github_org` - Github Org
- `oauth2_proxy_client_id` - the OAuth Client ID: ie: 123456.apps.googleusercontent.com
- `oauth2_proxy_client_secret` - the OAuth Client Secret
- `s3_backup_bucket` - S3 Bucket to use to store backups of consul snapshots - defaults to backup-bucket


#### Optional

- `additional_user_data_script` - Additional user_data scripts content
- `region` - AWS Region - defaults to us-east-1
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
- `allowed_cidr_blocks` - List of subnets to allow into the ECS Security Group. Defaults to `["0.0.0.0/0"]`.
- `heartbeat_timeout` - Heartbeat Timeout setting for how long it takes for the graceful shutodwn hook takes to timeout. This is useful when deploying clustered applications like consul that benifit from having a deploy between autoscaling create/destroy actions. Defaults to 180"
- `security_group_ids` - a list of security group IDs to apply to the launch configuration
- `vault_image` - Image to use when deploying consul, defaults to the hashicorp consul image

Usage
-----

```hcl
module "ecs-cluster" {
  source    = "github.com/terraform-community-modules/tf_aws_ecs"
  name      = "infra-services"
  servers   = 1
  subnet_id = ["subnet-6e101446"]
  vpc_id    = "vpc-99e73dfc"
}

```

#### Example cluster with consul and Registrator

In order to start the Consul/Registrator task in ECS, you'll need to pass in a consul config into the `additional_user_data_script` script parameter.  For example, you might pass something like this:

Please note, this module will try to mount `/etc/consul/` into `/consul/config` in the container and assumes that the consul config lives under `/etc/consul` on the docker host.  

```Shell
/bin/mkdir -p /etc/consul
cat <<"CONSUL" > /etc/consul/config.json
{
	"raft_protocol": 3,
	"log_level": "INFO",
	"enable_script_checks": true,
  "datacenter": "${datacenter}",
	"retry_join_ec2": {
		"tag_key": "consul_server",
		"tag_value": "true"
	}
}
CONSUL
```


```hcl

data "template_file" "ecs_consul_agent_json" {
  template = "${file("ecs_consul_agent.json.sh")}"

  vars {
    datacenter = "infra-services"
  }
}

module "ecs-cluster" {
  source                      = "github.com/terraform-community-modules/tf_aws_ecs"
  name                        = "infra-services"
  servers                     = 1
  subnet_id                   = ["subnet-6e101446"]
  vpc_id                      = "vpc-99e73dfc"
  additional_user_data_script = "${data.template_file.ecs_consul_agent_json.rendered}"
  enable_agents               = true
}


```


Outputs
=======

- `cluster_id` - _(String)_ ECS Cluster id for use in ECS task and service definitions.
- `autoscaling_group` _(Map)_ A map with keys `id`, `name`, and `arn` of the `aws_autoscaling_group` created.  

Authors
=======

* [Tim Hartmann](https://github.com/tfhartmann)

License
=======

[MIT](LICENSE)
