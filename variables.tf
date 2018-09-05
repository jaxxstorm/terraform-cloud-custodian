variable "namespace" {
  description = "A namespace for all the resources to live in"
}

variable "stage" {
  description = "A development stage (Eg. dev, stg, prod)"
}

variable "name" {
  description = "Name of invocation"
}

variable "region" {
  description = "AWS Region to create objects in"
}
