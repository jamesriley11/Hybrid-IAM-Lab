# Hybrid Identity & Access Management Lab

## Overview
This lab is a hybrid Identity and Access Management (IAM) environment designed to simulate real-world enterprise identity architecture. It utilises Active Directory and Microsoft Entra ID for identity management, PowerShell for scripting and automation, and modern access controls including Multi-Factor Authentication (MFA), Conditional Access (CA) and SAML-based Single-Sign On (SSO). The environment mirrors common enterprise IAM patterns, identity flows, and access control mechanisms.


## Architecture Overview
The environment consists of two virtual machines: a domain controller (DC01) hosting Active Directory, and a domain-joined client device  (Client01) used to access domain and cloud resources. An Entra ID tenant was established to provide cloud-based identity services, with Azure AD Connect configured to synchronise identities from DC01 using Password Hash Synchronisation (PHS) 

Within Entra ID, MFA, Conditional Access and SAML-based SSO were implemented to control access to cloud resources. PowerShell scripts were also developed to automate identity-related tasks such as user provisioning and privileged role auditing, with selected scripts executed automatically via Windows Task Scheduler.

A high-level architecture diagram is provided below to illustrate identity and authentication flows.
([Architecture](docs/Images/Architecture.jpg))


## Identity Design & Lifecycle
In this IAM environment, user identities are provisioned on-premises via an automated PowerShell user creation script [Create User](Scripts/Create%20User.ps1) and placed within a dedicated "Employees" Organisation Unit (OU). Client devices are domain-joined to enforce centralised identity controls, group policies and access to domain resources. 

Azure AD Connect is used to synchronise identities between the on-premises domain and the Entra ID tenant, with Password Hash Synchronisation (PHS) configured to enable cloud authentication. During implementation, password synchronisation initially failed due to the Entra sync service account lacking the "Replicating Directory Changes" and "Replicating Directory Changes All" permissions with Active Directory. Granting these permissions resolved the synchronisation issue and restored expected behaviour.

User lifecycle events such as departmental or role changes are handled through group membership updates, where users are removed from preliminary access groups (e.g., "G-DEPARTMENT All Users") and added to appropriate role-based groups. Once an account is no longer required, the user is removed from access groups (excluding the default "Domain Users"), disabled, and moved to a designated "Disabled Users" OU to maintain directory hygiene and prevent unauthorised access.


## Access Controls
### Conditional Access & MFA
sdfsdf

### SSO Implementation
sdfsdf

### RBAC, Least Privilege and Group Policies
sdfsdf


## Automation & Scripting
sdfsdf


## Outcomes & What This Demonstrated
sdasasd


## Challenges, Limitations & Lessons Learned
asdsad


## Future Improvements
