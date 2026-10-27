terraform {
  required_version = "1.16.0"

  cloud {
    hostname     = "tfe1.tfe-iks-396fd0d6cb18cdb028a7bd988fd987fd-0000.eu-de.containers.appdomain.cloud"
    organization = "test"

    workspaces {
      name = "test"
    }
  }
}

resource "null_resource" "name" {

}