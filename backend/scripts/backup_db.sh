#!/bin/bash
# Automated database backup script

# Go to backend directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="${DB_NAME}_backup_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"

echo "Starting backup of database: $DB_NAME..."

# Run pg_dump
PGPASSWORD="$DB_PASS" pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" > "$BACKUP_DIR/$FILENAME"

if [ $? -eq 0 ]; then
  # Compress the backup
  gzip "$BACKUP_DIR/$FILENAME"
  echo "✅ Backup successfully created at $BACKUP_DIR/$FILENAME.gz"

  # Retain only last 7 days of backups
  find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete
  echo "Old backups cleaned up."
else
  echo "❌ Backup failed!"
  rm -f "$BACKUP_DIR/$FILENAME"
  exit 1
fi
