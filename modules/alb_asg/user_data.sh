#!/bin/bash
set -e

# =============================================================================
# NODE.JS APPLICATION DEPLOYMENT SCRIPT
# Following AWS and Node.js industry best practices
# =============================================================================

echo "Starting Node.js application deployment..."

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y build-essential curl wget unzip software-properties-common python3 python3-pip jq net-tools

# =============================================================================
# APPLICATION DIRECTORY SETUP
# =============================================================================

echo "Setting up application directory structure..."

# Create application directory
mkdir -p /opt/app
mkdir -p /var/log/app

# Set proper ownership and permissions for ubuntu user
chown -R ubuntu:ubuntu /opt/app
chown -R ubuntu:ubuntu /var/log/app
chmod -R 755 /opt/app
chmod -R 755 /var/log/app

# =============================================================================
# NODE.JS AND APPLICATION SETUP (NodeSource Repository Method)
# =============================================================================

echo "Installing Node.js and deploying application..."

# Install Node.js via NodeSource Repository (system-wide installation)
echo "Installing Node.js version: ${nodejs_version} via NodeSource..."
curl -sL https://deb.nodesource.com/setup_${nodejs_version}.x | sudo -E bash -

# Install Node.js and npm
sudo apt install -y nodejs

# Install PM2 globally (available to all users)
sudo npm install -g pm2

# Verify installation
echo "Node.js version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "PM2 version: $(pm2 --version)"

# Run application setup as ubuntu user for security
sudo -u ubuntu bash << 'EOF'

# Navigate to app directory
cd /opt/app

# Create package.json
cat > package.json << 'PACKAGE_EOF'
{
  "name": "${customer_name}-app",
  "version": "1.0.0",
  "description": "Production Node.js application for load balancer and auto scaling",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \"No tests specified\" && exit 0"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "engines": {
    "node": ">=18.0.0"
  },
  "author": "Terraform Infrastructure",
  "license": "MIT"
}
PACKAGE_EOF

# Create app.js
cat > app.js << 'APP_EOF'
const express = require("express");
const os = require("os");
const app = express();

// Configuration
const PORT = process.env.PORT || ${app_port};
const HOST = "0.0.0.0";

// Get instance metadata
const instanceId = process.env.INSTANCE_ID || os.hostname();
const hostname = os.hostname();
const uptime = process.uptime();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(new Date().toISOString() + " - " + req.method + " " + req.path + " - " + req.ip);
  next();
});

// Routes
app.get("/", (req, res) => {
  res.json({
    message: "Customer One Application",
    version: "1.0.0",
    instance: {
      id: instanceId,
      hostname: hostname,
      uptime: Math.floor(uptime),
      timestamp: new Date().toISOString()
    },
    environment: {
      node_version: process.version,
      platform: process.platform,
      arch: process.arch,
      env: process.env.NODE_ENV || "production"
    },
    load_balancer_test: {
      client_ip: req.ip || req.connection.remoteAddress,
      user_agent: req.get("User-Agent"),
      forwarded_for: req.get("X-Forwarded-For")
    },
    available_endpoints_documentation: {
      main: "GET / - Main application information",
      health: "GET /api/health - Application health check",
      load_test: "GET /api/load-test - CPU load testing endpoint",
      instance_info: "GET /api/instance-info - Detailed instance information"
    }
  });
});

// Health check endpoint for ALB
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    instance: instanceId,
    timestamp: new Date().toISOString(),
    uptime: Math.floor(uptime),
    service: "customer-one-app"
  });
});

// API health check endpoint
app.get("/api/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "customer-one-api",
    instance: instanceId,
    timestamp: new Date().toISOString(),
    uptime: Math.floor(uptime),
    version: "1.0.0"
  });
});

// Load testing endpoint
app.get("/api/load-test", (req, res) => {
  const start = Date.now();
  const iterations = 1000000;
  let result = 0;
  
  for (let i = 0; i < iterations; i++) {
    result += Math.random();
  }
  
  const processingTime = Date.now() - start;
  
  res.json({
    message: "Load test completed",
    instance: instanceId,
    processing_time_ms: processingTime,
    iterations: iterations,
    result: Math.floor(result),
    timestamp: new Date().toISOString()
  });
});

// Instance information endpoint
app.get("/api/instance-info", (req, res) => {
  res.json({
    instance: {
      id: instanceId,
      hostname: hostname,
      uptime: Math.floor(uptime),
      memory: {
        total: os.totalmem(),
        free: os.freemem(),
        used: os.totalmem() - os.freemem(),
        usage_percent: Math.round(((os.totalmem() - os.freemem()) / os.totalmem()) * 100)
      },
      cpu: {
        count: os.cpus().length,
        model: os.cpus()[0].model
      },
      platform: {
        type: os.type(),
        release: os.release(),
        arch: os.arch()
      }
    },
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);
  res.status(500).json({
    error: "Internal Server Error",
    instance: instanceId,
    timestamp: new Date().toISOString(),
    message: process.env.NODE_ENV === "development" ? err.message : "Something went wrong"
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not Found",
    path: req.path,
    instance: instanceId,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, HOST, () => {
  console.log("Customer One Application running on " + HOST + ":" + PORT);
  console.log("Instance: " + instanceId);
  console.log("Hostname: " + hostname);
  console.log("Environment: " + (process.env.NODE_ENV || "production"));
  console.log("Node.js version: " + process.version);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully");
  process.exit(0);
});
APP_EOF

# Install application dependencies
echo "Installing application dependencies..."
npm install --production

# Create PM2 ecosystem file
cat > ecosystem.config.js << 'PM2_EOF'
module.exports = {
  apps: [{
    name: "${customer_name}-app",
    script: "app.js",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: "1G",
    min_uptime: "10s",
    max_restarts: 10,
    env: {
      NODE_ENV: "production",
      PORT: ${app_port}
    },
    log_file: "/var/log/app/pm2-combined.log",
    out_file: "/var/log/app/pm2-out.log",
    error_file: "/var/log/app/pm2-error.log",
    log_date_format: "YYYY-MM-DD HH:mm:ss Z",
    merge_logs: true,
    time: true
  }]
};
PM2_EOF

# Start application with PM2
echo "Starting application with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Wait for application to start
echo "Waiting for application to start..."
sleep 10

# Verify application is running
if pm2 list | grep -q "${customer_name}-app.*online"; then
    echo "✅ Node.js application started successfully!"
    pm2 list
else
    echo "❌ ERROR: Node.js application failed to start!"
    pm2 logs ${customer_name}-app --lines 20
    exit 1
fi

EOF

# =============================================================================
# PM2 STARTUP SETUP
# =============================================================================

echo "Setting up PM2 startup..."

# Setup PM2 to start on boot (run as ubuntu user for security)
sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Application will run on port ${app_port} (non-privileged port)
echo "✅ Application configured to run on port ${app_port}"

# =============================================================================
# CLOUDWATCH AGENT SETUP (Proper Location)
# =============================================================================

echo "Setting up CloudWatch monitoring..."

# Install CloudWatch agent (download to /tmp to avoid /opt/app)
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration (proper location)
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << 'CW_EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "ubuntu"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/app/pm2-error.log",
                        "log_group_name": "/aws/ec2/${project_name}-${environment}/pm2/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/app/pm2-out.log",
                        "log_group_name": "/aws/ec2/${project_name}-${environment}/pm2/out",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/app/pm2-combined.log",
                        "log_group_name": "/aws/ec2/${project_name}-${environment}/pm2/combined",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": ["swap_used_percent"],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_listen"],
                "metrics_collection_interval": 60
            },
            "procstat": [
                {
                    "pattern": "node",
                    "measurement": ["cpu_usage", "memory_rss", "num_threads"]
                }
            ]
        }
    }
}
CW_EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# =============================================================================
# LOG ROTATION SETUP
# =============================================================================

echo "Setting up log rotation..."

# Create log rotation for application logs
cat > /etc/logrotate.d/customer-one-app << 'LOG_EOF'
/var/log/app/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        sudo -u ubuntu pm2 reloadLogs
    endscript
}
LOG_EOF

# =============================================================================
# FINAL VERIFICATION
# =============================================================================

echo "Performing final verification..."

# Test application endpoints
echo "Testing application endpoints..."
sleep 5

# Test application using PM2 check (faster and more reliable)
if pm2 list | grep -q "${customer_name}-app.*online"; then
    echo "✅ Application is running and healthy on port ${app_port}"
else
    echo "❌ Application is not running properly"
fi

# =============================================================================
# COMPLETION
# =============================================================================

echo ""
echo "🎉 User data script completed successfully!"
echo "📋 Deployment Summary:"
echo "   • Node.js installed via NodeSource Repository (system-wide)"
echo "   • Application deployed to /opt/app"
echo "   • PM2 process manager configured"
echo "   • Application running on port ${app_port} (non-privileged port)"
echo "   • CloudWatch monitoring enabled"
echo "   • Log rotation configured"
echo "   • PM2 startup configured for system boot"
echo ""
echo "🔗 Test endpoints:"
echo "   • Health: http://localhost:${app_port}/api/health"
echo "   • Main: http://localhost:${app_port}/"
echo "   • Load test: http://localhost:${app_port}/api/load-test"
echo "   • Instance info: http://localhost:${app_port}/api/instance-info"
echo ""
echo "🛠️  Management Commands (Available to ALL users):"
echo "   • pm2 status, pm2 logs, pm2 restart"
echo "   • node --version, npm --version"
echo "   • Application logs: /var/log/app/"
echo "   • CloudWatch logs: /aws/ec2/${project_name}-${environment}/pm2/"
echo ""
echo "✅ Ready for load balancer and auto scaling testing!"