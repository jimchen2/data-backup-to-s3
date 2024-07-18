from mongo:6.0

# Avoid prompts from apt
env DEBIAN_FRONTEND=noninteractive

# Install necessary packages
run apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    cpulimit \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
run curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Clone the GitHub repository
run git clone https://github.com/jimchen2/data-backup-to-s3.git /app

# Make scripts executable
run chmod +x /app/backup-github.sh /app/backup-mongodb.sh

# Create a new script for running backups
run echo '#!/bin/bash\n\
log_file="/var/log/backups.log"\n\
\n\
run_backup() {\n\
    echo "$(date): Running $1 backup" >> $log_file\n\
    if ! nice -n 19 cpulimit -l 100 $1 $2 $3; then\n\
        echo "$(date): $1 backup failed" >> $log_file\n\
    else\n\
        echo "$(date): $1 backup completed successfully" >> $log_file\n\
    fi\n\
}\n\
\n\
github_backup() {\n\
    while true; do\n\
        run_backup "/app/backup-github.sh" "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME"\n\
        echo "$(date): GitHub backup sleeping for $GITHUB_BACKUP_PERIOD minutes" >> $log_file\n\
        sleep $(($GITHUB_BACKUP_PERIOD * 60))\n\
    done\n\
}\n\
\n\
mongodb_backup() {\n\
    while true; do\n\
        run_backup "/app/backup-mongodb.sh" "$MONGODB_URI" "$MONGODB_BUCKET_NAME"\n\
        echo "$(date): MongoDB backup sleeping for $MONGODB_BACKUP_PERIOD minutes" >> $log_file\n\
        sleep $(($MONGODB_BACKUP_PERIOD * 60))\n\
    done\n\
}\n\
\n\
github_backup & \n\
mongodb_backup & \n\
\n\
wait' > /app/run-backups.sh && chmod +x /app/run-backups.sh

# Set the new script as the entry point
cmd ["/app/run-backups.sh"]