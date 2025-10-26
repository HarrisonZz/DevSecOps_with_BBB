locals {
  project_dir = path.module
  wsl_home    = "/home/harrison" # 改成你 WSL 裡的帳號
}

resource "null_resource" "vagrant_up" {
  provisioner "local-exec" {
    command     = "vagrant up"
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "vagrant destroy -f"
    working_dir = path.module
  }

  provisioner "local-exec" {
    command = "powershell -Command \"Set-NetIPInterface -Forwarding Disabled -InterfaceAlias '乙太網路'\""
  }

  provisioner "local-exec" {
    command = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/setup-nat.ps1"
  }

}

resource "null_resource" "generate_ssh_config" {
  depends_on = [null_resource.vagrant_up]

  provisioner "local-exec" {
    command = "vagrant ssh-config > .ssh_config"
  }
}

resource "null_resource" "copy_to_wsl" {
  depends_on = [null_resource.generate_ssh_config]
  provisioner "local-exec" {
    command = "wsl bash ./scripts/${var.copy_script} ${join(" ", var.vm_names)}"
  }
}
