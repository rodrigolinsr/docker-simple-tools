#!/bin/bash

echo "======================================"
echo " 🚀 MySQL Database Copy Utility"
echo "======================================"

# Prompt for connection strings
read -p "Enter SOURCE connection string (format: user:pass@tcp(host:port)/dbname): " SRC_CONN
read -p "Enter DESTINATION connection string (format: user:pass@tcp(host:port)/dbname): " DEST_CONN

# Extract database names (for messages)
SRC_DB=$(echo "$SRC_CONN" | sed -E 's|.*/([^/]+)$|\1|')
DEST_DB=$(echo "$DEST_CONN" | sed -E 's|.*/([^/]+)$|\1|')

echo ""
echo "✅ Source: $SRC_DB"
echo "✅ Destination: $DEST_DB"
echo ""

# Confirm
read -p "Proceed with copying $SRC_DB to $DEST_DB? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Operation cancelled."
  exit 1
fi

echo ""
echo "📦 Dumping database from source..."
mysqldump -v -u$(echo $SRC_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\1/') \
          -p$(echo $SRC_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\2/') \
          -h$(echo $SRC_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\3/') \
          -P$(echo $SRC_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\4/') \
          $(echo $SRC_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\5/') \
          > dump.sql

if [ $? -ne 0 ]; then
  echo "❌ Failed to dump database."
  exit 1
fi

echo ""
echo "📥 Importing dump into destination..."
mysql -v -u$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\1/') \
          -p$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\2/') \
          -h$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\3/') \
          -P$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\4/') \
          $(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\5/') \
          < dump.sql

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
    mysql -u$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\1/') \
          -p$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\2/') \
          -h$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\3/') \
          -P$(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\4/') \
          $(echo $DEST_CONN | sed -E 's/(.+):(.+)@tcp\((.+):([0-9]+)\)\/(.+)/\5/') \
          -e "UPDATE $TABLE SET $COLUMN = ''"
  done
fi

echo ""
echo "🎉 Database copy completed successfully!"

