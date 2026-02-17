#!/bin/bash

# Define variables
REMOTE_USER="ubuntu"
REMOTE_HOST="62.234.178.73"
REMOTE_DIR="/var/www/html/"
LOCAL_DIR="build/web/"

echo "🚀 Starting Deployment..."

# 1. Build Flutter Web App
echo "📦 Building Flutter Web App..."
flutter build web --release --pwa-strategy=none

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Aborting deployment."
    exit 1
fi

# 2. Inject Killer Service Worker (Force update)
echo "💉 Injecting Killer Service Worker..."
cp web/flutter_service_worker.js build/web/flutter_service_worker.js

# 3. Deploy using Rsync
echo "📤 Syncing files to server..."
# Note: rsync determines update by size/mtime. The killer SW is new so it will overwrite the old one.
rsync -avz --progress "$LOCAL_DIR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Deployment Successful! 🎉"
    echo "🌍 Visit your site at http://$REMOTE_HOST"
else
    echo "❌ Deployment Failed!"
    exit 1
fi
