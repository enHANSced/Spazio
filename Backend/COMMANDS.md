# Comandos Útiles - Spazio Backend

## 🚀 Desarrollo

### Iniciar servidor de desarrollo
```bash
npm run dev
```

### Iniciar servidor de producción
```bash
npm start
```

### Iniciar sin conectar a bases de datos (útil para testing de rutas)
```bash
SKIP_DB=true npm run dev
```

---

## 🌱 Base de Datos

### Ejecutar seeder (poblar datos de prueba)
```bash
npm run seed
```

### Crear base de datos MySQL
```bash
mysql -u root -p
```
```sql
CREATE DATABASE spazio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Ver tablas MySQL
```sql
USE spazio_db;
SHOW TABLES;
SELECT * FROM users;
SELECT * FROM spaces;
```

### Ver colecciones MongoDB
```bash
mongosh
```
```js
use spazio_db
show collections
db.bookings.find().pretty()
db.bookings.countDocuments()
```

### Limpiar datos de prueba
```sql
-- MySQL
TRUNCATE TABLE spaces;
DELETE FROM users WHERE email LIKE '%@spazio.com';
```
```js
// MongoDB
db.bookings.deleteMany({})
```

---

## 🧪 Testing con cURL

### Registrar usuario
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"test123"}'
```

### Login
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@spazio.com","password":"admin123"}'
```

### Listar espacios (público)
```bash
curl http://localhost:3001/api/spaces
```

### Crear espacio (admin)
```bash
TOKEN="tu-token-aqui"
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Sala Test","description":"Test","capacity":10}'
```

### Crear reserva
```bash
TOKEN="tu-token-aqui"
SPACE_ID="uuid-del-espacio"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"spaceId\":\"$SPACE_ID\",\"startTime\":\"2025-11-10T10:00:00Z\",\"endTime\":\"2025-11-10T12:00:00Z\"}"
```

### Ver mis reservas
```bash
TOKEN="tu-token-aqui"
curl http://localhost:3001/api/bookings/my-bookings \
  -H "Authorization: Bearer $TOKEN"
```

### Ver calendario de un espacio
```bash
TOKEN="tu-token-aqui"
SPACE_ID="uuid-del-espacio"
curl "http://localhost:3001/api/bookings/space/$SPACE_ID?startDate=2025-11-01&endDate=2025-11-30" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Debugging

### Ver logs del servidor
```bash
# Ya incluidos en npm run dev con nodemon
```

### Verificar conexiones
```bash
# MySQL
mysql -u root -p -e "SELECT 1"

# MongoDB
mongosh --eval "db.runCommand({ ping: 1 })"
```

### Ver procesos Node corriendo
```bash
ps aux | grep node
```

### Matar proceso en puerto 3001
```bash
lsof -ti:3001 | xargs kill -9
```

---

## 📦 Gestión de Dependencias

### Instalar dependencias
```bash
npm install
```

### Agregar nueva dependencia
```bash
npm install nombre-paquete
```

### Agregar dependencia de desarrollo
```bash
npm install --save-dev nombre-paquete
```

### Actualizar dependencias
```bash
npm update
```

### Auditar vulnerabilidades
```bash
npm audit
npm audit fix
```

---

## 🔧 Mantenimiento

### Ver estructura del proyecto
```bash
tree -L 3 -I 'node_modules'
```

### Contar líneas de código
```bash
find src -name '*.js' | xargs wc -l
```

### Buscar en código
```bash
grep -r "palabra" src/
```

---

## 🚨 Troubleshooting

### Error: Puerto 3001 en uso
```bash
lsof -ti:3001 | xargs kill -9
# O cambiar puerto en .env
```

### Error: No se puede conectar a MySQL
```bash
# Verificar que MySQL está corriendo
sudo service mysql status
sudo service mysql start

# Verificar credenciales en .env
```

### Error: No se puede conectar a MongoDB
```bash
# Verificar que MongoDB está corriendo
sudo service mongod status
sudo service mongod start

# Verificar URI en .env
```

### Error: Tabla no existe
```bash
# El servidor crea las tablas automáticamente en desarrollo
# Asegúrate de que NODE_ENV=development en .env
```

### Reiniciar completamente
```bash
# Borrar node_modules y reinstalar
rm -rf node_modules package-lock.json
npm install

# Reiniciar bases de datos
# MySQL: DROP DATABASE spazio_db; CREATE DATABASE spazio_db;
# MongoDB: db.dropDatabase()

# Ejecutar seed
npm run seed
```

---

## 📊 Monitoreo

### Health check
```bash
curl http://localhost:3001/health
```

### Ver estado de bases de datos
```bash
# MySQL
mysql -u root -p -e "SHOW DATABASES"

# MongoDB
mongosh --eval "show dbs"
```

---

## 🎯 Workflows Comunes

### Setup inicial completo
```bash
cd Backend
npm install
cp .env.example .env
# Editar .env
npm run seed
npm run dev
```

### Reset y empezar de nuevo
```bash
# Limpiar bases de datos
mysql -u root -p spazio_db < /dev/null
mysql -u root -p -e "CREATE DATABASE spazio_db"
mongosh spazio_db --eval "db.dropDatabase()"

# Ejecutar seed
npm run seed

# Reiniciar servidor
npm run dev
```

### Actualizar un modelo
```bash
# 1. Editar archivo en src/entities/
# 2. Si es MySQL, el sync automático lo actualizará (en desarrollo)
# 3. Si necesitas migración manual, ejecutar SQL directo
```

---

## 📝 Variables de Entorno Importantes

```bash
PORT=3001                    # Puerto del servidor
NODE_ENV=development         # Ambiente
SKIP_DB=true                 # Saltar conexiones DB
JWT_SECRET=tu-secreto        # Secret para JWT
JWT_EXPIRES_IN=7d            # Expiración del token
MYSQL_HOST=localhost         # Host MySQL
MYSQL_DATABASE=spazio_db     # Base de datos MySQL
MONGODB_URI=mongodb://...    # URI MongoDB
```

---

## 🎓 Tips de Desarrollo

1. **Usa el seeder**: `npm run seed` para tener datos rápidamente
2. **Guarda los tokens**: Al hacer login, guarda el token para usarlo en otras peticiones
3. **Revisa los logs**: El servidor imprime información útil al iniciar
4. **Usa SKIP_DB**: Para probar rutas sin conectar a BD
5. **Lee TESTING.md**: Tiene ejemplos completos de flujos
6. **Consulta API_REFERENCE.md**: Para recordar endpoints rápidamente
