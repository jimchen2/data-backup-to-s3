#!/bin/bash

log_file="/var/log/backups.log"

run_backup() {
    echo "$(date): Running $1 backup" >> $log_file
    if ! cpulimit -l 100 $1 $2 $3; then
        echo "$(date): $1 backup failed" >> $log_file
    else
        echo "$(date): $1 backup completed successfully" >> $log_file
    fi
}

github_full_backup() {
    while true; do
        run_backup "/app/backup-github.sh" "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME"
        echo "$(date): GitHub full backup sleeping for $GITHUB_FULL_BACKUP_PERIOD minutes" >> $log_file
        sleep $(($GITHUB_FULL_BACKUP_PERIOD * 60))
    done
}

github_shallow_backup() {
    while true; do
        run_backup "/app/backup-github-shallow.sh" "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME"
        echo "$(date): GitHub shallow backup sleeping for $GITHUB_SHALLOW_BACKUP_PERIOD minutes" >> $log_file
        sleep $(($GITHUB_SHALLOW_BACKUP_PERIOD * 60))
    done
}

mongodb_backup() {
    while true; do
        run_backup "/app/backup-mongodb.sh" "$MONGODB_URI" "$MONGODB_BUCKET_NAME"
        echo "$(date): MongoDB backup sleeping for $MONGODB_BACKUP_PERIOD minutes" >> $log_file
        sleep $(($MONGODB_BACKUP_PERIOD * 60))
    done
}

github_full_backup &
github_shallow_backup &
mongodb_backup &

wait