FROM mongo:6.0

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    cpulimit \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Clone the GitHub repository
RUN git clone https://github.com/jimchen2/data-backup-to-s3.git /app

# Make scripts executable
RUN chmod +x /app/*.sh

# Set the run-backups script as the entry point
CMD ["/app/run-backups.sh"]