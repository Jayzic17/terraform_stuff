# This is where you can specify you packer build (a.k.a the Packer Template file)

variable "ami_id" {
	type = string
	default = "ami-087c17d1fe0178315"
}

locals {
	app_name = "httpd"
}

# the 'source' says where and what kind of image to build
# in this case, it will create an EBS-backed AMI
# the image will be stored directly in AWS under EC2 images
source "amazon-ebs" "httpd" {
	ami_name = "my-server-${local.app_name}"
	instance_type = "t2.micro"
	region = "us-east-1"
	source_ami = "${var.ami_id}"
	ssh_username = "ec2-user"
	tags = {
		Name = local.app_name
	}
}

# the 'build' allows us to provide configuration scripts. Packer supports a wide range of Provisioners:
# Chef, Puppet, Ansible, PowerShell, Bash, Salt, etc.
build {
	sources = ["source.amazon-ebs.httpd"]
	provisioner "shell"  {
		inline = [
			"sudo yum install -y httpd",
			"sudo systemctl start httpd",
			"sudo systemctl enable httpd"
		]
	}

    # post-processors run after the image is built. They can be used to upload artifacts or re-package
    post-processor "shell-local" {
        inline = ["echo foo"]
    }
}