# Project Report: Automated Static Website Deployment Pipeline

**Project Title:** Implementation of a CI/CD Pipeline with Blue-Green Deployment Strategy  
**Date:** July 2026  
**Repository:** `Vikas-K11/cicd`

---

## 1. Executive Summary

This project demonstrates the design and implementation of a modern, production-grade DevOps pipeline for deploying a static web application. It leverages **GitHub Actions** for Continuous Integration and Continuous Deployment (CI/CD), **AWS S3** for website hosting, and **AWS Systems Manager (SSM)** for enabling a zero-downtime blue-green deployment strategy. Security and code quality are strictly enforced through automated static code analysis, vulnerability scanning, and end-to-end browser testing.

## 2. Introduction & Objectives

The primary objective of this project is to automate the software delivery lifecycle of a web application while ensuring high availability, robust security, and strict code quality standards. 

**Key Objectives:**
- Establish a fully automated Continuous Integration and Deployment pipeline.
- Implement a **Blue-Green deployment model** using AWS S3 and SSM to suit cloud environments with restricted IAM permissions (such as AWS Lab environments).
- Enforce strict quality gates using HTML/CSS/JS linting and Playwright end-to-end (E2E) testing.
- Integrate automated security scanning for vulnerabilities prior to deployment.

## 3. System Architecture

The architecture is designed to be lightweight, highly available, and resilient, avoiding the need for complex routing infrastructure.

- **Source Control**: GitHub Repository
- **CI/CD Orchestration**: GitHub Actions (`.github/workflows/pipeline.yml`)
- **Infrastructure Provisioning**: HashiCorp Terraform
- **Hosting**: Amazon S3 Buckets (Staging, Prod-Blue, Prod-Green) configured for public static website hosting.
- **State Management**: AWS SSM Parameter Store tracks the currently active production environment (`blue` or `green`).

### Architecture Flow:
1. **Trigger**: A developer pushes code to the `main` branch on GitHub.
2. **Continuous Integration**: GitHub Actions triggers the CI workflow, performing Dependency Installation, Linting, Playwright E2E Testing, and Security Scans.
3. **Staging Deployment**: Upon CI success, the pipeline syncs the built artifacts to the Staging S3 bucket.
4. **Production Deployment (Blue-Green)**: 
   - The pipeline queries AWS SSM to determine the *inactive* environment.
   - The new build is synchronized to the inactive S3 bucket.
   - A health check (smoke test) validates the new deployment.
   - Upon success, the SSM parameter is updated to swap traffic, completing the deployment with zero downtime.

## 4. Technology Stack

- **Frontend Application**: HTML5, CSS3, Vanilla JavaScript (bundled with Vite)
- **Infrastructure as Code (IaC)**: HashiCorp Terraform (`>= 1.2.0`)
- **Cloud Provider**: Amazon Web Services (S3, SSM)
- **CI/CD Engine**: GitHub Actions
- **Security & Vulnerability Scanning**: Aqua Security Trivy, npm audit
- **End-to-End Testing**: Playwright

## 5. Implementation Details

- **Infrastructure Provisioning**: Terraform code (`infra/terraform/main.tf`) declaratively defines three separate S3 buckets: `staging`, `prod-blue`, and `prod-green`. The buckets are explicitly configured with public read bucket policies to act as web servers.
- **Pipeline Workflow Steps**:
  - `build-and-test`: Sets up Node.js, installs dependencies, runs static linters, and executes Playwright E2E tests in a headless Chromium browser.
  - `security-scan`: Runs `npm audit` and Trivy filesystem scans to block deployments if high-severity CVEs (Common Vulnerabilities and Exposures) are found.
  - `deploy-staging`: Authenticates to AWS via GitHub Secrets (Access Keys) and uploads the build directory to the staging bucket.
  - `deploy-production`: Executes the custom bash script `deploy-blue-green.sh`, which programmatically handles the environmental switch and updates AWS SSM.

## 6. Security and Quality Assurance

- **Playwright Automation**: Validates that critical UI components render correctly, ensuring the end-user experience is not degraded by new updates.
- **Trivy File System Scanning**: Automatically scans the repository's configuration and dependencies for known CVEs before deployment.
- **Instant Rollback Capability**: A dedicated `rollback.sh` script is provided to instantly revert the SSM parameter to the previous bucket state, restoring the system in under 30 seconds if a production failure occurs.

## 7. Conclusion

The implemented CI/CD pipeline successfully automates the static website deployment process, eliminating manual intervention and significantly reducing the risk of human error. The custom Blue-Green deployment strategy ensures that production updates occur with zero downtime, even within restricted cloud environments. This project serves as a robust and scalable blueprint for modern web operations and automated software delivery.
