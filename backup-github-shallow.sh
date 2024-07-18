#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github_token> <s3_bucket_name>"
    exit 1
fi

TOKEN="$1"
S3_BUCKET="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIPNAME="github_repos_shallow_$TIMESTAMP.zip"
TEMP_DIR="/tmp/github_repos_shallow_$TIMESTAMP"

# Create temporary directory
mkdir -p "$TEMP_DIR" || { echo "Failed to create $TEMP_DIR"; exit 1; }
cd "$TEMP_DIR" || { echo "Failed to change to $TEMP_DIR"; exit 1; }

# Get the date 24 hours ago in ISO 8601 format
YESTERDAY=$(date -u -d "24 hours ago" '+%Y-%m-%dT%H:%M:%SZ')

# Clone repositories under 300 MB, modified in the last 24 hours
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100" | \
jq -r --arg yesterday "$YESTERDAY" '.[] | select(.size < 300000 and .pushed_at > $yesterday) | {name: .name, clone_url: .clone_url} | @base64' | \
while read -r repo; do
    decoded=$(echo "$repo" | base64 --decode)
    name=$(echo "$decoded" | jq -r '.name')
    clone_url=$(echo "$decoded" | jq -r '.clone_url')
    echo "Shallow cloning $name..."
    if ! git clone --depth 1 "https://${TOKEN}@github.com/${clone_url#https://github.com/}" "$name"; then
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
    echo "All repositories under 300 MB, modified in the last 24 hours, shallow cloned, zipped to $ZIPNAME, and uploaded to S3 bucket $S3_BUCKET"
else
    echo "Failed to upload to S3"
    rm -rf "$TEMP_DIR" "/tmp/$ZIPNAME"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR" "/tmp/$ZIPNAME"