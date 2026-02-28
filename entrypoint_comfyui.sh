#!/bin/bash
set -e

# Run the base image setup script
/usr/local/bin/setup_instance.sh &

# Start ComfyUI
cd /opt/ComfyUI
source venv/bin/activate
exec python main.py --listen 0.0.0.0 --port 8188 --enable-manager --enable-cors-header '*'