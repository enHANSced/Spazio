export interface SpaceOwner {
  id: string
  name?: string | null
  businessName?: string | null
  businessDescription?: string | null
}

export interface Space {
  id: string
  name: string
  description?: string | null
  capacity: number
  ownerId: string
  isActive: boolean
  createdAt: string
  updatedAt: string
  owner?: SpaceOwner | null
  // Preparado para soporte futuro de imágenes
  imageUrl?: string | null
  images?: string[] | null
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
