# Guía de Integración de Imágenes - Spazio

## 📸 Cómo funcionará el sistema de imágenes

### Backend - Estructura de datos esperada

Cuando implementes el almacenamiento de imágenes en el backend, la respuesta de la API debería incluir:

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-123",
      "name": "Sala de Conferencias Premium",
      "description": "Espacio moderno con vista panorámica",
      "capacity": 50,
      "imageUrl": "https://tu-cdn.com/spaces/sala-conferencias-1.jpg",
      "images": [
        "https://tu-cdn.com/spaces/sala-conferencias-1.jpg",
        "https://tu-cdn.com/spaces/sala-conferencias-2.jpg",
        "https://tu-cdn.com/spaces/sala-conferencias-3.jpg"
      ],
      "isActive": true,
      "ownerId": "uuid-owner",
      "createdAt": "2025-01-01T00:00:00.000Z",
      "updatedAt": "2025-01-15T00:00:00.000Z"
    }
  ]
}
```

### Frontend - Cómo se procesan

El componente `SpaceCard.vue` ya está preparado:

```vue
<script setup lang="ts">
// La lógica ya implementada
const imageUrl = computed(() => {
  // 1. Prioridad: imageUrl individual
  if (props.space.imageUrl) return props.space.imageUrl
  
  // 2. Fallback: primer elemento del array de imágenes
  if (props.space.images && props.space.images.length > 0) {
    return props.space.images[0]
  }
  
  // 3. Si no hay imágenes: placeholder con gradiente
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)
</script>

<template>
  <!-- Imagen real -->
  <img 
    v-if="hasRealImage"
    :src="imageUrl!"
    :alt="space.name"
    class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
  />
  
  <!-- Placeholder si no hay imagen -->
  <div v-else class="h-full w-full bg-gradient-to-br" :class="placeholderImage">
    <!-- ... -->
  </div>
</template>
```

## 🔧 Pasos para implementar imágenes en el Backend

### 1. Agregar campos a MySQL (Space model)

```javascript
// Backend/src/entities/Space.js
module.exports = (sequelize, DataTypes) => {
  const Space = sequelize.define('Space', {
    // ... campos existentes
    imageUrl: {
      type: DataTypes.STRING(500),
      allowNull: true,
      validate: {
        isUrl: true
      }
    },
    images: {
      type: DataTypes.JSON,  // Array de URLs
      allowNull: true,
      defaultValue: []
    }
  }, {
    // ... config existente
  })

  return Space
}
```

### 2. Migración de base de datos

```sql
-- migration_add_images_to_spaces.sql
ALTER TABLE spaces 
ADD COLUMN imageUrl VARCHAR(500) DEFAULT NULL,
ADD COLUMN images JSON DEFAULT NULL;
```

### 3. Configurar almacenamiento

Opciones recomendadas:

#### Opción A: Cloudinary (Recomendado para producción)
```bash
npm install cloudinary multer
```

```javascript
// Backend/src/config/cloudinary.js
const cloudinary = require('cloudinary').v2

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
})

module.exports = cloudinary
```

#### Opción B: AWS S3
```bash
npm install @aws-sdk/client-s3 multer multer-s3
```

#### Opción C: Local (Solo desarrollo)
```bash
npm install multer
```

```javascript
// Backend/src/middleware/upload.middleware.js
const multer = require('multer')
const path = require('path')

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/spaces/')
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
    cb(null, 'space-' + uniqueSuffix + path.extname(file.originalname))
  }
})

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|webp/
    const mimetype = filetypes.test(file.mimetype)
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase())
    
    if (mimetype && extname) {
      return cb(null, true)
    }
    cb(new Error('Solo se permiten imágenes (jpeg, jpg, png, webp)'))
  }
})

module.exports = upload
```

### 4. Endpoint para subir imágenes

```javascript
// Backend/src/routes/spaces.routes.js
const upload = require('../middleware/upload.middleware')

// Subir una imagen principal
router.post('/:id/image', 
  authMiddleware, 
  isOwnerOrAdmin,
  isResourceOwner('space'),
  upload.single('image'),
  spacesController.uploadImage
)

// Subir múltiples imágenes
router.post('/:id/images',
  authMiddleware,
  isOwnerOrAdmin,
  isResourceOwner('space'),
  upload.array('images', 5), // max 5 imágenes
  spacesController.uploadImages
)

// Eliminar imagen
router.delete('/:id/images/:imageIndex',
  authMiddleware,
  isOwnerOrAdmin,
  isResourceOwner('space'),
  spacesController.deleteImage
)
```

### 5. Controller para manejar imágenes

```javascript
// Backend/src/controllers/spaces.controller.js

// Subir imagen principal
async uploadImage(req, res) {
  try {
    const { id } = req.params
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No se proporcionó ninguna imagen'
      })
    }

    const imageUrl = `/uploads/spaces/${req.file.filename}` // O URL de Cloudinary
    
    const space = await SpacesUseCase.updateImage(id, imageUrl)
    
    res.json({
      success: true,
      message: 'Imagen actualizada correctamente',
      data: space
    })
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    })
  }
}

// Subir múltiples imágenes
async uploadImages(req, res) {
  try {
    const { id } = req.params
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No se proporcionaron imágenes'
      })
    }

    const imageUrls = req.files.map(file => `/uploads/spaces/${file.filename}`)
    
    const space = await SpacesUseCase.addImages(id, imageUrls)
    
    res.json({
      success: true,
      message: `${imageUrls.length} imágenes agregadas correctamente`,
      data: space
    })
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    })
  }
}
```

### 6. Use Case para imágenes

```javascript
// Backend/src/use-cases/spaces.usecase.js

class SpacesUseCase {
  // ... métodos existentes

  async updateImage(spaceId, imageUrl) {
    const space = await Space.findByPk(spaceId)
    if (!space) throw new Error('Espacio no encontrado')
    
    space.imageUrl = imageUrl
    await space.save()
    
    return space
  }

  async addImages(spaceId, imageUrls) {
    const space = await Space.findByPk(spaceId)
    if (!space) throw new Error('Espacio no encontrado')
    
    const currentImages = space.images || []
    space.images = [...currentImages, ...imageUrls]
    await space.save()
    
    return space
  }

  async deleteImage(spaceId, imageIndex) {
    const space = await Space.findByPk(spaceId)
    if (!space) throw new Error('Espacio no encontrado')
    
    const images = space.images || []
    images.splice(imageIndex, 1)
    space.images = images
    await space.save()
    
    return space
  }
}
```

## 🎨 Frontend - Componente de Upload (para Owners)

Cuando crees el panel de owners, puedes usar este componente:

```vue
<!-- Web/app/components/ImageUploader.vue -->
<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  spaceId: string
  currentImages?: string[]
}>()

const emit = defineEmits<{
  uploaded: [images: string[]]
}>()

const uploading = ref(false)
const selectedFiles = ref<FileList | null>(null)

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  selectedFiles.value = target.files
}

const uploadImages = async () => {
  if (!selectedFiles.value) return
  
  uploading.value = true
  
  try {
    const formData = new FormData()
    Array.from(selectedFiles.value).forEach(file => {
      formData.append('images', file)
    })
    
    const response = await $fetch(`/api/spaces/${props.spaceId}/images`, {
      method: 'POST',
      body: formData
    })
    
    emit('uploaded', response.data.images)
    selectedFiles.value = null
  } catch (error) {
    console.error('Error al subir imágenes:', error)
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="space-y-4">
    <!-- Preview de imágenes actuales -->
    <div v-if="currentImages?.length" class="grid grid-cols-4 gap-4">
      <div
        v-for="(image, index) in currentImages"
        :key="index"
        class="relative aspect-square rounded-lg overflow-hidden"
      >
        <img :src="image" :alt="`Imagen ${index + 1}`" class="w-full h-full object-cover" />
        <button
          class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
          @click="emit('delete', index)"
        >
          <span class="material-symbols-outlined text-sm">delete</span>
        </button>
      </div>
    </div>
    
    <!-- Upload de nuevas imágenes -->
    <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
      <input
        type="file"
        multiple
        accept="image/*"
        class="hidden"
        id="image-upload"
        @change="handleFileSelect"
      />
      
      <label
        for="image-upload"
        class="cursor-pointer inline-flex flex-col items-center gap-2"
      >
        <span class="material-symbols-outlined text-4xl text-gray-400">cloud_upload</span>
        <span class="text-sm text-gray-600">Click para seleccionar imágenes</span>
        <span class="text-xs text-gray-400">PNG, JPG, WEBP hasta 5MB</span>
      </label>
      
      <div v-if="selectedFiles" class="mt-4">
        <p class="text-sm text-gray-600">{{ selectedFiles.length }} archivo(s) seleccionado(s)</p>
        <button
          class="mt-2 bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90"
          :disabled="uploading"
          @click="uploadImages"
        >
          {{ uploading ? 'Subiendo...' : 'Subir imágenes' }}
        </button>
      </div>
    </div>
  </div>
</template>
```

## 📋 Checklist de Implementación

- [ ] Agregar campos `imageUrl` e `images` al modelo Space (MySQL)
- [ ] Crear migración de base de datos
- [ ] Configurar sistema de almacenamiento (Cloudinary/S3/Local)
- [ ] Instalar dependencias necesarias (multer, cloudinary, etc.)
- [ ] Crear middleware de upload
- [ ] Agregar endpoints para subir/eliminar imágenes
- [ ] Implementar validaciones de tipo y tamaño de archivo
- [ ] Agregar métodos en UseCases
- [ ] Crear componente ImageUploader para owners
- [ ] Servir archivos estáticos (si usas almacenamiento local)
- [ ] Agregar variables de entorno necesarias
- [ ] Documentar en API_REFERENCE.md
- [ ] Probar con imágenes reales

## 🔒 Consideraciones de Seguridad

1. **Validar tipo de archivo**: Solo permitir imágenes
2. **Limitar tamaño**: Max 5MB por imagen
3. **Sanitizar nombres**: Evitar caracteres especiales
4. **Verificar ownership**: Solo el owner puede subir imágenes a su espacio
5. **Rate limiting**: Limitar cantidad de uploads por tiempo
6. **Escaneo de virus**: En producción, usar servicio de escaneo

## 🚀 Optimizaciones Recomendadas

1. **Compresión automática**: Usar sharp o similar
2. **Múltiples tamaños**: Generar thumbnails (small, medium, large)
3. **Lazy loading**: Cargar imágenes bajo demanda
4. **CDN**: Usar Cloudinary o CloudFront para mejor performance
5. **WebP**: Convertir automáticamente a formato WebP
6. **Placeholder blur**: Usar técnica de blur-up mientras carga

## 📊 Ejemplo de respuesta con imágenes

```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Sala de Juntas Ejecutiva",
    "description": "Espacio premium con vista panorámica",
    "capacity": 20,
    "imageUrl": "https://res.cloudinary.com/spazio/image/upload/v1/spaces/sala-juntas-main.jpg",
    "images": [
      "https://res.cloudinary.com/spazio/image/upload/v1/spaces/sala-juntas-1.jpg",
      "https://res.cloudinary.com/spazio/image/upload/v1/spaces/sala-juntas-2.jpg",
      "https://res.cloudinary.com/spazio/image/upload/v1/spaces/sala-juntas-3.jpg",
      "https://res.cloudinary.com/spazio/image/upload/v1/spaces/sala-juntas-4.jpg"
    ],
    "isActive": true,
    "ownerId": "owner-uuid",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "updatedAt": "2025-01-15T10:30:00.000Z",
    "owner": {
      "id": "owner-uuid",
      "businessName": "Espacios Corporativos SA",
      "name": "Juan Pérez"
    }
  }
}
```

## 🎯 Resultado Final

Cuando implementes este sistema:
- ✅ Los espacios con imágenes mostrarán fotos reales
- ✅ Los espacios sin imágenes mostrarán placeholders coloridos
- ✅ Transición suave entre placeholder y imagen real
- ✅ Hover effects profesionales
- ✅ Sistema escalable y mantenible
