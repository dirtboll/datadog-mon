data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnet" "default_a" {
  availability_zone = "${data.aws_region.current.id}a"
}

data "aws_security_groups" "default" {
  filter {
    name = "group-name"
    values = [ "default" ]
  }
}

resource "aws_ec2_instance_connect_endpoint" "default" {
  subnet_id          = data.aws_subnet.default_a.id
  security_group_ids = data.aws_security_groups.default.ids
}

resource "aws_security_group_rule" "allow_all" {
  security_group_id = data.aws_security_groups.default.ids[0]
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}
