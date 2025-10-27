# 🧭 Git & Pull Request Conventions

This document defines the **commit message**, **branch naming**, and **pull request conventions** used in the `terraform-training` repository.

Consistent Git hygiene ensures:
- Clear traceability between issues, commits, and pull requests.
- Automated progress tracking and reporting.
- Readable project history across all Terraform modules.

---

## 🧱 1. Commit Message Convention

We follow a **hybrid of Conventional Commits** + **GitHub issue linking**.

### ✅ Format
```
<type>(<scope>): <short summary> (#<issue-number>)
```

### Example
```
feat(module-06): add static website example and outputs (closes #6)
```


---

### 🧩 Common Commit Types

| Type | Meaning | Example |
|:-----|:--------|:--------|
| **feat** | Add new feature, module, or functionality | `feat(module-01): add getting started notes (#1)` |
| **fix** | Fix a bug or issue | `fix(ci): correct terraform workflow trigger (#9)` |
| **docs** | Documentation-only changes | `docs(readme): update learning structure (#0)` |
| **chore** | Maintenance tasks, no functional change | `chore(repo): add .gitignore and scripts (#3)` |
| **refactor** | Code reorganization without behavior change | `refactor(practice): reorganize modules (#12)` |
| **style** | Code formatting, comments, or naming cleanup | `style(terraform): format with terraform fmt (#7)` |
| **ci** | CI/CD workflow updates | `ci(github): add terraform validate workflow (#10)` |

---

### 📎 Linking to Issues

Use GitHub keywords to automatically manage issue status:

| Keyword | Action | When to Use |
|:--------|:-------|:------------|
| `closes #6` | Closes issue when PR is merged | Work is completed |
| `fixes #6` | Same as closes (use for bug fixes) | Bug resolved |
| `resolves #6` | Same as closes | Feature done |
| `refs #6` / `related to #6` | Links but keeps issue open | Work in progress |

**Example sequence:**
```bash
feat(module-06): create S3 bucket config (refs #6)
feat(module-06): add static website deployment and outputs (closes #6)
```


---

## 🌿 2. Branch Naming Convention

Follow this format:
```
<type>/<short-description>
```

**Examples:**
```bash
feature/module-01-getting-started
feature/module-06-s3-static-website
fix/terraform-lint
docs/update-readme
```

| Prefix | Meaning |
|:-------|:--------|
| `feature/` | New module, file, or enhancement |
| `fix/` | Bug fix or correction |
| `docs/` | Documentation-only updates |
| `refactor/` | Refactor or restructure existing code |

---

## 🚀 3. Pull Request (PR) Convention

### 📋 PR Title Format
```
[<scope>] <short descriptive title> (#<issue-number>)
```

**Example:**
```
[module-06] Add static website deployment example (#6)
```


---

### 📝 PR Description Template

> This repo includes a built-in PR template: `.github/pull_request_template.md`

**Example usage:**

```markdown
## 🧩 Summary
Adds Terraform example and documentation for Module 06 – S3 Static Website.

## 🔗 Related Issue
Closes #6

## ✅ Changes
- Added `notes.md` for learning content
- Added Terraform configuration under `/examples/`
- Updated `README.md`

## 🧠 Testing
- [x] terraform init
- [x] terraform fmt -check
- [x] terraform validate
- [x] terraform apply
- [x] terraform destroy

## 📸 Evidence
Screenshot of successful `terraform apply`
```

### 🏷️ Labels

Use consistent labels on PRs and issues for tracking:

| Label | Purpose |
|:------|:--------|
| `module:basics` | For basic modules |
| `module:advanced` | For advanced Terraform topics |
| `module:cloud` | For Terraform Cloud modules |
| `type:docs` | Documentation or notes-only changes |
| `type:feature` | New feature or exercise |
| `status:review` | Ready for mentor/reviewer |
| `status:approved` | Approved and ready to merge |

---

## 🧩 4. Review & Merge Guidelines

| Step | Description |
|:-----|:------------|
| 1️⃣ | Open PR from your feature branch and link the related issue |
| 2️⃣ | Ensure CI (lint, validate) passes |
| 3️⃣ | Request review (if applicable) |
| 4️⃣ | Reviewer checks structure, code, docs, and evidence |
| 5️⃣ | Merge to dev or main |
| 6️⃣ | Issue auto-closes if closes #x present |

---

## 🧭 Example End-to-End Workflow

**Scenario:** Working on Issue #6 — S3 Static Website

```bash
# Step 1: Create branch
git checkout -b feature/module-06-s3-static-website

# Step 2: Make commits
git add .
git commit -m "feat(module-06): add static website Terraform config (refs #6)"
git commit -m "docs(module-06): add README and notes (closes #6)"

# Step 3: Push branch
git push origin feature/module-06-s3-static-website

# Step 4: Open PR
[module-06] Add static website Terraform example (#6)
```