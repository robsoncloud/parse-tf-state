import subprocess
import json


def parse_state_list(command):
    try:
        output = subprocess.check_output(command, shell=True)
        state_list = output
        
        return output
        #return list(filter(None,state_list))
    except subprocess.CalledProcessError as e:
        print("Error executing command: " + e.output)
        return []

state_list = parse_state_list("terraform show -json")

state = json.loads(state_list)
raw_resources = state["values"]["root_module"]["resources"]
#print(state["values"]["root_module"]["child_modules"][1])

for res in state["values"]["root_module"]["child_modules"]:
    #print(res["child_modules"])
    raw_resources.extend(res["resources"])
    if "child_modules" in res:
        for b in res["child_modules"]:
            if "resources" in b:
                print("ok")
                raw_resources.extend(b["resources"])
#print(state["values"]["root_module"]["child_modules"][1]["child_modules"][0]["resources"])
    
    
  #raw_resources.extend(res)
  #print(res["resources"])
  #if(res["resources"]["child_modules"]):
    #print("tem")
    #for res2 in res["resources"]["child_modules"]:
         #raw_resources.extend(res2["resources"])
         #print(res2["resources"])
  

properties = {
    "azurerm_resource_group": ["name","location"],
    "azurerm_virtual_network": ["name","address_space","dns_servers"],
    "azurerm_subnet": ["name","address_prefixes","virtual_network_name"],
    "azurerm_public_ip_prefix": ["name","sku","ip_prefix","prefix_length","zones"],
    "azurerm_firewall_policy_rule_collection_group": ["name"],
    "azurerm_virtual_network_peering": ["name","allow_forwarded_traffic","allow_gateway_transit","allow_virtual_network_access","use_remote_gateways"]
}

def extract_resource_values(resource):
    # Use regular expressions to extract the values for the attributes
    # that you are interested in from the state_info list
    resource_values = {}
    #print(resource['type'])
    if resource['type'] in properties:
        resource_values['type'] = resource['type']
       
        values = properties.get(resource['type'])
        for value in resource['values']:
            if value in values:
                resource_values[value] = resource['values'][value]
    if resource_values:
        return resource_values



def create_resource_table(resource_type, resources):
    # Create a markdown table for the specified resource type, with the resource
    # properties as the columns and the resource values as the rows
    table = "## " + resource_type + "\n"
    # Get the list of properties for the resource type
    resource_properties = properties[resource_type]
    # Generate the table header by iterating over the properties
    table_header = ["|"]
    for property in resource_properties:
        table_header.append(property)
        table_header.append("|")
    table += "".join(table_header) + "\n"
    # Generate the table row separator by iterating over the properties
    table_row_separator = ["|"]
    for _ in range(len(resource_properties)):
        table_row_separator.append("-|")
    table += "".join(table_row_separator) + "\n"
    # Generate the table rows by iterating over the resources
    for resource in resources:
        # Generate the table row by iterating over the properties
        table_row = ["|"]
        for property in resource_properties:
            # Convert the list of values to a string using an empty string as the separator
            property_values = resource[property]
            property_value = "".join(str(property_values))
            table_row.append(property_value)
            table_row.append("|")
        table += "".join(table_row) + "\n"
    return table

resources = []

# Iterate over the list of resources and print the resource type
for resource in raw_resources:
  item = extract_resource_values(resource)
  if item:
    resources.append(item)

# Group the resources by their type
resources_by_type = {}
for resource in resources:
    if resource["type"] not in resources_by_type:
        resources_by_type[resource["type"]] = []
    resources_by_type[resource["type"]].append(resource)

#print(resources_by_type)

# Create a markdown table for each group of resources
tables = []
for resource_type, resources in resources_by_type.items():
    table = create_resource_table(resource_type, resources)
    tables.append(table)

# Open the readme.md file in write mode
with open("readme.md", "w") as f:
    # Iterate over the markdown tables
    for table in tables:
        # Write the contents of the table to the file
        f.write(table)
