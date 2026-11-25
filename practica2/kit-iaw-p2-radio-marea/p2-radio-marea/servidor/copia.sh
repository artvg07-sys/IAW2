#!/bin/sh

# C4.1 - Copia de seguridad de Radio Marea
set -e

# 1. Cargar las variables de radio.env
. /srv/servidor/radio.env

# 2. Obtener la fecha y la hora
FECHA=$(date +%Y%m%d-%H%M%S)

# 3. Crear la copia de seguridad de MariaDB
ARCHIVO="/copias/radio-$FECHA.sql"

mysqldump -h "$DB_HOST" -u "$COPIAS_USER" -p"$COPIAS_PASS" \
    --single-transaction --skip-lock-tables --no-tablespaces \
    "$DB_NAME" > "$ARCHIVO"

# 4. Eliminar copias antiguas de mas de 7 dias
find /copias -maxdepth 1 -type f -name "radio-*.sql" -mtime +6 -delete

# 5. Mostrar el archivo creado
echo "Copia de seguridad creada: $ARCHIVO"
