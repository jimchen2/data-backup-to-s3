#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github_token> <s3_bucket_name>"
    exit 1
fi

TOKEN="$1"
S3_BUCKET="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIPNAME="github_repos_shallow_$TIMESTAMP.zip"
TEMP_DIR="github_repos_shallow_$TIMESTAMP"

# Create temporary directory
mkdir "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

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
    git clone --depth 1 "https://${TOKEN}@github.com/${clone_url#https://github.com/}" "$name"
done

# Go back to parent directory
cd ..

# Zip repositories
zip -r "$ZIPNAME" "$TEMP_DIR"

# Upload to S3
aws s3 cp "$ZIPNAME" "s3://$S3_BUCKET/$ZIPNAME"

echo "All repositories under 300 MB, modified in the last 24 hours, shallow cloned, zipped to $ZIPNAME, and uploaded to S3 bucket $S3_BUCKET"

# Clean up
rm -rf "$TEMP_DIR"
rm "$ZIPNAME"