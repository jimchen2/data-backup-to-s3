#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <mongodb_uri> <s3_bucket_name>"
    exit 1
fi

MONGODB_URI="$1"
S3_BUCKET_NAME="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/tmp/mongodb_backup_$TIMESTAMP.gz"

# Perform MongoDB backup
mongodump --uri="$MONGODB_URI" --gzip --archive="$BACKUP_FILE"

# Upload to S3
aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET_NAME/mongodb_backup_$TIMESTAMP.gz"

# Clean up
rm "$BACKUP_FILE"

echo "MongoDB backup completed and uploaded to S3 bucket $S3_BUCKET_NAME as mongodb_backup_$TIMESTAMP.gz"
