## Build

```
docker build -t data-backup-to-s3 .
```

## Run

```
## Config
docker run -d --env-file .env data-backup-to-s3
```
