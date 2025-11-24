# 🚀 Quick Start - Sistema de Roles Owner

## ⚡ Comandos Rápidos

### 1. Aplicar Migración
```bash
./migrate.sh
# O manualmente:
mysql -u root -p spazio_db < migration_owner_system.sql
```

### 2. Ejecutar Seed
```bash
npm run seed
```

### 3. Iniciar Servidor
```bash
npm run dev
```

## 🔑 Credenciales de Prueba

| Rol    | Email                  | Password  | Estado      |
|--------|------------------------|-----------|-------------|
| Admin  | admin@spazio.com       | admin123  | Activo      |
| User   | user@spazio.com        | user123   | Activo      |
| Owner  | owner1@spazio.com      | owner123  | Verificado  |
| Owner  | owner2@spazio.com      | owner123  | Verificado  |
| Owner  | pending@spazio.com     | pending123| Pendiente   |

## �� Estructura de Espacios

| Espacio                | Owner        | Negocio           |
|------------------------|--------------|-------------------|
| Sala de Reuniones A    | owner1       | CoWork Central    |
| Sala de Conferencias   | owner2       | Salas Premium     |
| Sala de Capacitación   | owner1       | CoWork Central    |
| Espacio de Coworking   | owner2       | Salas Premium     |

## 🧪 Tests Rápidos con cURL

### Login Owner
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner1@spazio.com","password":"owner123"}'
```

### Ver Mis Espacios
```bash
TOKEN="<tu_token>"
curl -X GET http://localhost:3001/api/spaces/owner/my-spaces \
  -H "Authorization: Bearer $TOKEN"
```

### Ver Reservas de Mis Espacios
```bash
curl -X GET http://localhost:3001/api/bookings/owner/bookings \
  -H "Authorization: Bearer $TOKEN"
```

### Crear Nuevo Espacio
```bash
curl -X POST http://localhost:3001/api/spaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sala Nueva",
    "description": "Espacio para eventos",
    "capacity": 25
  }'
```

## 🔍 Verificar Migración

```bash
# Ver estructura de users
mysql -u root -p spazio_db -e "DESCRIBE users;"

# Ver estructura de spaces
mysql -u root -p spazio_db -e "DESCRIBE spaces;"

# Ver owners
mysql -u root -p spazio_db -e "SELECT id, name, email, role, isVerified, businessName FROM users WHERE role='owner';"

# Ver espacios con owners
mysql -u root -p spazio_db -e "SELECT s.id, s.name, s.capacity, u.businessName as owner FROM spaces s JOIN users u ON s.ownerId = u.id;"
```

## 📚 Documentación Completa

Ver `OWNER_SYSTEM.md` para detalles completos de la implementación.
