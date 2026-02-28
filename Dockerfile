FROM 993cz8u0.c1.gra9.container-registry.ovh.net/hive-compute-public/base-ubuntu:latest

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    wget \
    curl \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI
RUN git clone https://github.com/Comfy-Org/ComfyUI.git /opt/ComfyUI

# Create venv and install Python dependencies (cu128 for RTX 5090)
WORKDIR /opt/ComfyUI
RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128 \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r manager_requirements.txt

# Give the ubuntu user ownership
RUN chown -R ubuntu:ubuntu /opt/ComfyUI

# Download Z-Image Turbo model files
RUN wget -q --show-progress -O /opt/ComfyUI/models/text_encoders/qwen_3_4b.safetensors \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
    && wget -q --show-progress -O /opt/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
    && wget -q --show-progress -O /opt/ComfyUI/models/vae/ae.safetensors \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"

# Add venv activation to bashrc
RUN echo 'source /opt/ComfyUI/venv/bin/activate' >> /root/.bashrc \
    && echo 'source /opt/ComfyUI/venv/bin/activate' >> /home/ubuntu/.bashrc

# Copy entrypoint script
COPY entrypoint_comfyui.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create workspace directory LAST so nothing overwrites it
# This is also created in entrypoint.sh as a safety net
RUN mkdir -p /home/ubuntu/workspace/.cache/huggingface/hub \
    && mkdir -p /home/ubuntu/workspace/.tmpdir \
    && mkdir -p /home/ubuntu/workspace/.pipcache \
    && chown -R ubuntu:ubuntu /home/ubuntu/workspace

# ComfyUI web UI port
EXPOSE 8188

CMD ["/usr/local/bin/entrypoint.sh"]