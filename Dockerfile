FROM alpine:3.18

# Set environment variables
ENV GITHUB_TOKEN=""
ENV MONGODB_URI=""
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV GITHUB_BUCKET_NAME=""
ENV MONGODB_BUCKET_NAME=""
ENV BACKUP_PERIOD=1440

# Install necessary packages
RUN apk add --no-cache \
    curl \
    git \
    zip \
    aws-cli \
    mongodb-tools \
    dcron \
    bash

# Clone the GitHub repository
RUN git clone https://github.com/jimchen2/data-backup-to-s3.git /app

# Make scripts executable
RUN chmod +x /app/backup-github.sh /app/backup-mongodb.sh

# Create a cron job file
RUN echo "*/$BACKUP_PERIOD * * * * /app/backup-github.sh $GITHUB_TOKEN $GITHUB_BUCKET_NAME" > /etc/crontabs/root
RUN echo "*/$BACKUP_PERIOD * * * * /app/backup-mongodb.sh $MONGODB_URI $MONGODB_BUCKET_NAME" >> /etc/crontabs/root

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD crond -f -d 8