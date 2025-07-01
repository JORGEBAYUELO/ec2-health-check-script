# EC2 Health Check & Alert Script (DevOps PoC)

This proof-of-concept Bash script monitors the health of all running EC2 instances in a specified AWS region. If any instance is in an unhealthy state (based on system or instance status), the script sends an alert via **AWS SNS**.

## 🚀 What It Does

- Queries all running EC2 instances in a given region
- Checks:
  - ✅ System Status (AWS infrastructure)
  - ✅ Instance Status (EC2 OS and network)
- Sends alert via AWS SNS if any instances are unhealthy
- Can be fully automated using `cron`

---

## 📸 Screenshot

![EC2 Health Check Screenshot](./green_and_red_status.png)

![EC2 Email Notification Screenshot](./email_notification.png)

![EC2 Email Notification Message Screenshot](./email_notification_message.png)

---

## 🛠️ Requirements

- AWS CLI configured with access to EC2 and SNS
- IAM permissions:
  - `ec2:DescribeInstances`
  - `ec2:DescribeInstanceStatus`
  - `sns:Publish`
- At least one EC2 instance running

---

## ⚙️ Setup Instructions

### 1. Configure AWS CLI (if not done already)

```bash
aws configure
```

### 2. Create SNS Topic

```bash
aws sns create-topic --name ec2-health-alerts
```

### 3. Subscribe Your Email

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:<your-region>:<your-account-id>:ec2-health-alerts \
  --protocol email \
  --notification-endpoint your@email.com
```

📧 Confirm the subscription via the email you receive.

## ▶️ Usage

```bash
chmod +x ec2_health_check.sh
./ec2_health_check.sh us-east-1
```

## ⏰ Automate with Cron

To run everyday at 6 PM:

```bash
crontab -e
```

Add:

```bash
0 18 * * * /path/to/ec2_health_check.sh us-east-1 >> /var/log/ec2_health.log 2>&1
```

## 💡 Why This Project?

As part of my journey into DevOps, I built this project to simulate real-world tasks like:

- Infrastructure monitoring

- Health checks and alerting

- Using AWS CLI, Bash, and automation tools

- Thinking proactively about infrastructure reliability

## 📫 Contact

This project was developed by [Jorge Bayuelo](https://github.com/JORGEBAYUELO).

Feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/jorge-bayuelo/)!
