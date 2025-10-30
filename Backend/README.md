# Spazio Backend - API REST

Backend básico para el sistema de reservas Spazio con arquitectura limpia.

## 🚀 Configuración Inicial

### 1. Instalar dependencias
```bash
npm install
```

### 2. Configurar variables de entorno
Copia `.env.example` a `.env` y configura tus credenciales:
```bash
cp .env.example .env
```

### 3. Configurar bases de datos

#### MySQL
Crea la base de datos:
```sql
CREATE DATABASE spazio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### MongoDB
Asegúrate de tener MongoDB corriendo en localhost:27017 o actualiza la URI en `.env`

### 4. Iniciar servidor de desarrollo
```bash
npm run dev
```

El servidor estará disponible en `http://localhost:3001`

## 📚 Endpoints Disponibles

### Salud del servidor
- `GET /` - Mensaje de bienvenida
- `GET /health` - Estado del servidor

### Autenticación
- `POST /api/auth/register` - Registrar nuevo usuario
  ```json
  {
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "contraseña123"
  }
  ```

- `POST /api/auth/login` - Iniciar sesión
  ```json
  {
    "email": "juan@example.com",
    "password": "contraseña123"
  }
  ```

- `GET /api/auth/profile` - Obtener perfil (requiere token)
  - Header: `Authorization: Bearer <token>`

## 🏗️ Estructura del Proyecto

```
Backend/
├── src/
│   ├── config/           # Configuración de bases de datos
│   ├── entities/         # Modelos de datos (User)
│   ├── use-cases/        # Lógica de negocio
│   ├── controllers/      # Controladores de rutas
│   ├── routes/           # Definición de endpoints
│   ├── middleware/       # Auth, validación
│   └── index.js          # Punto de entrada
├── .env.example          # Variables de entorno ejemplo
└── package.json
```

## 🔐 Autenticación

El sistema usa JWT (JSON Web Tokens). Al hacer login o registro, recibirás un token que debes incluir en las peticiones protegidas:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🛠️ Tecnologías

- **Express** - Framework web
- **MySQL + Sequelize** - Base de datos relacional
- **MongoDB + Mongoose** - Base de datos NoSQL
- **JWT** - Autenticación
- **bcryptjs** - Encriptación de contraseñas

## 📝 Próximos Pasos

- [ ] Implementar CRUD de Espacios
- [ ] Implementar sistema de Reservas con validación
- [ ] Agregar documentación Swagger
- [ ] Implementar logs y auditoría
