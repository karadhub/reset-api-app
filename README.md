# Mahad DevOps Challenge

This repo implements all tasks with a minimal, runnable setup you can finish in ~30 minutes.

- Task 1: Node.js API + Docker + CI to build/push/run container
- Task 2: Terraform to provision AWS EC2 with Prometheus Node Exporter
- Task 3: Jenkins Docker image conflict troubleshooting

## Prereqs

- Docker Desktop installed (you mentioned it's already installed)
- Git + GitHub repo
- Optional: AWS account + IAM credentials for Terraform

---

## Task 1 – CI/CD + Containerization

### Run locally (no Docker)

```powershell
# from repo root
npm install
npm start
# open another shell
curl http://localhost:3000/health
curl http://localhost:3000/
```

### Docker build and run locally

```powershell
# build
docker build -t mahad/hello:local .
# run
docker run -d --rm -p 3000:3000 --name mahad mahad/hello:local
# test
curl http://localhost:3000/health
curl http://localhost:3000/
# stop
docker stop mahad
```
<img width="421" height="159" alt="image" src="https://github.com/user-attachments/assets/c4ab748e-730e-434c-a8ea-cd39e2780354" />

### CI with GitHub Actions (GHCR by default)

1. Push this repo to GitHub.
2. Ensure Actions is enabled.
3. On push to main, workflow builds and pushes to GHCR: `ghcr.io/<owner>/<repo>:<tag>` and runs a simple health check.

To use Docker Hub instead of GHCR:

- In repo Settings > Secrets and variables > Actions, add:
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN` (create a Docker Hub access token)
- Uncomment the Docker Hub login step in `.github/workflows/ci.yml` and change `images:` to `docker.io/<your-username>/<repo>`.

---

## Task 2 – Infrastructure & Monitoring (AWS Terraform)

Creates a t2.micro Ubuntu EC2 with Node Exporter (port 9100).

### Configure AWS creds

```powershell
$env:AWS_ACCESS_KEY_ID = "<your-access-key>"
$env:AWS_SECRET_ACCESS_KEY = "<your-secret>"
$env:AWS_DEFAULT_REGION = "us-east-1"  # or update terraform variable
```

### Provide SSH key and apply

```powershell
# path to your public key (Windows example)
$pub = "$HOME/.ssh/id_rsa.pub"
cd terraform/aws
terraform init
terraform apply -auto-approve -var "key_name=mahad-key" -var "public_key_path=$pub"
```

Terraform output prints `public_ip`.

Security group opens ports 22 and 9100. Verify:

```powershell
curl http://<public_ip>:9100/metrics | Select-String node_cpu_seconds_total -SimpleMatch
```

### Grafana connection (3 lines)

- Add Prometheus as a data source: URL http://<public_ip>:9090 (assumes a Prometheus server scraping the EC2’s `:9100`).
- In your Prometheus server, add a scrape job: `- targets: ['<public_ip>:9100']`.
- Import Grafana dashboard “Node Exporter Full” (e.g., 1860) to visualize metrics.

---

## Task 3 – Troubleshooting

Jenkins error: `docker: conflict: unable to delete image ... image is being used by stopped container`.

Fix quickly:

```powershell
# list who blocks the image
docker ps -a --filter ancestor=<image> --format "{{.ID}}\t{{.Image}}\t{{.Names}}"
# remove stopped containers using that image
docker container prune --filter "until=24h" -f
# if still present, force remove those containers then the image
docker rm -f <container_id>
docker rmi -f <image_id>
```

Prevention in Jenkins pipeline:

- Always run with `--rm` or `--name` and stop/remove containers after tests.
- Add cleanup stage: `docker ps -aq --filter ancestor=$IMAGE | xargs -r docker rm -f` then `docker rmi -f $IMAGE`.
- Prefer unique tags per build (Git SHA) to avoid tag reuse conflicts.

---

## Notes

- The CI workflow uses GHCR by default. Switch to Docker Hub by uncommenting the login step and adjusting image name.
- Terraform scripts are basic and for demo. Destroy when done:

```powershell
cd terraform/aws
terraform destroy -auto-approve -var "key_name=mahad-key" -var "public_key_path=$pub"
```
