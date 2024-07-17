# Use the official MongoDB image as the base image
FROM mongo:latest

# Install necessary tools
RUN apt-get update && apt-get install -y \
    awscli \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Create a backup script
RUN echo '#!/bin/bash\n\
DATE=$(date +%Y-%m-%d)\n\
BACKUP_FILE="/tmp/mongodb_backup_$DATE.gz"\n\
mongodump --uri="$MONGODB_URI" --gzip --archive="$BACKUP_FILE"\n\
aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET_NAME/mongodb_backups/"\n\
rm "$BACKUP_FILE"' > /backup.sh \
&& chmod +x /backup.sh

# Set up cron job to run the backup script daily at midnight
RUN echo "0 0 * * * /backup.sh" | crontab -

# Start MongoDB and cron
CMD mongod --bind_ip_all & cron && tail -f /dev/null

# Set restart policy
LABEL com.docker.compose.restart_policy="always"