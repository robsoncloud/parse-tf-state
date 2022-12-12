from diagrams import Cluster,Diagram
from diagrams.azure.network import Firewall
from diagrams.azure.network import VirtualNetworkGateways
from diagrams.azure.network import RouteTables

with Diagram("Simple Diagram", show=False):
    with Cluster("Azure"):
        with Cluster("hub"):
            with Cluster("FirewallSubnet - 172.16.2.0/24"):
                firewall = Firewall("fw - 172.16.2.4")
            with Cluster("GatewaySubnet"):
                gw = VirtualNetworkGateways("gw-iom")
                rt = RouteTables("rt-firewall")

        gw >> rt >> firewall
    with Cluster("IoM"):
        with Cluster("Continet 8"):
            fortigate = Firewall("Fortigate")
        fortigate >> gw
        
