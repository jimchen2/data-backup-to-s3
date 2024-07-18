#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github_token> <s3_bucket_name>"
    exit 1
fi

TOKEN="$1"
S3_BUCKET="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIPNAME="github_repos_$TIMESTAMP.zip"
TEMP_DIR="github_repos_$TIMESTAMP"

# Create temporary directory
mkdir "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Clone repositories
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100" | \
grep -o '"clone_url": "[^"]*' | awk -F'"' '{print $4}' | \
while read repo; do
    git clone "https://${TOKEN}@github.com/${repo#https://github.com/}"
done

# Go back to parent directory
cd ..

# Zip repositories
zip -r "$ZIPNAME" "$TEMP_DIR"

# Upload to S3
aws s3 cp "$ZIPNAME" "s3://$S3_BUCKET/$ZIPNAME"

echo "All repositories cloned, zipped to $ZIPNAME, and uploaded to S3 bucket $S3_BUCKET"

# Clean up
rm -rf "$TEMP_DIR"
rm "$ZIPNAME"