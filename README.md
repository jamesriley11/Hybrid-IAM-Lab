# Hybrid IAM Lab - Active Directory & Azure Entra ID
A hybrid identity lab demonstrating MFA, conditional access, SSO, and PowerShell automation.

## Overview
This project demonstrates a hybrid identity and access management (IAM) environment, using on-premises Active Directory synced to Azure Entra ID. The focus of the lab is secure authentication, access control, and automation. Security controls such as MFA, Conditional Access, least-privilege RBAC, and Group Policies were implemented and validated through testing and automation.

## Objectives
- Build an on-prem Active Directory domain with domain-joined clients and users
- Sync identities to Azure Entra ID using Azure AD Connect
- Enforce MFA and Conditional Access policies
- Configure SAML-based Single Sign-On (SSO)
- Implement RBAC and least privilege access using Group Policy and role assignments
- Automate user provisioning and security auditing with PowerShell

## Architecture
![Architecture Diagram](Architecture.jpg)

## Technologies Used
- Windows Server 2022 (Active Directory)
- Windows 10
- Azure Entra ID
- Azure AD Connect
- Conditional Access & MFA
- SAML-based SSO
- PowerShell

## Key Outcomes
- Enforced adaptive authentication based on location and risk
- Reduced manual identity administration and auditing via automation
- Implemented least-privilege access design
- Identified and corrected identity configuration issues during deployment and testing

## Notes
This is a personal lab project built for learning and demonstration purposes. Free trials and evaluation images were used, and no production systems or real user data has been used.
