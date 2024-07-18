#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <github_token> <s3_bucket_name> <backup_type>"
    exit 1
fi

TOKEN="$1"
S3_BUCKET="$2"
BACKUP_TYPE="$3"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIPNAME="github_repos_${BACKUP_TYPE}_$TIMESTAMP.zip"
TEMP_DIR="/tmp/github_repos_${BACKUP_TYPE}_$TIMESTAMP"

# Create temporary directory
mkdir -p "$TEMP_DIR" || { echo "Failed to create $TEMP_DIR"; exit 1; }
cd "$TEMP_DIR" || { echo "Failed to change to $TEMP_DIR"; exit 1; }

# Set clone options based on backup type
if [ "$BACKUP_TYPE" = "shallow" ]; then
    CLONE_OPTS="--depth 1"
    # Get the date 24 hours ago in ISO 8601 format
    YESTERDAY=$(date -u -d "24 hours ago" '+%Y-%m-%dT%H:%M:%SZ')
    JQ_FILTER=".[] | select(.size < 300000 and .pushed_at > \"$YESTERDAY\") | {name: .name, clone_url: .clone_url} | @base64"
else
    CLONE_OPTS=""
    JQ_FILTER=".[] | select(.size < 300000) | {name: .name, clone_url: .clone_url} | @base64"
fi

# Clone repositories
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100" | \
jq -r "$JQ_FILTER" | \
while read -r repo; do
    decoded=$(echo "$repo" | base64 --decode)
    name=$(echo "$decoded" | jq -r '.name')
    clone_url=$(echo "$decoded" | jq -r '.clone_url')
    echo "Cloning $name..."
    if ! git clone $CLONE_OPTS "https://${TOKEN}@github.com/${clone_url#https://github.com/}" "$name"; then
        echo "Failed to clone $name, skipping..."
    fi
done

# Check if any repositories were cloned
if [ -z "$(ls -A "$TEMP_DIR")" ]; then
    echo "No repositories were cloned successfully. Exiting."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create zip file in /tmp
cd /tmp || { echo "Failed to change to /tmp"; exit 1; }
if ! zip -r "$ZIPNAME" "${TEMP_DIR##*/}"; then
    echo "Failed to create zip file"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Upload to S3
if aws s3 cp "$ZIPNAME" "s3://$S3_BUCKET/$ZIPNAME"; then
    echo "All repositories under 300 MB $([[ "$BACKUP_TYPE" = "shallow" ]] && echo ", modified in the last 24 hours,") cloned, zipped to $ZIPNAME, and uploaded to S3 bucket $S3_BUCKET"
else
    echo "Failed to upload to S3"
    rm -rf "$TEMP_DIR" "/tmp/$ZIPNAME"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR" "/tmp/$ZIPNAME"
