# input variables
variable name { default = "dims" }
variable public_key_filename { }

# create resources
resource "digitalocean_ssh_key" "default" {
  name = "${var.name}-key"
  public_key = "${file(var.public_key_filename)}"
}

# output variables
output "keypair_id" {
  value = "${digitalocean_ssh_key.default.id}"
}
