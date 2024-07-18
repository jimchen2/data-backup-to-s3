# Use the official MongoDB image as the base
FROM mongo:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    awscli \
    git \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install mongodump (should already be included in the mongo image, but just in case)
RUN apt-get update && apt-get install -y mongodb-database-tools && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/jimchen2/data-backup-to-s3 .

# Make the scripts executable
RUN chmod +x backup-mongodb.sh backup-github.sh

# Create a wrapper script that sources environment variables and runs the backup scripts
RUN echo '#!/bin/bash\n\
source /app/.env\n\
/app/backup-mongodb.sh "$MONGODB_URI" "$MONGODB_BUCKET_NAME"\n\
/app/backup-github.sh "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME"' > /app/run_backups.sh \
    && chmod +x /app/run_backups.sh

# Add cron job
RUN echo "*/$BACKUP_PERIOD * * * * root /app/run_backups.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/backup-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log