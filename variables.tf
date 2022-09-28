# This is a variables.tf file where you can declare a variables type in addition to setting some default values via blocks
# Slightly different from terraform.tfvars in that it lets you do a little more than just defining a value

# Here is how you use different IAM Roles and switch between them using the terraform console via workspaces:
variable "workspace_iam_roles" {
  default = {
    staging    = "arn:aws:iam::STAGING-ACCOUNT-ID:role/Terraform"
    production = "arn:aws:iam::PRODUCTION-ACCOUNT-ID:role/Terraform"
  }
}

# Here is how you would define an object
variable "with_optional_attribute" {
  type = object({
    a = string
    b = optional(number)
  })

  default = {
    a = "forever"
    b = 21
  }
}

# Here is how to make a tuple
variable "idk" {
  type    = tuple(string, number, bool)
  default = ["hello", 22, false]
}

# Here is how to make lists
variable "planets" {
  type    = list(any)
  default = ["mars", "earth", "moon"]
}

# Here is how to make a map
variable "plans" {
  type = map(any)
  default = {
    "PlanA" = "10 USD"
    "PlanB" = "50 USD"
  }
}

