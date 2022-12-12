resource "azurerm_network_interface" "control" {
  count = 3
  name                = "control-nic-${count.index}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  ip_configuration {
    name                          = "internal-${count.index}"
    subnet_id                     = azurerm_subnet.k8s.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "control" {
  count = 3
  name                = "control-${count.index}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.control[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  #user_data = base64encode(local.custom_data)

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.private_ip_address
      type        = "ssh"
      user        = "adminuser"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u adminuser -i '${self.private_ip_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' install-apache.yml"
  }
}

data "local_file" "public_ssh_key" {
  filename = "/root/.ssh/id_rsa.pub"
}


locals {
  custom_data = <<CUSTOM_DATA
  #!/bin/bash
   sudo -u ubuntu bash -c 'echo "${data.local_file.public_ssh_key.content}" >> ~/.ssh/authorized_keys'
  CUSTOM_DATA
  } 


output "control-ip" {
  value = {
    for control in azurerm_linux_virtual_machine.control:
    control.name => control.private_ip_address
  }
}
