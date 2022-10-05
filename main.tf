provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "rolan-vpc-project" {
  cidr_block = "12.0.0.0/16"

  tags = {
    Name = "rolan-vpc-project"
  }
}

resource "aws_internet_gateway" "rolan-ig" {
  vpc_id = "${aws_vpc.rolan-vpc-project.id}"
  
  tags = {
    Name = "rolan-ig"
  }
}

resource "aws_route_table" "rolan-rt" {
  vpc_id = "${aws_vpc.rolan-vpc-project.id}"

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.rolan-ig.id}"
 } 

 tags = {
   Name = "rolan-rt"
 }
}


module "db-tier" {
  name="rolan-db"
  source="./modules/db-tier" #looks for a main tf at that path
  vpc_id="${aws_vpc.rolan-vpc-project.id}"
  route_table_id = "${aws_vpc.rolan-vpc-project.main_route_table_id}"
  cidr_block="12.0.10.0/24"
  user_data=templatefile("./scripts/db_user_data.sh", {})
  ami_id = "ami-" //use Jenkins packer ami
  map_public_ip_on_launch = true

  ingress = [{
    from_port       = 3024
    to_port         = 3024
    protocol        = "tcp"
    cidr_blocks     = "${module.api-tier.subnet_cidr_block}"
  }]
}

module "api-tier" {
  name="rolan-api"
  source="./modules/api-tier" #looks for a main tf at that path
  vpc_id="${aws_vpc.rolan-vpc-project.id}"
  route_table_id = "${aws_route_table.rolan-rt.id}"
  cidr_block="12.0.11.0/24"
  user_data=templatefile("./scripts/api_user_data.sh", {mysql_ip = module.db-tier.private_ip})
  ami_id = "ami-" //use Jenkins packer ami
  map_public_ip_on_launch = true

  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }]
}

module "react-tier" {
  name="rolan-react"
  source="./modules/react-tier" #looks for a main tf at that path
  vpc_id="${aws_vpc.rolan-vpc-project.id}"
  route_table_id = "${aws_route_table.rolan-rt.id}"
  cidr_block="12.0.12.0/24"
  user_data=templatefile("./scripts/react_user_data.sh", {})
  ami_id = "ami-" //use Jenkins packer ami
  map_public_ip_on_launch = true

  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }]
}
