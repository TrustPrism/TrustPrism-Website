#!/bin/bash

# Configuration: Update these variables with your Jetstream2 VM details
REMOTE_USER="tanvia"  # Or whatever user you use on Jetstream2
REMOTE_HOST=129.114.102.44
REMOTE_DIR="~/TrustPrism"

echo "=========================================================="
echo "🚀 Transferring TrustPrism to Jetstream2 VM"
echo "=========================================================="

if [ "$REMOTE_HOST" = "your-jetstream2-ip" ]; then
  echo "⚠️  Wait! You need to edit deploy.sh and update REMOTE_HOST with your VM's IP address."
  exit 1
fi

echo "Copying files using rsync..."
# Exclude node_modules and .git to save time and bandwidth
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'backend/node_modules' \
  --exclude 'frontend/node_modules' \
  --exclude 'deploy.sh' \
  ./ "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Transfer complete!"
  echo ""
  echo "To deploy on your Jetstream2 server, SSH into it and run:"
  echo "--------------------------------------------------------"
  echo "ssh $REMOTE_USER@$REMOTE_HOST"
  echo "cd $REMOTE_DIR"
  echo "docker compose up -d --build"
  echo "cat backup.sql | docker exec -i trustprism-db psql -U trustuser -d trustprism"
  echo "--------------------------------------------------------"
else
  echo "❌ Transfer failed. Check your SSH keys and IP address."
fi
