#!/bin/bash

echo "======================================"
echo " 🚀 MySQL Database Copy Utility"
echo "======================================"

# Function to parse MySQL URI
parse_mysql_uri() {
    local URI=$1
    # Remove mysql:// if present
    URI=${URI#mysql://}

    local USER_PASS_HOST_PORT_DB
    USER_PASS_HOST_PORT_DB=$URI

    # Extract user
    USER=$(echo "$USER_PASS_HOST_PORT_DB" | cut -d: -f1)
    # Extract password
    PASS=$(echo "$USER_PASS_HOST_PORT_DB" | cut -d: -f2 | cut -d@ -f1)
    # Extract host
    HOST=$(echo "$USER_PASS_HOST_PORT_DB" | cut -d@ -f2 | cut -d: -f1)
    # Extract port
    PORT=$(echo "$USER_PASS_HOST_PORT_DB" | cut -d: -f3 | cut -d/ -f1)
    # Extract database
    DB=$(echo "$USER_PASS_HOST_PORT_DB" | cut -d/ -f2)
}

# Prompt for connection strings
read -p "Enter SOURCE connection string (mysql://user:pass@host:port/db): " SRC_URI
read -p "Enter DESTINATION connection string (mysql://user:pass@host:port/db): " DEST_URI

# Parse source and destination
parse_mysql_uri "$SRC_URI"
SRC_USER=$USER
SRC_PASS=$PASS
SRC_HOST=$HOST
SRC_PORT=$PORT
SRC_DB=$DB

parse_mysql_uri "$DEST_URI"
DEST_USER=$USER
DEST_PASS=$PASS
DEST_HOST=$HOST
DEST_PORT=$PORT
DEST_DB=$DB

echo ""
echo "✅ Source: $SRC_DB@$SRC_HOST:$SRC_PORT"
echo "✅ Destination: $DEST_DB@$DEST_HOST:$DEST_PORT"
echo ""

# Confirm
read -p "Proceed with copying $SRC_DB to $DEST_DB? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Operation cancelled."
  exit 1
fi

echo ""
echo "📦 Dumping database from source..."
mysqldump --column-statistics=0 -u"$SRC_USER" -p"$SRC_PASS" -h"$SRC_HOST" -P"$SRC_PORT" "$SRC_DB" > dump.sql
if [ $? -ne 0 ]; then
  echo "❌ Failed to dump database."
  exit 1
fi

echo ""
echo "📥 Importing dump into destination..."
mysql -u"$DEST_USER" -p"$DEST_PASS" -h"$DEST_HOST" -P"$DEST_PORT" "$DEST_DB" < dump.sql
if [ $? -ne 0 ]; then
  echo "❌ Failed to import database."
  exit 1
fi

echo ""
echo "⚙️ Do you want to blank out sensitive columns (e.g. user.password)?"
read -p "Enter table.column pairs separated by commas (or leave empty): " COLS

if [ ! -z "$COLS" ]; then
  IFS=',' read -ra ITEMS <<< "$COLS"
  for ITEM in "${ITEMS[@]}"; do
    TABLE=$(echo "$ITEM" | cut -d. -f1)
    COLUMN=$(echo "$ITEM" | cut -d. -f2)
    echo "   ➡️ Updating $TABLE.$COLUMN ..."
    mysql -u"$DEST_USER" -p"$DEST_PASS" -h"$DEST_HOST" -P"$DEST_PORT" "$DEST_DB" -e "UPDATE $TABLE SET $COLUMN = ''"
  done
fi

echo ""
echo "🎉 Database copy completed successfully!"
