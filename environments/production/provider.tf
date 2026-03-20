terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Platform subscription (hub)
provider "azurerm" {
  alias           = "platform"
  subscription_id = "1600c19f-74f6-4dc2-b68d-7533649ec025"
  features {}
}

