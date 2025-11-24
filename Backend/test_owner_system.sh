#!/bin/bash

echo "🧪 Prueba del Sistema de Roles Owner"
echo "======================================"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:3001"

# Función para verificar si el servidor está corriendo
check_server() {
    if curl -s "$API_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Servidor corriendo en $API_URL${NC}"
        return 0
    else
        echo -e "${RED}✗ Servidor NO está corriendo${NC}"
        echo -e "${YELLOW}Por favor inicia el servidor con: npm run dev${NC}"
        return 1
    fi
}

# Test 1: Login como Owner
test_owner_login() {
    echo ""
    echo "📋 Test 1: Login como Owner"
    echo "----------------------------"
    
    RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"owner1@spazio.com","password":"owner123"}')
    
    TOKEN=$(echo $RESPONSE | jq -r '.data.token')
    
    if [ "$TOKEN" != "null" ] && [ ! -z "$TOKEN" ]; then
        echo -e "${GREEN}✓ Login exitoso${NC}"
        echo "Token: ${TOKEN:0:50}..."
        echo $TOKEN > /tmp/owner_token.txt
        
        # Mostrar info del usuario
        USER_NAME=$(echo $RESPONSE | jq -r '.data.user.name')
        BUSINESS=$(echo $RESPONSE | jq -r '.data.user.businessName')
        echo "Usuario: $USER_NAME"
        echo "Negocio: $BUSINESS"
        return 0
    else
        echo -e "${RED}✗ Login fallido${NC}"
        echo "Response: $RESPONSE"
        return 1
    fi
}

# Test 2: Ver mis espacios como Owner
test_my_spaces() {
    echo ""
    echo "📋 Test 2: Ver mis espacios"
    echo "---------------------------"
    
    TOKEN=$(cat /tmp/owner_token.txt)
    
    RESPONSE=$(curl -s -X GET "$API_URL/api/spaces/owner/my-spaces" \
        -H "Authorization: Bearer $TOKEN")
    
    COUNT=$(echo $RESPONSE | jq -r '.data | length')
    
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Espacios obtenidos: $COUNT${NC}"
        echo $RESPONSE | jq '.data[] | {id, name, capacity}'
        return 0
    else
        echo -e "${RED}✗ No se pudieron obtener espacios${NC}"
        echo "Response: $RESPONSE"
        return 1
    fi
}

# Test 3: Ver reservas de mis espacios
test_owner_bookings() {
    echo ""
    echo "📋 Test 3: Ver reservas de mis espacios"
    echo "---------------------------------------"
    
    TOKEN=$(cat /tmp/owner_token.txt)
    
    RESPONSE=$(curl -s -X GET "$API_URL/api/bookings/owner/bookings" \
        -H "Authorization: Bearer $TOKEN")
    
    COUNT=$(echo $RESPONSE | jq -r '.data | length')
    
    echo -e "${GREEN}✓ Reservas obtenidas: $COUNT${NC}"
    if [ "$COUNT" -gt 0 ]; then
        echo $RESPONSE | jq '.data[] | {space: .space.name, startTime, status}'
    fi
    return 0
}

# Test 4: Intentar crear reserva como Owner (debe fallar)
test_owner_cannot_book() {
    echo ""
    echo "📋 Test 4: Intentar reservar como Owner (debe fallar)"
    echo "-----------------------------------------------------"
    
    TOKEN=$(cat /tmp/owner_token.txt)
    
    TOMORROW=$(date -d "+1 day" +"%Y-%m-%dT10:00:00.000Z")
    END_TIME=$(date -d "+1 day" +"%Y-%m-%dT12:00:00.000Z")
    
    # Obtener un spaceId de los espacios públicos
    SPACE_ID=$(curl -s -X GET "$API_URL/api/spaces" | jq -r '.data[0].id')
    
    if [ -z "$SPACE_ID" ] || [ "$SPACE_ID" == "null" ]; then
        echo -e "${YELLOW}⚠ No hay espacios disponibles para probar${NC}"
        return 0
    fi
    
    echo "Intentando reservar espacio: ${SPACE_ID:0:8}..."
    
    RESPONSE=$(curl -s -X POST "$API_URL/api/bookings" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"spaceId\": \"$SPACE_ID\",
            \"startTime\": \"$TOMORROW\",
            \"endTime\": \"$END_TIME\"
        }")
    
    ERROR_MSG=$(echo $RESPONSE | jq -r '.message')
    
    if echo "$ERROR_MSG" | grep -iq "propietario"; then
        echo -e "${GREEN}✓ Restricción funcionando correctamente${NC}"
        echo "Mensaje: $ERROR_MSG"
        return 0
    else
        echo -e "${RED}✗ La restricción NO está funcionando${NC}"
        echo "Response: $RESPONSE"
        return 1
    fi
}

# Test 5: Login como Admin y ver owners pendientes
test_admin_pending_owners() {
    echo ""
    echo "📋 Test 5: Admin ve owners pendientes"
    echo "-------------------------------------"
    
    # Login como admin
    ADMIN_TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@spazio.com","password":"admin123"}' | jq -r '.data.token')
    
    if [ "$ADMIN_TOKEN" != "null" ] && [ ! -z "$ADMIN_TOKEN" ]; then
        echo -e "${GREEN}✓ Admin login exitoso${NC}"
        
        RESPONSE=$(curl -s -X GET "$API_URL/api/users/pending-owners" \
            -H "Authorization: Bearer $ADMIN_TOKEN")
        
        COUNT=$(echo $RESPONSE | jq -r '.data | length')
        echo -e "${GREEN}✓ Owners pendientes: $COUNT${NC}"
        
        if [ "$COUNT" -gt 0 ]; then
            echo $RESPONSE | jq '.data[] | {name, email, businessName}'
        fi
        return 0
    else
        echo -e "${RED}✗ Admin login fallido${NC}"
        return 1
    fi
}

# Ejecutar tests
check_server || exit 1

test_owner_login || exit 1
test_my_spaces || exit 1
test_owner_bookings || exit 1
test_owner_cannot_book || exit 1
test_admin_pending_owners || exit 1

echo ""
echo "======================================"
echo -e "${GREEN}✅ Todos los tests pasaron${NC}"
echo "======================================"
