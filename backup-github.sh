#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github_token> <s3_bucket_name>"
    exit 1
fi

TOKEN="$1"
S3_BUCKET="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIPNAME="github_repos_$TIMESTAMP.zip"

# Clone repositories
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100" | \
grep -o '"clone_url": "[^"]*' | awk -F'"' '{print $4}' | \
while read repo; do
    git clone "$repo"
done

# Zip repositories
zip -r "$ZIPNAME" *

# Upload to S3
aws s3 cp "$ZIPNAME" "s3://$S3_BUCKET/$ZIPNAME"

echo "All repositories cloned, zipped to $ZIPNAME, and uploaded to S3 bucket $S3_BUCKET"

# Clean up
rm "$ZIPNAME"
