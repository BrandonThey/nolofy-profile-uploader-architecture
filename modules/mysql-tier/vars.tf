variable "vpc_id" {
  description = "The VPC ID in AWS"
}

variable "map_public_ip_on_launch" {
  default = false
}

variable "cidr_block" {
  description = "The CIDR block of the tier subnet"
}

variable "name" {
  description = "name to be used for tagging instances"
}


variable "route_table_id" {
  description = "id of route table to associate with the subnet"
}

variable "user_data" {
  description = "user data to start the instance"
}

variable "ami_id" {
  description = "the id of the ami for the instance"
}

variable "ingress" {
  type = list
}
  