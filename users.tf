terraform {
  required_version = ">= 1.5"
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

locals {
  # Editable mapping: environments -> applications -> roles -> users
  users_by_env_app_role = {
    dev = {
      "Billing Console" = {
        read-only = ["dev.alice", "dev.bob"]
        admin     = ["dev.olivia"]
      }
      "Analytics Hub" = {
        read-only = ["dev.cara"]
        admin     = ["dev.casey"]
      }
      "Data Lake" = {
        read-only = ["dev.jordan"]
        admin     = []
      }
    }
    stage = {
      "Billing Console" = {
        read-only = ["stg.alice"]
        admin     = ["stg.olivia"]
      }
      "Analytics Hub" = {
        read-only = ["stg.cara"]
        admin     = ["stg.casey"]
      }
      "Data Lake" = {
        read-only = ["stg.jordan"]
        admin     = []
      }
    }
    prod = {
      "Billing Console" = {
        read-only = ["alice"]
        admin     = ["olivia"]
      }
      "Analytics Hub" = {
        read-only = ["cara"]
        admin     = ["casey"]
      }
      "Data Lake" = {
        read-only = ["jordan"]
        admin     = []
      }
    }
  }

  # Flatten to a list of bindings
  bindings = flatten([
    for env, apps in local.users_by_env_app_role : [
      for app, roles in apps : [
        for role, users in roles : [
          for user in users : {
            key         = "${env}/${app}/${role}/${user}"
            environment = env
            application = app
            role        = role
            user        = user
          }
        ]
      ]
    ]
  ])
}

# Optional: create users (swap for your IdP/IAM resource)
resource "example_identity_user" "user" {
  for_each = { for b in local.bindings : b.user => b.user }

  username = each.value
  email    = "${each.value}@example.com"
}

# Apply role bindings (swap for your real binding resource/provider)
resource "example_app_role_binding" "binding" {
  for_each = { for b in local.bindings : b.key => b }

  environment = each.value.environment
  application = each.value.application
  role        = each.value.role
  username    = each.value.user
}