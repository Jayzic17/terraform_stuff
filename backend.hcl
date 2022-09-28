# This is where you can define the configuration for your backend if you want to have it here instead of main.tf
# backends are storage spaces (EX: s3) where state files are stored (can be locally on your computer, or remote)
workspaces {name = "workspaces"}
hostname = "app.terraform.io"
organization = "company"