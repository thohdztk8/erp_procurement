#!/bin/bash
echo "Waiting for SQL Server to start..."

# Chờ đến khi sqlcmd kết nối được thay vì sleep cứng
until /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -C -Q "SELECT 1" &>/dev/null; do
    echo "SQL Server not ready yet, retrying in 5s..."
    sleep 5
done

echo "SQL Server is ready. Running init script..."
/opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "${SA_PASSWORD}" \
    -i /docker-entrypoint-initdb.d/db.sql \
    -C -b

echo "SQL Server is ready. Running init master data script..."
/opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "${SA_PASSWORD}" \
    -i /docker-entrypoint-initdb.d/seed_master_data.sql \
    -C -b

echo "Database initialized!"