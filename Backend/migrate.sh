#!/bin/bash

# Script para aplicar la migración del sistema de roles owner
# Fecha: 2025-11-06

echo "🔄 Aplicando migración del sistema de roles owner..."
echo ""
echo "⚠️  IMPORTANTE: Este script modificará la estructura de la base de datos"
echo "   - Agregará rol 'owner' a users"
echo "   - Agregará campos isVerified, businessName, businessDescription a users"
echo "   - Agregará campo ownerId a spaces"
echo ""
read -p "¿Deseas continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "❌ Migración cancelada"
    exit 1
fi

echo ""
echo "📋 Ejecutando migración SQL..."
mysql -u root -p spazio_db < migration_owner_system.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migración completada exitosamente"
    echo ""
    echo "📊 Verificando estructura..."
    mysql -u root -p spazio_db -e "SHOW COLUMNS FROM users WHERE Field IN ('role', 'isVerified', 'businessName', 'businessDescription');"
    mysql -u root -p spazio_db -e "SHOW COLUMNS FROM spaces WHERE Field = 'ownerId';"
    echo ""
    echo "🌱 Ahora ejecuta: npm run seed"
else
    echo ""
    echo "❌ Error al aplicar la migración"
    exit 1
fi
