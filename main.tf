terraform {
  backend "s3" {}

  required_providers {
    docker = {
      source  = "registry.terraform.io/kreuzwerker/docker"
      version = "~>3.0"
    }

    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~>3.5"
    }
  }
}

provider "random" {}
provider "docker" {}

variable "port" {
  type    = number
  default = 5432
}

variable "network_mode" {
  type    = string
  default = "bridge"
}

resource "random_pet" "dbname" {
  length = 1
}

resource "docker_image" "postgres" {
  name         = "postgres:latest"
  keep_locally = false
}

resource "docker_container" "postgres" {
  image        = docker_image.postgres.image_id
  name         = random_pet.dbname.id
  network_mode = var.network_mode
  ports {
    internal = 5432
    external = var.port
  }

  env = [
    "POSTGRES_PASSWORD=${random_pet.dbname.id}",
    "POSTGRES_USER=${random_pet.dbname.id}",
    "POSTGRES_DB=${random_pet.dbname.id}"
  ]
}

locals {
  port = var.network_mode == "host" ?  5432: docker_container.postgres.ports[0].external
}

output "POSTGRES_URL" {
  sensitive = true
  value     = "postgresql://${random_pet.dbname.id}:${random_pet.dbname.id}@localhost:${local.port}/${random_pet.dbname.id}"
}

output "POSTGRES_ROOT_URL" {
  sensitive = true
  value     = "postgresql://${random_pet.dbname.id}:${random_pet.dbname.id}@localhost:${local.port}"
}

output "DBNAME" {
  sensitive = true
  value     = random_pet.dbname.id
}

