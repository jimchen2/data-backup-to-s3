## Updates

No longer used. Use Lambda functions for backup instead.

## Build

```
docker build -t jimchen2/data-backup-to-s3 .
```

## Run

```
## Config
docker run -d --restart always --env-file .env jimchen2/data-backup-to-s3
```
