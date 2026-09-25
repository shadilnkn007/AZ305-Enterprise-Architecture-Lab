# Module 05 - Network Security

## AZ-305 Enterprise Architecture Implementation Lab

This module implements centralized network security for the enterprise hub-and-spoke architecture.

The solution introduces:

- Azure Firewall
- Azure Firewall Policy
- Firewall network rules
- Network Security Groups (NSGs)
- User Defined Routes (UDRs)
- Centralized Internet egress
- Hub-to-spoke traffic inspection
- Spoke-to-spoke traffic inspection
- Hybrid traffic routing through the firewall

---

# 1. Architecture

The architecture created in the previous modules contains:

- Central India Hub
- South India Hub
- Production spokes
- NonProduction spoke
- Simulated on-premises network
- Site-to-site VPN

This module adds Azure Firewall to both regional hubs.

```text
                         Internet
                            |
                            |
                    +----------------+
                    | Azure Firewall |
                    |     CI Hub     |
                    +----------------+
                            |
                     Hub-CI VNet
                      /        \
                     /          \
                    /            \
             Prod-CI            NonProd-CI
             Spoke                Spoke
               |
          Application
            subnet


                         Internet
                            |
                            |
                    +----------------+
                    | Azure Firewall |
                    |     SI Hub     |
                    +----------------+
                            |
                     Hub-SI VNet
                            |
                         Prod-SI
                          Spoke
