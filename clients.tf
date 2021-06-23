# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "clients" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-cluster"

  cluster_name     = "${var.cluster_name}-client"
  cluster_size     = var.num_servers
  instance_type    = "t3.medium"
  spot_price       = var.spot_price
  root_volume_size = 16

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = var.cluster_tag_key
  cluster_tag_value = var.cluster_name

  ami_id = data.aws_ami.base.image_id
  user_data = templatefile("user-data-client.sh", {
    cluster_tag_key   = var.cluster_tag_key,
    cluster_tag_value = var.cluster_name,
    nomad_region      = var.nomad_region,
    nomad_datacenter  = var.cluster_name,
  })


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = var.ssh_key_name

  tags = [
    {
      key                 = "Environment"
      value               = "hc_demo"
      propagate_at_launch = true
    }
  ]
}



resource "aws_security_group_rule" "allow_clients_inbound" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535 # Don't do it in prod
  protocol    = "tcp"
  cidr_blocks = var.allowed_inbound_cidr_blocks

  security_group_id = module.clients.security_group_id
}
