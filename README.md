# 🚀 AutoDeploy — Production-Style CI/CD Pipeline

A production-style CI/CD pipeline for a containerized FastAPI application, implementing automated code validation, Docker-based deployments, GitHub Actions, self-hosted runners, Nginx traffic routing, and Blue-Green deployment.

The project demonstrates how modern software can move from a developer's code commit to a validated and safely deployed production version through an automated pipeline.

---

## 🏗️ Architecture

```text
                         DEVELOPER
                             │
                             │ git push
                             ▼
                    GITHUB REPOSITORY
                             │
                             ▼
                    GITHUB ACTIONS
                             │
                             ▼
                    CI PIPELINE
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
                  RUFF             PYTEST
                    │                 │
                    └────────┬────────┘
                             │
                        CI PASSED
                             │
                             ▼
                  SELF-HOSTED RUNNER
                         (Mac)
                             │
                             ▼
                     DOCKER BUILD
                             │
                             ▼
                DETECT ACTIVE ENVIRONMENT
                             │
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
              BLUE ACTIVE        GREEN ACTIVE
                    │                 │
                    ▼                 ▼
              DEPLOY GREEN       DEPLOY BLUE
                    │                 │
                    └────────┬────────┘
                             │
                             ▼
                      HEALTH CHECK
                             │
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
                  FAIL              PASS
                    │                 │
                    ▼                 ▼
              STOP DEPLOYMENT     NGINX SWITCH
                                      │
                                      ▼
                                  PRODUCTION
```

---

## 🔄 CI/CD Workflow

The complete deployment lifecycle:

```text
Developer pushes code
        │
        ▼
GitHub Actions triggered
        │
        ▼
Install Python dependencies
        │
        ▼
Run Ruff linting
        │
        ▼
Run Pytest
        │
        ├─────────────── FAIL ──────────────► Pipeline stops
        │
        ▼
      PASS
        │
        ▼
Self-hosted runner executes deployment
        │
        ▼
Build Docker image
        │
        ▼
Detect active environment
        │
        ▼
Deploy to inactive environment
        │
        ▼
Run application health check
        │
        ├─────────────── FAIL ──────────────► Deployment aborted
        │
        ▼
      PASS
        │
        ▼
Switch Nginx traffic
        │
        ▼
New version becomes production
```

---

# ✨ Key Features

- Automated CI pipeline using GitHub Actions
- Python code quality checks using Ruff
- Automated unit and API testing using Pytest
- Docker-based application containerization
- Docker Compose for local orchestration
- Self-hosted GitHub Actions runner
- Automated Blue-Green deployment
- Nginx reverse proxy and traffic routing
- Application health checks before traffic switching
- Deployment failure protection
- Minimal downtime deployment strategy
- Automatic deployment triggered by Git pushes
- Git-based version tracking

---

# 🧰 Tech Stack

| Technology | Purpose |
|---|---|
| Python | Application development |
| FastAPI | Backend REST API |
| Pytest | Automated testing |
| Ruff | Linting and code quality |
| Git | Version control |
| GitHub | Source code hosting |
| GitHub Actions | CI/CD automation |
| Docker | Containerization |
| Docker Compose | Container orchestration |
| Nginx | Reverse proxy and traffic routing |
| Bash | Deployment automation |

---

# 📂 Project Structure

```text
cicd-task-api/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│   └── main.py
│
├── tests/
│   └── test_main.py
│
├── deployment/
│   └── blue_green_deploy.sh
│
├── nginx/
│   └── nginx.conf
│
├── DOCKERFILE
│
├── docker-compose.yml
│
├── requirements.txt
│
├── .gitignore
│
└── README.md
```

> The GitHub Actions self-hosted runner is intentionally maintained outside the Git repository to prevent runner binaries and dependencies from being committed to source control.

---

# 🧪 Continuous Integration

The CI pipeline runs automatically when code is pushed to the repository.

The pipeline performs:

### 1. Dependency Installation

The workflow sets up the Python environment and installs the required dependencies.

### 2. Code Quality

Ruff checks the project for code quality and formatting issues.

```bash
ruff check .
```

### 3. Automated Tests

Pytest executes the application's automated test suite.

```bash
python -m pytest
```

If linting or testing fails, the deployment stage does not execute.

```text
Ruff ❌
   │
   ▼
Pipeline Stops
   │
   ▼
Deployment Blocked
```

---

# 🐳 Docker

The application is packaged as a Docker image using the project's `DOCKERFILE`.

Docker provides a consistent runtime environment between development and deployment.

The deployment process builds an image using:

```bash
docker build -f DOCKERFILE -t cicd-task-api:<version> .
```

The application is then executed inside Docker containers.

---

# 🔵🟢 Blue-Green Deployment

The project uses a Blue-Green deployment strategy to reduce deployment risk and minimize downtime.

Two environments are maintained:

```text
Blue  → Port 8001
Green → Port 8002
```

Only one environment receives production traffic at a time.

### Example

Current production:

```text
Nginx
  │
  ▼
Blue :8001
Version 1
```

During deployment:

```text
Blue :8001
Version 1
   │
   │ Production traffic
   ▼

Green :8002
Version 2
   │
   │ New deployment
   ▼
Health Check
```

If the new version is healthy:

```text
Nginx
  │
  ▼
Green :8002
Version 2
```

The old Blue environment remains available for rollback.

---

# 🌐 Nginx Traffic Routing

Nginx acts as the reverse proxy and traffic controller.

Users access:

```text
localhost:8000
```

Nginx routes traffic to the currently active environment:

```text
Client
   │
   ▼
Nginx :8000
   │
   ├──► Blue :8001
   │
   └──► Green :8002
```

During deployment, the pipeline updates the Nginx upstream configuration and reloads Nginx after the new environment passes its health check.

---

# ❤️ Health Checks

Before switching production traffic, the deployment pipeline verifies that the new application instance is healthy.

Example:

```bash
curl --fail http://localhost:<target-port>/health
```

If the health check fails:

```text
New Environment
      │
      ▼
Health Check ❌
      │
      ▼
Deployment Stops
      │
      ▼
Existing Production Remains Active
```

If the health check succeeds:

```text
New Environment
      │
      ▼
Health Check ✅
      │
      ▼
Nginx Traffic Switch
      │
      ▼
New Version Production
```

This prevents an unhealthy application from immediately receiving production traffic.

---

# 🤖 Self-Hosted GitHub Actions Runner

The deployment stage runs on a self-hosted GitHub Actions runner.

The runner executes deployment commands on the machine where Docker and the deployment environment are available.

The runner is maintained separately from the source repository:

```text
~/actions-runner
```

while the application source code is maintained in:

```text
~/cicd-task-api
```

This separation prevents runner binaries and large dependencies from being accidentally committed to Git.

---

# 🔐 Deployment Safety

The deployment process follows a safety-first approach:

1. Validate source code
2. Run automated tests
3. Build Docker image
4. Detect inactive environment
5. Deploy new version
6. Perform health check
7. Switch traffic only after validation

If the new deployment fails before traffic switching:

```text
Existing Production
        │
        ▼
Remains Active
```

This reduces the risk of pushing broken code directly into production.

---

# 🚀 Running Locally

## Clone the repository

```bash
git clone https://github.com/padhiraj/cicd-task-api.git
cd cicd-task-api
```

## Install dependencies

```bash
pip install -r requirements.txt
```

## Run tests

```bash
python -m pytest
```

## Run linting

```bash
ruff check .
```

## Build Docker image

```bash
docker build -f DOCKERFILE -t cicd-task-api:blue .
```

## Start services

```bash
docker compose up -d
```

## Check running containers

```bash
docker ps
```

## Test application health

```bash
curl http://localhost:8000/health
```

---

# 📊 Deployment Flow

```text
┌─────────────┐
│   Developer │
└──────┬──────┘
       │
       │ git push
       ▼
┌─────────────────┐
│     GitHub      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Ruff + Pytest   │
└────────┬────────┘
         │
         │ PASS
         ▼
┌─────────────────┐
│ Docker Build    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Deploy Inactive │
│   Environment   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Health Check    │
└────────┬────────┘
         │
         │ PASS
         ▼
┌─────────────────┐
│ Nginx Switch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Production    │
└─────────────────┘
```

---

# 🎯 Engineering Concepts Demonstrated

This project demonstrates practical understanding of:

- Continuous Integration
- Continuous Deployment
- Infrastructure automation
- Automated testing
- Code quality automation
- Containerization
- Docker image management
- Reverse proxies
- Blue-Green deployment
- Health-based deployment validation
- Self-hosted CI/CD infrastructure
- Deployment failure handling
- Zero/minimal downtime deployment concepts

---

# 🔮 Future Improvements

Potential production-grade extensions include:

- Push Docker images to GitHub Container Registry
- Deploy to AWS, Azure, or GCP
- Add automated rollback
- Add deployment approvals
- Add GitHub Actions environments
- Add secrets management
- Add container image vulnerability scanning
- Add monitoring and observability
- Add centralized logging
- Add Slack or email deployment notifications
- Add deployment metrics
- Add infrastructure as code using Terraform
- Add Kubernetes-based deployments

---

# 👨‍💻 Author

**Padhiraj**

Built as a hands-on project to understand and implement modern CI/CD engineering practices.

---

⭐ If you found this project useful, consider starring the repository.
