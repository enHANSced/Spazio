import type { Space, SpaceApiResponse, SpacesApiResponse } from '../types/space'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

export class SpacesService {
  static async list(): Promise<Space[]> {
    try {
      const response = await $fetch<SpacesApiResponse>(buildApiUrl('/spaces'))

      if (!response.success) {
        throw new Error(response.message || 'No fue posible cargar los espacios disponibles')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  static async detail(id: string): Promise<Space> {
    try {
      const response = await $fetch<SpaceApiResponse>(buildApiUrl(`/spaces/${id}`))

      if (!response.success) {
        throw new Error(response.message || 'No fue posible obtener el espacio solicitado')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export default SpacesService
