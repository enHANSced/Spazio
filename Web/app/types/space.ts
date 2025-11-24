export interface SpaceOwner {
  id: string
  name?: string | null
  businessName?: string | null
  businessDescription?: string | null
  phone?: string | null
  whatsappNumber?: string | null
}

export interface WorkingHours {
  start: string
  end: string
}

export interface Space {
  id: string
  name: string
  description?: string | null
  capacity: number
  ownerId: string
  isActive: boolean
  pricePerHour?: number | null
  amenities?: string[] | null
  rules?: string | null
  virtualTourUrl?: string | null
  cancellationPolicy?: 'flexible' | 'moderate' | 'strict' | null
  address?: string | null
  city?: string | null
  state?: string | null
  country?: string | null
  latitude?: number | null
  longitude?: number | null
  zipCode?: string | null
  workingHours?: WorkingHours | null
  videos?: Array<{ url: string; publicId?: string; thumbnail?: string }> | null
  images360?: Array<{ url: string; publicId?: string }> | null
  createdAt: string
  updatedAt: string
  owner?: SpaceOwner | null
  // Imágenes normales
  imageUrl?: string | null
  images?: (string | { url: string; publicId?: string | null })[] | null
}

export interface SpacesApiResponse {
  success: boolean
  message?: string
  data: Space[]
}

export interface SpaceApiResponse {
  success: boolean
  message?: string
  data: Space
}

export interface CreateSpacePayload {
  name: string
  description?: string
  capacity: number
  pricePerHour?: number
  amenities?: string[]
  rules?: string
  virtualTourUrl?: string
  cancellationPolicy?: 'flexible' | 'moderate' | 'strict'
  address?: string
  city?: string
  state?: string
  country?: string
  latitude?: number
  longitude?: number
  zipCode?: string
  workingHours?: WorkingHours
  imageUrl?: string
  images?: (string | { url: string })[]
  videos?: Array<{ url: string }>
  images360?: Array<{ url: string }>
}

export interface UpdateSpacePayload {
  name?: string
  description?: string
  capacity?: number
  isActive?: boolean
  pricePerHour?: number
  amenities?: string[]
  rules?: string
  virtualTourUrl?: string
  cancellationPolicy?: 'flexible' | 'moderate' | 'strict'
  address?: string
  city?: string
  state?: string
  country?: string
  latitude?: number
  longitude?: number
  zipCode?: string
  workingHours?: WorkingHours
  imageUrl?: string
  images?: (string | { url: string })[]
  videos?: Array<{ url: string }>
  images360?: Array<{ url: string }>
  imagesToDelete?: string[] // publicIds de Cloudinary a eliminar
}
