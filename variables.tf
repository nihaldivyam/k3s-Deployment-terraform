variable "deployer-public-key" {
  type    = string
}

variable "ami_id" {
  type    = string
  default = "ami-026669ec456129a70"
}
variable "worker_instance_type" {
  type    = string
  default = "t2.micro"
}
# copy token from master node and paste here.
variable "k3s_token" {
  type    = string
  default = "K1055d6435f6c60be8d6ac9c4c7c760b6f8b502ba6fa6c986412aa56f02ffe2d157::server:randomstring123"
}
variable "cluster_name" {
  type    = string
  default = "k3s-demo"
}