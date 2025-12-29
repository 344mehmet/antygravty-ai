# GPU Fine-tuning Dockerfile with Unsloth
FROM nvidia/cuda:12.1-devel-ubuntu22.04

# Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    python3.11-venv \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks
RUN ln -sf /usr/bin/python3.11 /usr/bin/python
RUN ln -sf /usr/bin/pip3 /usr/bin/pip

# Upgrade pip
RUN pip install --upgrade pip

# Install PyTorch with CUDA
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Unsloth (fast fine-tuning)
RUN pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"

# Install additional dependencies
RUN pip install \
    transformers>=4.36.0 \
    datasets>=2.16.0 \
    accelerate>=0.25.0 \
    peft>=0.7.0 \
    bitsandbytes>=0.41.0 \
    trl>=0.7.0 \
    huggingface_hub>=0.20.0

# Copy training script
COPY train.py .
COPY config.yaml .

# Create output directory
RUN mkdir -p /app/output /app/data

# Run training
CMD ["python", "train.py"]
