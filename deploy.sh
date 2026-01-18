#!/bin/bash

# Define variables
REMOTE_USER="ubuntu"
REMOTE_HOST="43.154.248.236"
REMOTE_DIR="/var/www/html/"
LOCAL_DIR="build/web/"

echo "🚀 Starting Deployment..."

# 1. Build Flutter Web App
echo "📦 Building Flutter Web App..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Aborting deployment."
    exit 1
fi

# 2. Deploy using Rsync
echo "📤 Syncing files to server..."
rsync -avz --progress "$LOCAL_DIR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Deployment Successful! 🎉"
    echo "🌍 Visit your site at http://$REMOTE_HOST"
else
    echo "❌ Deployment Failed!"
    exit 1
fi
