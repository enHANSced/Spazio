// Tipos para el sistema de reseñas y calificaciones

export interface ReviewUser {
  id: string
  name: string
}

export interface ReviewSpace {
  id: string
  name: string
  image: string | null
}

export interface OwnerResponse {
  text: string | null
  respondedAt: string | null
}

export interface Review {
  _id: string
  bookingId: string
  userId: string
  ownerId: string
  spaceId: string
  rating: number
  comment: string
  isActive: boolean
  ownerResponse: OwnerResponse | null
  createdAt: string
  updatedAt: string
  // Datos enriquecidos
  user: ReviewUser | null
  space: ReviewSpace | null
}

export interface Pagination {
  total: number
  page: number
  limit: number
  totalPages: number
}

export interface RatingDistribution {
  '1': number
  '2': number
  '3': number
  '4': number
  '5': number
}

export interface OwnerInfo {
  id: string
  name: string
  businessName: string | null
  isVerified: boolean
  memberSince: string
}

export interface OwnerStatsData {
  spacesCount: number
  totalBookings: number
  completedBookings: number
  totalReviews: number
  averageRating: number
  ratingDistribution: RatingDistribution
}

export interface OwnerStats {
  owner: OwnerInfo
  stats: OwnerStatsData
}

export interface SpaceStats {
  spaceId: string
  spaceName: string
  completedBookings: number
  totalReviews: number
  averageRating: number
}

export interface CanReviewResult {
  canReview: boolean
  reason?: string
}

// API Response types
export interface ReviewsApiResponse {
  success: boolean
  data: Review[]
  pagination: Pagination
  message?: string
}

export interface ReviewApiResponse {
  success: boolean
  data: Review
  message?: string
}

export interface OwnerStatsApiResponse {
  success: boolean
  data: OwnerStats
  message?: string
}

export interface SpaceStatsApiResponse {
  success: boolean
  data: SpaceStats
  message?: string
}

export interface CanReviewApiResponse {
  success: boolean
  data: CanReviewResult
  message?: string
}

export interface CreateReviewData {
  bookingId: string
  rating: number
  comment?: string
}

export interface RespondToReviewData {
  response: string
}
