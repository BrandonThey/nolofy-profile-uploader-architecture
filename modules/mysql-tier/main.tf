resource "aws_subnet" "nology-uploader-db-subnet" {
    vpc_id      = "${var.vpc_id}"
    cidr_block  = "${var.cidr_block}"

    tags = {
        Name = "${var.name}-subnet"
    }
}

resource "aws_security_group" "group" {
    name        = "${var.name}-sg"
    description = "Allow access from MySQL only"
    vpc_id      = "${var.vpc_id}"

    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_security_group_rule" "rule" {
  count             = "${length(var.ingress)}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "${lookup(var.ingress[count.index], "from_port")}"
  to_port           = "${lookup(var.ingress[count.index], "to_port")}"
  cidr_blocks       = ["${lookup(var.ingress[count.index], "cidr_blocks")}"]
  security_group_id = "${aws_security_group.group.id}"
}

resource "aws_instance" "db" {
    ami                     = "${var.ami_id}"
    instance_type           = "t2.micro"
    key_name                = "" // ADD AWS KEY WHEN GENERATED
    user_data               = "${var.user_data}"
    subnet_id               = "${aws_subnet.nology-uploader-db-subnet.id}"
    vpc_security_group_ids  = ["${aws_security_group.group.id}"]

    tags = {
        Name = "${var.name}"
    }
}

