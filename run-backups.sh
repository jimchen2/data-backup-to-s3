#!/bin/bash

log_file="/var/log/backups.log"

run_backup() {
    echo "$(date): Running $1 backup" >> $log_file
    if ! cpulimit -l 100 $2 $3 $4 $5; then
        echo "$(date): $1 backup failed" >> $log_file
    else
        echo "$(date): $1 backup completed successfully" >> $log_file
    fi
}

github_backup() {
    local counter=0
    while true; do
        if [ $counter -eq 0 ]; then
            run_backup "GitHub full" "/app/backup-github.sh" "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME" "full"
        else
            run_backup "GitHub shallow" "/app/backup-github.sh" "$GITHUB_TOKEN" "$GITHUB_BUCKET_NAME" "shallow"
        fi

        counter=$((counter + 1))
        if [ $counter -ge $GITHUB_FULL_BACKUP_FREQUENCY ]; then
            counter=0
        fi

        echo "$(date): GitHub backup sleeping for $GITHUB_BACKUP_PERIOD minutes" >> $log_file
        sleep $(($GITHUB_BACKUP_PERIOD * 60))
    done
}

mongodb_backup() {
    while true; do
        run_backup "MongoDB" "/app/backup-mongodb.sh" "$MONGODB_URI" "$MONGODB_BUCKET_NAME"
        echo "$(date): MongoDB backup sleeping for $MONGODB_BACKUP_PERIOD minutes" >> $log_file
        sleep $(($MONGODB_BACKUP_PERIOD * 60))
    done
}

github_backup &
mongodb_backup &

wait
