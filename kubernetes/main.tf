# Create a resource group
resource "azurerm_resource_group" "k8s" {
  name     = "kubernetes-the-hard-way"
  location = "northeurope"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "k8s" {
  name                = "k8s-vnet"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  address_space       = ["10.240.0.0/16"]
}

resource "azurerm_subnet" "k8s"{
  name                 = "k8s-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.k8s.name
  address_prefixes     = ["10.240.0.0/24"]
}

# install cli
resource "null_resource" "install-cli-tools" {

  provisioner "local-exec" {
    command = "ansible-playbook playbooks/install-cli-tools.yml"
  }

  depends_on = [
    azurerm_linux_virtual_machine.control,
    azurerm_linux_virtual_machine.node
  ]

}

# generate the ansible inventory

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory"
  content = templatefile(
    "${path.module}/templates/ansible_inventory.tpl",
    {
      user     = "adminuser"
      prefix-controllers   = "control"
      prefix-nodes   = "node"
      nodes    = azurerm_linux_virtual_machine.node.*.private_ip_address,
      controllers = azurerm_linux_virtual_machine.control.*.private_ip_address
    }
  )
}
