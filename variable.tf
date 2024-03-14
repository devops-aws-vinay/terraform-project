variable "vpc-cidrip"{
    default = "10.0.0.0/16"
}

variable "sub1a-ip"{
    default = "10.0.1.0/24"
}

variable "sub1b-ip"{
    default = "10.0.2.0/24"
}

variable "vpc-sg"{
    default = [aws_security_group.vpcsg.id]
}