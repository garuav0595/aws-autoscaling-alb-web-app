#!/bin/bash
# Launch Template user-data script: configures each new Auto Scaling
# Group instance identically and automatically on boot.

# Update system packages
yum update -y

# Install Apache web server
yum install -y httpd

# Start Apache and enable it to start on boot
systemctl start httpd
systemctl enable httpd

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create a custom index page with instance information
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Auto Scaling Demo</title>
<style>
body {
  font-family: Arial, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  margin: 0;
}
.container {
  background: white;
  padding: 40px;
  border-radius: 10px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  text-align: center;
}
h1 { color: #333; }
.info { margin: 20px 0; padding: 15px; background: #f0f0f0; border-radius: 5px; }
.label { font-weight: bold; color: #667eea; }
</style>
</head>
<body>
<div class="container">
  <h1>🚀 AWS Auto Scaling Web Application</h1>
  <p>This server is part of an Auto Scaling Group</p>
  <div class="info">
    <p><span class="label">Instance ID:</span> $INSTANCE_ID</p>
    <p><span class="label">Availability Zone:</span> $AVAILABILITY_ZONE</p>
    <p><span class="label">Private IP:</span> $PRIVATE_IP</p>
  </div>
  <p style="color: #28a745; font-weight: bold;">✅ Server is Running Successfully!</p>
</div>
</body>
</html>
EOF

# Create health check endpoint
echo "OK" > /var/www/html/health.html

# Install and configure CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent

# Configure log permissions
chmod -R 755 /var/www/html
chown -R apache:apache /var/www/html

# Restart Apache to apply all changes
systemctl restart httpd
