/*
This is a
multi-line comment
*/

// This is a single line comment

# This is also a single line comment

# This is the main.tf file (the name 'main' is just conventional, it's not necessary. Terraform will look for any .tf file when trying to run commands)

# This is the terraform configuration block type: allows you to configure some behaviors or terraform itself
# required_version : what version of terraform you want to run
# required_providers : the Providers that will be pulled during a 'terraform init'
# experiments : experimental terraform language features you can include
# provider_meta : Module-specific information for Providers
terraform {

  # This is for specifying the cloud provider to use EX: aws
  # required_providers vs providers block: the first is for defining "constraints", the 2nd one is for configuring the settings
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.58.0" # Providers are released on a separate schedule from terraform, so best to explicitly specify a specific version of the provider to avoid code breakage

      # version constraints:
      //version = "=3.58.0"  # version must be EXACTLY 3.58.0
      //version = "!=3.58.0" # any version BUT 3.58.0
      //version = ">=3.58.0" # version can be greater than or equal to 3.58.0
      //version = "~>3.58.0" # versions where only the right-most digit increments (EX: 3.58.1) 
      configuration_aliases = [aws.alternate] # How to set alias provider for a parent module
    }
  }

  # This is how you define a remote workspace/backend in Terraform Cloud
  # Note: this is assuming you've created the workspace in Terraform Cloud first
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "org_name_here"
    workspaces = {
      name = "workspace_name_here"

      # you can use 'prefix' to specify multiple workspaces, but you can't have both 'prefix' and 'name', otherwise it will throw an error
      prefix = "workspace_"
    }
  }

  # Here's where you can setup your backend configuration in a backend.hcl file and use: 'terraform init -backend-config=backend.hcl'
  backend "remote" {}

  # This is how you define a local backend
  # by default, you use the backend state when you have not specified a backend
  backend "local" {
    path = "relative/path/to/terraform.tfstate"
  }
}

# This is the terraform_remote_state data resource if you're using a local backend
# terraform_remote_state retrieves the root module output values from another terraform configuration, using the latest state snapshot from the remote backend
# (ctrl + F: 'explicitly publishing data' for the suggested alternative)
data "terraform_remote_state" "vpc" {
  backend = "local"
  //backend = "s3"

  config = {
    path = "..."
  }

  //bucket = "..."
  //key = "path/to/my/key"
  //region = "us-east-1"
}

#...and this is how you would use it:
resource "aws_instance" "foo" {
  subnet_id = data.terraform_remote_state.vpc.outputs.subnet_id
}

# This is the terraform_remote_state data resource if you're using a remote backend
data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "..."
    workspaces = {
      name = "..."
    }
  }
}

#...and this is how you would use it:
resource "aws_instance" "foo" {
  subnet_id = data.terraform_remote_state.vpc.outputs.subnet_id
}

# terraform_remote_state only exposes output values, its user must have access to the entire state snapshot, which often includes some sensitive information
# so explicitly publishing data is the more recomended method, meaning use data sources and references whenever possible:
data "aws_s3_bucket" "selected" {
  bucket = "bucket.test.com"
}

data "aws_route53_zone" "test_zone" {
  name = "test.com."
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.test_zone.id
  name    = "bucket"
  type    = "A"

  alias {
    name    = data.aws_s3_bucket.selected.website_domain
    zone_id = data.aws_s3_bucket.selected.hosted_zone_id
  }
}

# This is how to generate an aws key pair
resource "aws_key_pair" "deployer" {
  count      = terraform.workspace == "default" ? 5 : 1 # this is how to reference the current workspace being worked in
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

# This is how to declare an input variable: parameters for terraform Modules
# type : specifies what value types are accepted for this variable (can also be a list of types)
# default : a default value, which then makes the variable optional
# description : specifies the input variable's documentation
# validation : a block for defining validation rules; in addition to type constraints
# sensitive : prevents value from being outputed to terraform UI when the variable is used in configuration
# you reference an input variable by preceeding the variable name with: 'var.'
# you can declare variables in either the root module (as shown), or in child modules
variable "instance_type" {
  type    = string
  default = ["us-west-1a"]
  validation {
    condition     = can(regex("^t2.-", var.instance_type))                   # can(): evaluates an expression and returns a boolean based on whether the expression produced a result without any errors
    error_message = "The instance type value must be a valid instance type." # must start with an uppercase letter and end with a period
  }
}

# This is how to declare a local variable
# So when you go to reference these variables, remember to preceed the variable name with: 'local.'
# However, it's best practice to use locals sparingly
locals {
  project_name = "Andrew"
}

# You can even have more than 1 'locals' block (not sure why you would need 2 tho)
locals {
  Project    = local.project_name
  first_name = "Jonathan"

  # String directive: lets you embed logic into a string
  # The '~' gives you the option to strip out leading whitespace
  greeting       = "hello, %{if local.first_name != ""}${local.first_name}%{else~}unamed%{endif~}"
  a_number       = 6.34324 # Note: the 'number' type includes whole numbers and fractions (there is no explicit 'float' type in terraform; that's handled by the 'number' type)
  the_null_value = null    # In terraform, 'null' means the default value; not "nothing"
  list_of_stuff  = ["hi", "how are ya?"]
  map_of_stuff   = { me = "based", you = "beta" }
  example_object = {a = 1, b = "hey"}
  example_tuple = ["hello", 22, false]

  a       = true
  b       = false
  result  = a || b
  result2 = a && b
  result3 = a == b

  c = "Andrew"
  d = (c == "Andrew") ? "Jonathan" : "Paige"

  # Here are some 'for' expressions. You can iterate over a list, set, tuple, map, or object
  # [] returns a list
  e = [for f in local.list_of_stuff : upper(f)] # ["HI", "HOW ARE YA?"]
  # {} returns an object
  m = { for n in local.list_of_stuff : n => upper(n) }         # {hi = "HI", how are ya? = "HOW ARE YA?"}
  g = [for h, i in local.map_of_stuff : length(h) + length(i)] # copies the keys and values of the map into 'g'
  j = [for k, l in local.list_of_stuff : "${k} is ${l}"]       # 'k' gets you the index, and 'l' gets you the value
  o = [for p in local.map_of_stuff : upper(p) if p != ""]      # you can add conditional 'if' in a 'for' expression

  # Here's a splat expression: an ultra-condensed 'for' expression; uses the '*' operator. It can turn something like this:
  q = [for r in local.list_of_stuff : r.id]
  # ...Into this:
  s = [local.list_of_stuff[*].id]

  # This is a Dynamic Block: lets you construct multiple repeatable blocks
  # Here's some example data:
  my_names = [{
    first = "jon"
    last  = "gorczyca"
    },
    {
      first = "andrew"
      last  = "gorczyca"
  }]
  # ...and then here's where you specify the block you want to make dynamic (creates 2 people):
  dynamic "my_people" {
    for_each = local.my_names
    content {
      first = my_names.value.first
      last  = my_names.value.last
    }
  }

  # Some built-in numeric functions:
  aa = abs(-12)
  ab = floor(4.5)
  ac = ceil(5.1)
  ad = log(10, 100)
  ae = min([5, 2, 8, 1])
  af = max([4, 2, 1, 0])
  ag = pow(3, 2)
  ah = signum(1)          # returns -1 if the number is negative, 1 if positive, and 0 if 0
  ai = parseint("56", 10) # parses the given string as a representation of an integer in the given base and returns the resulting number

  # Some built-in string functions:
  aj = chomp("hello\n")                                    # removes newline characters at the end of a string
  ak = format("Hello %s! There are %d lights", "Ander", 4) # returns a string by formatting multiple values according to a specification string
  al = formatlist("Hello %s!", ["jon", "andrew", "paige"]) # this will return: ["Hello jon!, "Hello andrew!", "Hello paige!"]
  ao = join(", ", ["foo", "bar"])                    # returns a string by concatenating a list of strings seperated by a given delimiter
  ap = lower("HELLO")                                # convert to lowercase
  aq = regex("^hey", "ey")                           # returns the matching substrings
  ar = regexall("^hey", "ey")                        # returns a list of all matches
  as = replace("hello world", "/w.*d/", "everybody") # hello everybody
  at = split(",", "foo,bar,baz")                     # returns a list by dividing a given string by the given delimiter
  au = strrev("hello")                               # reverses the characters in a string: olleh
  av = substr("hello world", 1, 4)                   # returns a substring: ello
  aw = title("hello world")                          # converts the first letter of each word to uppercase: Hello World
  ax = trim("?!hello?!", "!?")                       # removes the specified characters from the start and end of the given string
  ay = trimprefix("helloworld", "hello")             # removes the specified prefix; if no such one exists, the string is returned unchanged
  az = trimsuffix("helloworld", "world")             # reverse of trimprefix...
  ba = upper("hello")                                # reverse of lower()...

  # Some Collection functions:
  bb = alltrue(["true", true])              # returns true if all elements in a given collection are true or "true"; returns true if the collection is empty
  bc = anytrue([true, false])               # returns true if any element in a given collection is true or "true"; retruns false if the collection is empty
  bd = chunklist(["a", "b", "c", "d"], 2)   # [["a", "b"], ["c", "d"]]
  be = coalescelist(["a", "b"], ["c", "d"]) # takes any number of lists and returns the 1st one that isn't empty
  bf = coalesce("a", "b")                   # takes any number of arguments and returns the 1st one that isn't null or an empty string
  bg = compact(["a", "", "b", "c"])         # takes a list of strings and returns a new list with any empty strings removed
  bh = concat(["a", ""], ["b", "c"])        # takes 2 or more lists and combines them into a single list
  bi = contains(["a", "b", "c"], "a")
  bj = distinct(["a", "b", "a", "c", "d", "b"])                                               # returns a new list with any duplicates removed
  bk = element(["a", "b", "c"], 1)                                                            # retrieves a single element from a list; 0-base; also loops back around, so if you gave it something like 3, it would return: "a"
  bl = index(["a", "b", "c"], "b")                                                            # opposite of element()... 
  bm = flatten([["a", "b"], ["c"]])                                                           # ["a", "b", "c"]
  bn = keys({ a = 1, c = 2, d = 3 })                                                          # takes in a Map and returns a list of its keys
  bo = length(["a", "b"])                                                                     # determins the length of a given list, map, or string
  bp = lookup({ a = "ay", b = "bee" }, "a", "what?")                                          # returns the value of a single element from a map, given its key; if the given key does not exist, the given default value is returned instead
  bq = matchkeys(["i-123", "i-abc", "i-def"], ["us-west", "us-east", "us-east"], ["us-east"]) # ["i-abc", "i-def"]
  br = merge({ a = "b", c = "d" }, { e = "f", c = "z" })                                      # takes any number of maps or objects and returns a merged version of those maps or objects
  bs = one(["hello"])                                                                         # takes a list, set, or tuple with 0 or more elements. If it's empty, return null. If there is 1 element, return the element. Otherwise, an error is returned
  bt = range(0, 3, 1)                                                                         # generates a list of numbers using a start value, a limit value, and a step value
  bu = reverse([1, 2, 3])                                                                     # returns the list in reverse
  bv = setintersection(["a", "b"], ["b", "c"], ["b", "d"])                                    # ["b"] returns a single set containing all the elements the other sets have in common
  bw = setproduct(["development", "staging", "production"], ["app1", "app2"])                 # returns Cartesian Product
  bx = setsubtract(["a", "b", "c"], ["a", "c"])                                               # ["b"] returns a new set containing the elements from the first set that are not present in the second set
  by = setunion(["a", "b"], ["b", "c"], ["d"])                                                # ["d", "b", "c", "a"]
  bz = slice(["a", "b", "c", "d"], 1, 3)                                                      # ["b", "c"] 1st number is inclusive, 2nd is exclusive
  ca = sort(["e", "d", "a"])
  cb = sum([10, 13, 6, 4.5])
  cc = transpose({ "a" = ["1", "2"], "b" = ["2", "3"] }) # takes a map of lists of strings and transposes it so that the keys are the values and the values are the keys
  cd = values({ a = 3, c = 2, d = 1 })                   # takes a map and returns a list of its values
  ce = zipmap(["a", "b"], [1, 2])                        # {"a" = 1, "b" = 2} takes 2 lists and converts it into a single map

  # Some Encoding and Decoding Functions
  cf = base64encode("Hello World")
  cg = base64decode("sjdoirfjelfkd")
  ch = jsonencode("Hello World")
  ci = jsondecode("jdflkjeifrjedklf")
  cj = textencodebase64("Hello World")
  ck = csvdecode("jkldjfldkfjd")
  cl = yamlencode("Hello World")
  cm = yamldecode("jkdlfjelf")
  cn = base64gzip("Hello World")
  co = urlencode("https://helloworld.com")
  cp = textdecodebase64("jdlfkjdlfdkj")

  # Some filesystem functions
  cq = abspath("some/terraform/root")                                                # converts a given path into an absolute path: /home/user/some/terraform/root
  cr = dirname("foo/bar/baz.txt")                                                    # takes a given path and removes the last portion from it: foo/bar
  cs = pathexpand("~/.ssh/id_rsa")                                                   # takes a path that begins with a "~" and replaces the ~ with the current user's home directory path: /home/steve/.ssh/id_rsa
  ct = basename("foo/bar/baz.txt")                                                   # takes a path and removes all except the last portion: baz.txt
  cu = file("/Documents/hello.txt")                                                  # returns the contents of a given file as a string
  cv = fileexists("/Documents/hello.txt")                                            # determins whether a file exists at a given path
  cw = fileset("/Documents", "/Documents/*.txt")                                     # enumerates over a set of regular file names given a path and pattern
  cx = filebase64("/Documents/hello.txt")                                            # reads the contents of a file and returns it as a base64-encoded string: dlkjfdlkfjlsf
  cy = templatefile("/Documents/hello.txt", { port = 8080, ip_address = "1.0.0.0" }) # reads the file and renders its content as a template using supplied set of template variables

  # Some data and time functions
  cz = formatdate("DD MMM YYY hh:mm ZZZ", "2018-01-02T23:12:01Z") # converts a timestamp into a different time format: 02 Jan 2018 23:12 UTC
  da = timeadd("2017-11-22T00:00:00Z", "10m")                     # adds a duration to a timestamp
  db = timestamp()                                                # returns a UTC timestamp string in RFC 3339 format: 2018-05-13T07:44:12Z

  # Some hash and crypto functions
  dc = bcrypt("hello world")
  dd = md5("hello world")
  de = sha1("hello world")
  df = uuid("hello world")

  # Some IP Network functions
  dg = cidrhost("10.12.127.0/20", 16)         # calculates a full host IP address given a host number within a given IP network address prefix
  dh = cidrnetmask("172.16.0.0/12")           # converts an IPv4 address prefix given in CIDR notation into a subnet mask address
  di = cidrsubnet("172.16.0.0/12", 4, 2)      # calculates a subnet address within a given IP network address prefix
  dj = cidrsubnets("10.1.0.0/16", 4, 4, 8, 4) # calculates a sequence of consecutive IP address ranges within a particular CIRD prefix

  # Some type conversion functions
  dk = can(local.foo.bar)                          # returns true if the given expression suceeded w/o any errors; like a try/catch block
  dl = defaults()                                  # used with input variables whose type is an object or a collection of objects that include optional attributes
  dm = nonsensitive(sha256(var.sensitive_example)) # takes a sensitive value and returns a copy of the value with the sensitive marking removed, thereby exposing the sensitive value
  dn = sensitive(file("/Documents/hello.txt"))     # takes any value and returns a copy of it marked so that terraform will treat it as sensitive
  do = tobool("true")                              # converts its argument to a boolean value
  dp = tomap({ "a" = 1, "b" = 2 })                 # converts its argument to a map value
  dq = toset(["a", "b", "c"])                      # converts its argument to a set
  dr = tolist(["a", "b", 3])                       # converts its argument to a list
  ds = tonumber("1")                               # converts its argument to a number
  dt = tostring(true)                              # converts its argument to a string
  du = try(tostring(false), tonumber("3"))         # evaluates all arguments and returns the result of the 1st one that doesn't produce any errors

}

# This is for specifying a cloud provider profile EX: aws
# Note: if you intend to use multiple 'provider's and alternate between them using 'alias', you need to explicitly define all providers
# EX: if I want to switch between us-east and us-west using 'alias' I need to have defined 2 'provider's: 1 for east and 1 for west
provider "aws" {
  alias   = "west" # How to set an alternative provider
  profile = "default"
  region  = "us-east-1"

  # Here is how you use different IAM Roles and switch between them using the terraform console via workspaces
  assume_role = var.workspace_iam_roles[terraform.workspace]

  # How to escape special characters
  list_of_examples = ["\\", "\"", "$${}", "%%{}"]
}

# This is how you define data sources: they allow terraform to use information defined outside of terraform, defined by another separate terraform configuration, or modified by functions
# You reference data sources by preceeding the data source with: 'data.'
data "aws_ami" "web" {

  # Filters allow you to narrow down the selection of what kind of external resource you're trying to find
  # EX: available AWS ami's with the name: 'state' (this is ONLY for AWS!)
  filter {
    name   = "state"
    values = ["available"]
  }

  # This is how to reference your local backend
  config = {
    path = "${path.module}/.../terraform.tfstate"
  }
}

# This is how you would use your Packer to build an image
data "aws_ami" "packer_image" {
  //name_regex = "my-server-httpd"
  filter {
    name   = "name"
    values = ["my-server-httpd"]
  }
  owners = ["self"]
}

resource "aws_instance" "my_server" {
  ami           = data.aws_ami.packer_image.id
  instance_type = "t2.micro"
  tags = {
    Name = "Server-Apache-Packer"
  }
}

# Here's how you can include Vault as part of your terraform
data "vault_generic_secret" "aws_creds" {
  path = "secret/aws"
}

provider "aws" {
  region     = data.vault_generic_secret.aws_creds.data["region"]
  access_key = data.vault_generic_secret.aws_creds.data["aws_access_key_id"]
  secret_key = data.vault_generic_secret.aws_creds.data["aws_secret_access_key"]
}

# This is for provisioning an EC2 instance in aws
resource "aws_instance" "my_server" {
  count = 4 # basically saying: "I want to create 4 of these aws_instances"
  # 'count' can also take expressions, but must always be known before configuration and must also be a whole number
  ami           = "ami-087c17d1f30178315" # EX: The Amazon Linux 2 AMI ID number 
  instance_type = var.instance_type       # Value of input variable: instance_type
  tags = {
    Name = "MyServer-${local.project_name}" # Value of local variable: project_name
    # This is also how to do string concatenation/interpolation
    //Name = "Server ${count.index}"        # This is how to get the current value of 'count'
  }
  key_name = aws_key_pair.deployer.key_name # This is how you would reference a key pair with an EC2
  provider = aws.west                       # How to reference an alias provider
  depends_on = [
    aws_iam_role_policy.example # How to explicitly define a dependency for a resource
  ]

  # This is how to iterate over something using a for-loop with a Map
  for_each = {
    a_group       = "eastus"
    another_group = "westus2"
  }
  name     = each.key
  location = each.value

  # This is how to iterate over something using a for-loop with a List
  # Note: you can only use 1 for-loop per resource
  /*
    for_each = toset(["Todd", "James", "Alice", "Dottie"]) # toset() : constructor for a Set; removes any duplicates; all values in the list mush be of the same type
    name = each.key
    */

  # This is a lifecycle block: allows you to change what happens to a resource (create '+', update in-place '~', destroy '-')
  # create_before_destory (bool) : when replacing a resource '-/+', create the new resource first, then delete the old one: '+/-'
  # prevent_destroy (bool) : ensures a resource cannot be destoryed
  # ignore_changes (list of attributes) : don't change the resource (create, update, destroy) if a change occurs for the listed attributes
  lifecycle {
    create_before_destroy = true
  }

  # This is a timeout block that lets you control the timing of certain operations (EX: how long to create a resource, how long before it's deleted, etc.)
  timeouts {
    create = "60m"
    delete = "2h"
  }
}

# This is how you define a local command (local-exec): lets you execute local commands after a resource is provisioned
resource "aws_instance" "web" {
  provisioner "local-exec" {

    # REQUIRED
    command = "echo ${self.private_ip} >> private_ips.txt"

    # OPTIONAL
    working_dir = "src/main"
    interpreter = ["Powershell", "-Command"]
    environment = {
      KEY    = "fjkldsfjkdl;f;jl"
      SECRET = "kdlfj;anvcnvc"
    }
  }
}

# This is how you define a remote command (remote-exec): lets you execute remote commands after a resource is provisioned
# Supports ssh and winrm connection types
resource "aws_instance" "web" {
  provisioner "remote-exec" {

    # inline: list of command strings
    inline = [
      "puppet apply",
      "consul join ${aws_instance.web.private.ip}"
    ]

    # scripts: local scripts that will be copied to the remote instance and executed in order
    scripts = [
      "./setup-users.sh",
      "/home/andrew/Desktop/bootstrap"
    ]
  }
}

# This is how to use the file provisioner: used to copy files from our local machine to the remote provisioned instance
resource "aws_instance" "web" {

  # Copies the myapp.conf file to /dtc/myapp.conf
  provisioner "file" {

    # source: the local file we want to upload to the remote machine
    source = "conf/myapp.conf"

    # destination: where you want to upload the file on the remote machine
    destination = "/etc/myapp.conf"

    # This is a connection block: it tells a provisioner or resource how to establish a connection
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.host

      # Can also connect via bastion
      bastion_host        = ""
      bastion_host_key    = ""
      bastion_port        = ""
      bastion_user        = ""
      bastion_password    = ""
      bastion_private_key = ""
      bastion_certificate = ""
    }
  }

  # Copies the string in content into /tmp/file.log
  provisioner "file" {

    # content: a file or a folder
    content     = "ami used: ${self.ami}"
    destination = "/tmp/file.log"
  }
}

# The primary use-case for the null resource is as a do-nothing container for
# arbitrary actions taken by a provisioner.
# In this example, three EC2 instances are created and then a null_resource instance
# is used to gather data about all three and execute a single action that affects
# them all. Due to the triggers map, the null_resource will be replaced each time
# the instance ids change, and thus the remote-exec provisioner will be re-run.
resource "null_resource" "cluster" {

  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = join(",", aws_instance.cluster.*.id)
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = element(aws_instance.cluster.*.public_ip, 0)
  }

  provisioner "remote-exec" {

    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "bootstrap-cluster.sh ${join(" ", aws_instance.cluster.*.private_ip)}",
    ]
  }
}

# This is how to define a module: pre-made templates you can use to define whole infrastructures (EX: EC2's, VPC's, etc.)
# Remember to run 'terraform init' first before running so that it's included as part of the script
# This is useful for following best terraform conventions, speeding up your coding, and shortening the amount of options you have to include
# You can reference variables defined in modules by preceeding the variable name with: 'module.'
# parent modules can refer to things inside child modules, but not the other way around
module "vpc" {

  # format: <NAMESPACE>/<NAME>/<PROVIDER>
  source = "terraform-aws-modules/vpc/aws"
  # for private modules: <HOSTNAME>/<NAMESPACE>/<NAME>/<PROVIDER>
  # to configure private module access, you need to authenticate with Terraform Cloud via 'terraform login' first

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# This is how to use a Module from a different directory
module "aws_server" {
  source        = ".//aws_server"
  instance_type = "t2.micro"
}

# This is how to declare an output value: computed values after a 'terraform apply' is performed
# useful for getting information after provisioning is complete
output "public_ip" {
  value = aws_instance.my_server.public_ip # The public ip of the 'aws_instance' resource defined above
  //value = module.aws_server.public_ip                 # This is how to reference your own Module
  description = ""
  sensitive   = true # Makes it so that the output is not shown in your terminal
  //value = values(aws_instance.my_server)[*].public_ip # get the value of the public_ip for each of the 4 aws_instances'
  # values() : takes a Map and returns a List of the values for each keypair
}
 