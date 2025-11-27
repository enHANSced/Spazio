<template>
  <div class="h-[400px] w-full rounded-lg overflow-hidden border border-gray-300 z-0 relative">
    <l-map
      ref="mapRef"
      v-model:zoom="zoom"
      :center="center"
      :use-global-leaflet="false"
      @click="onMapClick"
      @ready="onMapReady"
    >
      <l-tile-layer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        layer-type="base"
        name="OpenStreetMap"
        attribution="&copy; <a href='https://www.openstreetmap.org/copyright'>OpenStreetMap</a> contributors"
      ></l-tile-layer>
      
      <l-marker 
        v-if="markerLatLng" 
        :lat-lng="markerLatLng"
      ></l-marker>
    </l-map>
    
    <div class="absolute top-2 right-2 z-[1000] space-y-2">
      <button
        @click="getCurrentLocation"
        :disabled="loadingLocation"
        class="bg-white hover:bg-gray-50 p-2 rounded shadow-md border border-gray-300 transition-colors disabled:opacity-50"
        title="Ir a mi ubicación"
      >
        <svg v-if="!loadingLocation" class="w-5 h-5 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <svg v-else class="w-5 h-5 text-gray-700 animate-spin" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
      </button>
    </div>
    
    <div class="absolute bottom-2 left-2 bg-white px-2 py-1 rounded shadow text-xs z-[1000]">
      Click en el mapa para seleccionar ubicación
    </div>
  </div>
</template>

<script setup lang="ts">
import 'leaflet/dist/leaflet.css'
import { LMap, LTileLayer, LMarker } from '@vue-leaflet/vue-leaflet'

const props = defineProps<{
  modelValue?: { lat: number; lng: number } | null
  address?: string
  city?: string
  state?: string
  country?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: { lat: number; lng: number }): void
  (e: 'update:address', value: string): void
  (e: 'update:city', value: string): void
  (e: 'update:state', value: string): void
}>()

const mapRef = ref<any>(null)
const zoom = ref(13)
const center = ref<[number, number]>([14.0723, -87.1921])
const markerLatLng = ref<[number, number] | null>(null)
const loadingLocation = ref(false)
const map = ref<any>(null)

// Geocoding: convertir dirección a coordenadas
const geocodeAddress = async (address: string, city: string, state: string, country: string) => {
  if (!address || !city) return
  
  try {
    const query = `${address}, ${city}, ${state}, ${country}`.trim()
    const response = await fetch(
      `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`
    )
    const data = await response.json()
    
    if (data && data.length > 0) {
      const { lat, lon } = data[0]
      const latNum = parseFloat(lat)
      const lonNum = parseFloat(lon)
      
      markerLatLng.value = [latNum, lonNum]
      center.value = [latNum, lonNum]
      
      if (map.value) {
        map.value.setView([latNum, lonNum], 15)
      }
      
      emit('update:modelValue', { lat: latNum, lng: lonNum })
    }
  } catch (error) {
    console.error('Error geocoding address:', error)
  }
}

// Reverse geocoding: convertir coordenadas a dirección
const reverseGeocode = async (lat: number, lng: number) => {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`
    )
    const data = await response.json()
    
    if (data && data.address) {
      const address = data.address
      
      // Construir dirección legible
      const street = address.road || address.street || ''
      const houseNumber = address.house_number || ''
      const fullAddress = houseNumber ? `${street} ${houseNumber}` : street
      
      const city = address.city || address.town || address.village || ''
      const state = address.state || ''
      
      if (fullAddress) emit('update:address', fullAddress)
      if (city) emit('update:city', city)
      if (state) emit('update:state', state)
    }
  } catch (error) {
    console.error('Error reverse geocoding:', error)
  }
}

// Obtener ubicación actual del usuario
const getCurrentLocation = () => {
  if (!navigator.geolocation) {
    alert('La geolocalización no está disponible en tu navegador')
    return
  }
  
  loadingLocation.value = true
  
  navigator.geolocation.getCurrentPosition(
    (position) => {
      const { latitude, longitude } = position.coords
      
      markerLatLng.value = [latitude, longitude]
      center.value = [latitude, longitude]
      
      if (map.value) {
        map.value.setView([latitude, longitude], 15)
      }
      
      emit('update:modelValue', { lat: latitude, lng: longitude })
      reverseGeocode(latitude, longitude)
      
      loadingLocation.value = false
    },
    (error) => {
      console.error('Error getting location:', error)
      alert('No se pudo obtener tu ubicación. Verifica los permisos del navegador.')
      loadingLocation.value = false
    }
  )
}

// Cuando el usuario hace click en el mapa
const onMapClick = (e: any) => {
  const { lat, lng } = e.latlng
  markerLatLng.value = [lat, lng]
  emit('update:modelValue', { lat, lng })
  reverseGeocode(lat, lng)
}

// Cuando el mapa está listo
const onMapReady = () => {
  if (mapRef.value && mapRef.value.leafletObject) {
    map.value = mapRef.value.leafletObject
  }
}

// Watch para coordenadas desde el padre
watch(() => props.modelValue, (val) => {
  if (val && val.lat && val.lng && val.lat !== 0 && val.lng !== 0) {
    markerLatLng.value = [val.lat, val.lng]
    center.value = [val.lat, val.lng]
    
    if (map.value) {
      map.value.setView([val.lat, val.lng], 15)
    }
  }
}, { immediate: true })

// Watch para cambios en la dirección
let geocodeTimeout: any = null
watch([() => props.address, () => props.city, () => props.state, () => props.country], 
  ([newAddress, newCity, newState, newCountry]) => {
    // Debounce para no hacer demasiadas peticiones
    if (geocodeTimeout) clearTimeout(geocodeTimeout)
    
    geocodeTimeout = setTimeout(() => {
      if (newAddress && newCity) {
        geocodeAddress(newAddress, newCity, newState || '', newCountry || 'Honduras')
      }
    }, 1000) // Esperar 1 segundo después de que el usuario deje de escribir
  }
)

// Intentar obtener ubicación actual al montar (opcional, comentado para no ser intrusivo)
onMounted(() => {
  // Descomentar si quieres que automáticamente pida ubicación al cargar
  // getCurrentLocation()
})
</script>
