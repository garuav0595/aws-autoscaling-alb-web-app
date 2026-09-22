# Highly Scalable Web App — AWS Auto Scaling Group + ALB + Target Group

A complete, beginner-friendly build of a highly available, auto-scaling web application on AWS: an Application Load Balancer distributing traffic across an Auto Scaling Group of EC2 instances, with zero manual intervention during traffic spikes.

> 📖 Full write-up: [Building a Highly Scalable Web Application using AWS Auto Scaling Group, Target Group & Load Balancer](https://www.linkedin.com/pulse/building-highly-scalable-web-application-using-aws-auto-gaurav-khatri-4xp5c/) by **Gaurav Khatri**

## What problem this solves

A single server crashes when traffic spikes. This architecture automatically adds servers when traffic increases, removes them when it drops (saving cost), distributes traffic evenly, and keeps the app up even if one server fails.

## Technologies used

AWS EC2 · Application Load Balancer (ALB) · Target Groups · Auto Scaling Groups (ASG) · custom AMI · VPC

## Architecture, in plain terms

- **Load Balancer** = the host who greets traffic and distributes it across available servers
- **Target Group** = the pool of servers the load balancer sends traffic to
- **Auto Scaling Group** = opens more "tables" (instances) when busy, closes them when quiet
- **EC2 instances** = the servers actually handling requests

## Build phases

**Phase 1 — base infrastructure:** a VPC with public/private subnets across multiple AZs; a first EC2 instance (Amazon Linux 2 + Apache) configured and turned into a custom AMI so every future server is identical.

**Phase 2 — load balancer & target group:** a target group (`my-web-app-targets`, HTTP:80, health check on `/index.html` every 30s) behind an internet-facing ALB across multiple AZs, so traffic only ever reaches healthy instances.

**Phase 3 — auto scaling:**

- **Launch Template** (`my-web-app-launch-template`) — AMI, `t2.micro`, key pair, VPC + security group (HTTP:80, SSH:22), 8 GB gp3 EBS, an `EC2-CloudWatch-Role` instance profile, and the [`user-data.sh`](./user-data.sh) bootstrap script below
- **Auto Scaling Group** — min 2 / desired 2 / max 5 instances, with EC2 + ELB health checks

### Scaling policies

| Policy | Trigger |
|---|---|
| Scale out | +1 instance when CPU > 70% for 2 minutes |
| Scale in | −1 instance when CPU < 30% for 5 minutes |

## `user-data.sh`

Runs on every instance the ASG launches: installs and starts Apache, serves a page showing that instance's ID/AZ/private IP (handy for verifying load balancing is actually spreading traffic), and adds a `/health.html` endpoint for the target group health check.

## How it behaves in real time

| Scenario | What happens |
|---|---|
| Normal traffic | 2 instances, ~20–40% CPU, traffic split evenly |
| Traffic spike (3x) | CPU > 70% → ASG launches a new instance within 2–3 min → traffic spreads across 3 (up to 5) |
| Traffic returns to normal | CPU < 30% for 5 min → extra instances terminated → back to desired capacity of 2 |
| Instance failure | ALB health check fails → traffic stops routing there → ASG terminates and replaces it → zero downtime |

## Key metrics monitored

Target response time · healthy host count · request count · CPU utilization · network in/out

## Cost impact

| | Before ASG | After ASG |
|---|---|---|
| Setup | 5 servers running 24/7 | 2 servers normally, scale to 5 for ~4h/day |
| Monthly cost | ~$180 | ~$80 |
| Savings | — | **55%** |

## Security practices

- Security groups scoped to minimal required ports
- ALB in the public subnet, instances in the private subnet
- HTTPS-ready via AWS Certificate Manager
- Least-privilege IAM roles
- Regular AMI updates for security patches

## Key learnings

- High availability ≠ auto scaling — HA is redundancy, auto scaling is demand-based resource optimization
- Health checks are critical — bad config routes traffic to failed instances
- Cool-down periods prevent scaling "flapping"
- You can't optimize scaling policies without proper monitoring
- Always load-test scaling policies before relying on them (Apache Bench + CloudWatch alarms were used here)

## Future enhancements

Custom CloudWatch metric-based scaling · HTTPS via ACM · RDS database layer · multi-region deployment · CloudFront CDN · full Infrastructure as Code (Terraform/CloudFormation)

---

**Author:** [Gaurav Khatri](https://www.linkedin.com/in/gaurav-khatri-devops/) — DevOps Engineer @ Sarv.com | Kubernetes (EKS), Docker, GitOps & CI/CD
