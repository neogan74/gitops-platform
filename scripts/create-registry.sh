#!/bin/bash

set -o errexit

# Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'

echo "🔧 Setting up local Docker registry..."

if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  echo "📦 Creating registry container..."
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
  echo "✅ Registry container created at localhost:${reg_port}"
else
  echo "✅ Registry container already running"
fi

# Connect the registry to the kind network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}" 2>/dev/null)" = 'null' ]; then
  echo "🔗 Connecting registry to kind network..."
  docker network connect "kind" "${reg_name}" 2>/dev/null || true
  echo "✅ Registry connected to kind network"
fi

echo "🎉 Local registry ready at localhost:${reg_port}"
