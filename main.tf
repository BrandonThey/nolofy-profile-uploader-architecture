provider "aws" {
  region = "us-east-1" //CHANGE THIS IF NEEDED
}

//Creating a vpc with a unique 16 bit mask
//This vpc will house our subnets for the app and the database
//This will also create a private route table for our database
resource "aws_vpc" "nology-uploader-vpc" {
  cidr_block = "99.0.0.0/16" //CHANGE THIS LATER IF NEEDED
  tags = {
    Name = "nology-uploader-vpc"
  }
}

//Creating Internet gateway that will connect our VPC
//and contents inside with the internet
resource "aws_internet_gateway" "nology-uploader-ig" {
  vpc_id = "${aws_vpc.nology-uploader-vpc.id}"
  tags = {
    Name = "nology-uploader-ig"
  }
}

//Creating our public route table that will connect the internet gateway
//with our public app
resource "aws_route_table" "nology-uploader-rt" {
  vpc_id = "${aws_vpc.nology-uploader-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nology-uploader-ig.id}"
  }
  tags = {
    Name = "nology-uploader-rt"
  }
}

module "db-tier" {
  name="nology-uploader-db"
  source = "./modules/mysql-db"
  vpc_id = "${aws_vpc.nology-uploader-vpc.id}"
  route_table_id = "${aws_vpc.nology-uploader-vpc.main_routing_table}"
  cidr_block = "99.0.1.0/24"
  user_data = templatefile("./scripts/db_user_data.sh", {}) //NEED TO WORK ON GETTING SCRIPT FOR THIS
  ami_id = "ami-0c39c5647431f40ef" //NEEDS TO BE CHANGED LATER BASED ON REGION AND IMAGE

  ingress = [{
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_block = "${module.app-tier.subnet_cidr_block}"
  }]
}

module "app-tier" {
  name = "nology-uploader-app"
  source = "./modules/app"
  vpc_id = "${aws_vpc.nology-uploader-vpc.id}"
  route_table_id = "${aws_vpc.nology-uploader-rt.id}"
  cidr_block = "99.0.2.0/24"
  user_data = templatefile("./scripts/app_user_data.sh", {/*mongodb_ip = module.db-tier.private_ip*/}) //NEED TO WORK ON GETTING SCRIPT FOR THIS
  ami_id = "ami-0c39c5647431f40ef" //NEEDS TO BE CHANGED LATER BASED ON REGION AND IMAGE, TO MATCH FRONTEND MACHINE
  map_public_ip_on_launch = true

  ingress = [{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }]
}