#!/bin/bash

# Define variables
REMOTE_USER="ubuntu"
REMOTE_HOST="62.234.178.73"

echo "🛡️ Updating Nginx Configuration..."
scp nginx.conf "$REMOTE_USER@$REMOTE_HOST:/tmp/nginx.conf"

# Execute remote commands to move config and reload nginx
echo "🔄 Reloading Nginx..."
ssh -t "$REMOTE_USER@$REMOTE_HOST" "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf && sudo nginx -t && sudo systemctl reload nginx"

if [ $? -eq 0 ]; then
    echo "✅ Nginx Configuration Updated Successfully! 🚀"
else
    echo "❌ Nginx Update Failed!"
    exit 1
fi
