variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "enable_private_network" {
  type    = bool
  default = true
}
