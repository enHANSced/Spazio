import type { Space, SpaceApiResponse, SpacesApiResponse, CreateSpacePayload, UpdateSpacePayload } from '../types/space'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

export class OwnerSpacesService {
  /**
   * Obtener todos los espacios del propietario autenticado
   */
  static async getMySpaces(token: string): Promise<Space[]> {
    try {
      const response = await $fetch<SpacesApiResponse>(buildApiUrl('/spaces/owner/my-spaces'), {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible cargar tus espacios')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Crear un nuevo espacio
   */
  static async createSpace(token: string, payload: CreateSpacePayload): Promise<Space> {
    try {
      const response = await $fetch<SpaceApiResponse>(buildApiUrl('/spaces'), {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible crear el espacio')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Actualizar un espacio existente
   */
  static async updateSpace(token: string, id: string, payload: UpdateSpacePayload): Promise<Space> {
    try {
      const response = await $fetch<SpaceApiResponse>(buildApiUrl(`/spaces/${id}`), {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible actualizar el espacio')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Eliminar un espacio (soft-delete)
   */
  static async deleteSpace(token: string, id: string): Promise<void> {
    try {
      const response = await $fetch<{ success: boolean; message: string }>(
        buildApiUrl(`/spaces/${id}`),
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${token}`
          }
        }
      )

      if (!response.success) {
        throw new Error(response.message || 'No fue posible eliminar el espacio')
      }
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export default OwnerSpacesService

// Versión con manejo automático de token
export const ownerSpacesService = {
  async getMySpaces() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const response = await $fetch<SpacesApiResponse>(buildApiUrl('/spaces/owner/my-spaces'), {
        headers: { Authorization: `Bearer ${token}` }
      })
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: [], message: extractApiErrorMessage(error) }
    }
  },

  async createSpace(payload: CreateSpacePayload) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const response = await $fetch<SpaceApiResponse>(buildApiUrl('/spaces'), {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: payload
      })
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  async updateSpace(id: string, payload: UpdateSpacePayload) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const response = await $fetch<SpaceApiResponse>(buildApiUrl(`/spaces/${id}`), {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
        body: payload
      })
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  async deleteSpace(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const response = await $fetch<{ success: boolean; message?: string }>(buildApiUrl(`/spaces/${id}`), {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      })
      return { success: response.success, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  }
}
