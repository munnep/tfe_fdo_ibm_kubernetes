from diagrams import Cluster, Diagram, Edge
from diagrams.ibm.general import IBMContainers
from diagrams.ibm.network import Vpc, Subnet, PublicGateway, Gateway
from diagrams.ibm.storage import ObjectStorage
from diagrams.ibm.data import Caches, DataServices
from diagrams.ibm.user import User

# Variables
title = "TFE Active-Active Deployment on IBM Kubernetes Service (IKS)"
outformat = "png"
filename = "diagram/diagram_tfe_kubernetes"
direction = "TB"

with Diagram(
    name=title,
    direction=direction,
    filename=filename,
    outformat=outformat,
) as diag:
    user = User("User")

    with Cluster("IBM Cloud"):
        # Managed Regional Services (Outside VPC)
        cos = ObjectStorage("Cloud Object Storage\n(TFE State & Assets)")
        postgres = DataServices("Cloud Databases\nfor PostgreSQL (HA)")
        redis = Caches("Cloud Databases\nfor Redis (HA)")

        with Cluster("IBM VPC (tfe-vpc)"):
            pgw = PublicGateway("Public Gateway")
            
            with Cluster("Subnet: 10.10.10.0/24 (Zone 1)"):
                iks = IBMContainers("IKS Cluster\n(TFE Active-Active Pods)")
                postgres_vpe = Gateway("PostgreSQL VPE Gateway")
                redis_vpe = Gateway("Redis VPE Gateway")

    user >> Edge(label="HTTPS (Ingress)") >> iks
    iks >> Edge(label="Private Link") >> postgres_vpe
    iks >> Edge(label="Private Link") >> redis_vpe
    iks >> Edge(label="S3 HMAC") >> cos

    postgres_vpe >> Edge(color="blue", style="dashed") >> postgres
    redis_vpe >> Edge(color="blue", style="dashed") >> redis

diag
