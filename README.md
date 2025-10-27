# 🌍 terraform-training

This repository contains **Terraform learning materials, exercises, and production-style practice projects**.  
It is designed as part of the **Backend Training Plan** to help trainees build real-world skills in **Infrastructure as Code (IaC)** and **DevOps** using **Terraform** with AWS or GCP.

---

## 📘 Learning Overview

This Terraform training consists of **three progressive modules** and a **final hands-on practice**:

1. **Terraform Basics – Managing Infrastructure as Code**  
2. **Advanced Terraform – Variables, Modules, & State Management**  
3. **Optional: Terraform Cloud – Automation, Workspaces, and Integration**  
4. **Practice Project – Building Production-Ready Infrastructure**

Each module includes:
- 🎯 **Learning objectives**
- 🧱 **Exercises and examples**
- 🚀 **Hands-on projects**
- 📦 **Deliverables for reporting and review**  

---

## 🧠 Objectives

After completing this training, learners will be able to:

- Explain **Infrastructure as Code (IaC)** principles and Terraform's role in modern DevOps
- Define, deploy, and manage infrastructure using **Terraform declarative syntax**
- Organize reusable Terraform code using **variables, outputs, and modules**
- Configure and manage **Terraform state** both locally and remotely
- Implement **CI/CD automation** and Terraform Cloud workflows
- Build **multi-environment (dev, staging, prod)** infrastructure following best practices

---

## 🗂 Directory Structure

```
terraform-training/
│
├── learning/                    # Learning notes and module theory
│   ├── basics/
│   │   ├── module-01-getting-started/
│   │   └── module-02-environment-setup/
│   │
│   ├── advanced/
│   │   ├── module-01-variables-locals-outputs/
│   │   └── module-02-expressions-functions/
│   │
│   ├── cloud/                   # Optional Terraform Cloud module
│   │   ├── module-01-workspaces/
│   │   ├── module-02-automation/
│   │   └── module-03-cicd-integration/
│   │
│   └── README.md
│
├── exercises/                   # Short hands-on module tasks
│   ├── basics/
│   ├── advanced/
│   └── cloud/
│
├── practice/                    # End-to-end projects
│   ├── 10_core/
│   ├── 20_infra/
│   ├── 30_app/
│   └── envs/
│       ├── dev/
│       ├── stage/
│       └── prod/
│
├── docs/                        # Documentation and tracking
│   ├── progress-tracker.md
│   ├── epic-issues.md
│   ├── repo-standards.md
│   └── diagrams/
│
├── scripts/                     # Utility scripts for setup and automation
│   ├── init_env.sh
│   ├── plan_all.sh
│   ├── apply_all.sh
│   └── destroy_all.sh
│
└── .github/workflows/           # CI/CD pipelines for Terraform validation
    ├── terraform-lint.yml
    ├── terraform-validate.yml
    └── terraform-plan.yml
```

## 📚 Module Mapping (from Training Plan)

| Module | Description | Practice Outcome |
|:-------|:-------------|:-----------------|
| **Terraform Basics** | Managing Infrastructure as Code — core concepts, resources, data sources, S3/GCS static site | Deploy static website via Terraform |
| **Advanced Terraform** | Variables, modules, and state management — modularization and remote state | Reusable infrastructure and multi-env setup |
| **Terraform Cloud (Optional)** | Automation, workspaces, and integration with CI/CD tools | Remote execution via Terraform Cloud |
| **Practice Project** | Real-world production stack: VPC, ECS, Lambda, API Gateway, CI/CD | Complete modular Terraform architecture with multi-env support |

---

## 🧩 Issues & Progress Tracking

Each module and project is tracked using **GitHub Issues**:
- Each issue includes: goal, tasks, deliverables, and links to exercises
- Epic issues track completion for each learning phase:
  - `[Epic] Terraform Basics`
  - `[Epic] Advanced Terraform`
  - `[Epic] Terraform Cloud (Optional)`
  - `[Epic] Final Practice Project`

Progress summary and deliverables are documented in:  
📄 [`/docs/progress-tracker.md`](docs/progress-tracker.md)

---

## 🧰 Prerequisites

- **Terraform CLI** ([Download](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI** ([Docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)) or **GCP SDK**
- **Optional tools:**
  - [asdf](https://asdf-vm.com/) for version management
  - [tflint](https://github.com/terraform-linters/tflint)
  - [terraform-docs](https://terraform-docs.io/)  

---

## 🚀 Quick Start - `TODO`