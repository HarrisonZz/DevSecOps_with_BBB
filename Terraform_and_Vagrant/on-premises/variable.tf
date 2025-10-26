variable "vm_names" {
  description = "List of Vagrant VM hostnames"
  type        = list(string)
  default     = ["k3s-controlplane", "k3s-agent"]
}

variable "copy_script" {
  type    = string
  default = "copy_to_wsl.sh"
}
