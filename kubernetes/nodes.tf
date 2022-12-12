#===================
# NODES

resource "azurerm_network_interface" "node" {
  count               = 3
  name                = "node-nic-${count.index}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  ip_configuration {
    name                          = "internal-${count.index}"
    subnet_id                     = azurerm_subnet.k8s.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "node" {
  count               = 3
  name                = "node-${count.index}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.node[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("${var.pub_key}")
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u adminuser -i '${self.private_ip_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' playbooks/install-ssh-key.yml"
  }
}


output "nodes-ip" {
  value = {
    for node in azurerm_linux_virtual_machine.node :
    node.name => node.private_ip_address
  }
}
#======= NODES ===