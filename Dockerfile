# Use an official Ubuntu as a parent image
FROM ubuntu:latest

# Set environment variables
ENV GITHUB_TOKEN=""
ENV MONGODB_URI=""
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV GITHUB_BUCKET_NAME=""
ENV MONGODB_BUCKET_NAME=""
ENV BACKUP_PERIOD=1440

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zip \
    awscli \
    mongodb-org-tools \
    cron

# Clone the GitHub repository
RUN git clone https://github.com/jimchen2/data-backup-to-s3.git /app

# Make scripts executable
RUN chmod +x /app/backup-github.sh /app/backup-mongodb.sh

# Create a cron job file
RUN echo "*/$BACKUP_PERIOD * * * * /app/backup-github.sh $GITHUB_TOKEN $GITHUB_BUCKET_NAME" > /etc/cron.d/backup-cron
RUN echo "*/$BACKUP_PERIOD * * * * /app/backup-mongodb.sh $MONGODB_URI $MONGODB_BUCKET_NAME" >> /etc/cron.d/backup-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/backup-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
