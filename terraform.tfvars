# This is called a Variable Definition File: where you can set values for input variables
# can also end with: 'tfvars.json'
# is auto-loaded by default

instance_type = "t2.micro"

# Another way of setting values for variables is by using Environment Variables 
# terraform looks for variables starting with: "TF_VAR_" and will be loaded to your CICD solution (EX: Terraform Cloud)
TF_VAR_instance_type = "value_here"

# You can also use multiple Variable Definition Files, but they won't be auto-loaded unless you specify them via command line: 'terraform apply -var-file filename.tfvars' or 'terraform apply -var-file filename.tfvars'
# Another way is to name your Variable Definition File with: '.auto.tfvars', and it will always be loaded


