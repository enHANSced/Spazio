<template>
  <div class="max-w-6xl mx-auto px-4 py-8">
    <!-- Header con Título y Acciones -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Perfil de Propietario</h1>
        <p class="mt-1 text-gray-500">
          Gestiona tu información personal y los detalles de tu negocio
        </p>
      </div>
      <div class="flex gap-3">
        <button
          type="button"
          @click="resetForm"
          :disabled="isSubmitting || !hasChanges"
          class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          Cancelar
        </button>
        <button
          @click="handleSubmit"
          :disabled="isSubmitting || !hasChanges"
          class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm transition-all flex items-center gap-2"
        >
          <svg v-if="isSubmitting" class="animate-spin h-4 w-4" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none" />
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          {{ isSubmitting ? 'Guardando...' : 'Guardar Cambios' }}
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="grid grid-cols-1 lg:grid-cols-3 gap-8 animate-pulse">
      <div class="lg:col-span-1 space-y-6">
        <div class="h-64 bg-gray-200 rounded-xl"></div>
        <div class="h-32 bg-gray-200 rounded-xl"></div>
      </div>
      <div class="lg:col-span-2 space-y-6">
        <div class="h-96 bg-gray-200 rounded-xl"></div>
        <div class="h-64 bg-gray-200 rounded-xl"></div>
      </div>
    </div>

    <!-- Contenido Principal -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      
      <!-- Columna Izquierda: Resumen y Estado -->
      <div class="lg:col-span-1 space-y-6">
        <!-- Tarjeta de Perfil -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="h-24 bg-gradient-to-r from-blue-500 to-indigo-600"></div>
          <div class="px-6 pb-6">
            <div class="relative flex justify-center -mt-12 mb-4">
              <div class="w-24 h-24 rounded-full border-4 border-white bg-white shadow-md flex items-center justify-center overflow-hidden">
                <span class="text-3xl font-bold text-blue-600 select-none">
                  {{ getInitials(profile.name) }}
                </span>
              </div>
            </div>
            <div class="text-center mb-6">
              <h2 class="text-xl font-bold text-gray-900">{{ profile.name }}</h2>
              <p class="text-sm text-gray-500">{{ profile.email }}</p>
            </div>
            
            <!-- Estado de Verificación -->
            <div
              :class="[
                'rounded-lg p-4 border flex items-start gap-3',
                profile.isVerified
                  ? 'bg-green-50 border-green-100'
                  : 'bg-amber-50 border-amber-100'
              ]"
            >
              <div :class="['mt-0.5', profile.isVerified ? 'text-green-600' : 'text-amber-600']">
                <svg v-if="profile.isVerified" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 :class="['text-sm font-semibold', profile.isVerified ? 'text-green-900' : 'text-amber-900']">
                  {{ profile.isVerified ? 'Cuenta Verificada' : 'Verificación Pendiente' }}
                </h3>
                <p :class="['text-xs mt-1', profile.isVerified ? 'text-green-700' : 'text-amber-700']">
                  {{ profile.isVerified 
                    ? 'Tu cuenta está activa y visible para los usuarios.' 
                    : 'Tu perfil está siendo revisado por nuestro equipo.' 
                  }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Tips o Ayuda Rápida -->
        <div class="bg-blue-50 rounded-xl p-6 border border-blue-100">
          <h3 class="text-sm font-semibold text-blue-900 mb-2">¿Necesitas ayuda?</h3>
          <p class="text-sm text-blue-700 mb-4">
            Mantén tu perfil actualizado para generar más confianza en tus clientes potenciales.
          </p>
          <a href="#" class="text-sm font-medium text-blue-600 hover:text-blue-800 hover:underline">
            Ver guía de mejores prácticas &rarr;
          </a>
        </div>
      </div>

      <!-- Columna Derecha: Formulario -->
      <div class="lg:col-span-2 space-y-6">
        <form @submit.prevent="handleSubmit">
          
          <!-- Sección: Información Básica -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              Información Personal
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="col-span-2 md:col-span-1">
                <label for="name" class="block text-sm font-medium text-gray-700 mb-1">Nombre completo</label>
                <input
                  id="name"
                  v-model="form.name"
                  type="text"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  :class="{'border-red-300 focus:ring-red-200 focus:border-red-400': errors.name}"
                />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div class="col-span-2 md:col-span-1">
                <label class="block text-sm font-medium text-gray-700 mb-1">Correo electrónico</label>
                <input
                  :value="profile.email"
                  disabled
                  class="w-full px-4 py-2 rounded-lg border border-gray-200 bg-gray-50 text-gray-500 cursor-not-allowed"
                />
              </div>
            </div>
          </div>

          <!-- Sección: Detalles del Negocio -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
              Perfil de Negocio
            </h3>
            <div class="space-y-6">
              <div>
                <label for="businessName" class="block text-sm font-medium text-gray-700 mb-1">Nombre del Negocio</label>
                <input
                  id="businessName"
                  v-model="form.businessName"
                  type="text"
                  placeholder="Ej. Espacios Creativos HN"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  :class="{'border-red-300 focus:ring-red-200 focus:border-red-400': errors.businessName}"
                />
                <p v-if="errors.businessName" class="mt-1 text-xs text-red-600">{{ errors.businessName }}</p>
              </div>
              <div>
                <label for="businessDescription" class="block text-sm font-medium text-gray-700 mb-1">Descripción</label>
                <textarea
                  id="businessDescription"
                  v-model="form.businessDescription"
                  rows="4"
                  placeholder="Describe brevemente qué tipo de espacios ofreces..."
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
                ></textarea>
                <div class="flex justify-end mt-1">
                  <span class="text-xs text-gray-400">{{ form.businessDescription.length }}/1000</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Sección: Contacto y Redes -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Contacto y Redes Sociales
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Teléfono</label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-4 w-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                  </div>
                  <input
                    v-model="form.phone"
                    type="tel"
                    class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="+504 9999-9999"
                  />
                </div>
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <label class="block text-sm font-medium text-gray-700">WhatsApp</label>
                  <button
                    type="button"
                    @click="copyPhoneToWhatsapp"
                    :disabled="!form.phone.trim()"
                    class="text-xs font-medium text-blue-600 hover:text-blue-800 disabled:text-gray-400 disabled:cursor-not-allowed transition-colors flex items-center gap-1"
                    title="Usar el mismo número de teléfono"
                  >
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                    Mismo que teléfono
                  </button>
                </div>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-4 w-4 text-green-500" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.008-.57-.008-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                  </div>
                  <input
                    v-model="form.whatsappNumber"
                    type="tel"
                    class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="+504 9999-9999"
                  />
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="h-4 w-4 text-pink-600" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                  </svg>
                </div>
                <input
                  v-model="form.instagram"
                  type="url"
                  class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  placeholder="Instagram URL"
                />
              </div>
              
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="h-4 w-4 text-blue-600" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M9 8h-3v4h3v12h5v-12h3.642l.358-4h-4v-1.667c0-.955.192-1.333 1.115-1.333h2.885v-5h-3.808c-3.596 0-5.192 1.583-5.192 4.615v3.385z"/>
                  </svg>
                </div>
                <input
                  v-model="form.facebook"
                  type="url"
                  class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  placeholder="Facebook URL"
                />
              </div>

              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="h-4 w-4 text-blue-700" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M4.98 3.5c0 1.381-1.11 2.5-2.48 2.5s-2.48-1.119-2.48-2.5c0-1.38 1.11-2.5 2.48-2.5s2.48 1.12 2.48 2.5zm.02 4.5h-5v16h5v-16zm7.982 0h-4.968v16h4.969v-8.399c0-4.67 6.029-5.052 6.029 0v8.399h4.988v-10.131c0-7.88-8.922-7.593-11.018-3.714v-2.155z"/>
                  </svg>
                </div>
                <input
                  v-model="form.linkedin"
                  type="url"
                  class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  placeholder="LinkedIn URL"
                />
              </div>
            </div>
          </div>

          <!-- Sección: Información Bancaria para Pagos -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mt-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-2 flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
              </svg>
              Información Bancaria para Pagos
            </h3>
            <p class="text-sm text-gray-500 mb-6">
              Configura tu cuenta bancaria para recibir pagos por transferencia de tus reservas.
            </p>

            <!-- Alerta informativa -->
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
              <div class="flex items-start gap-3">
                <svg class="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div>
                  <p class="text-sm text-blue-900 font-medium">¿Cómo funciona?</p>
                  <p class="text-xs text-blue-700 mt-1">
                    Cuando un usuario elija pagar por transferencia, verá estos datos para realizar el depósito. 
                    Luego podrás verificar el comprobante de pago desde el panel de reservas.
                  </p>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Banco -->
              <div>
                <label for="bankName" class="block text-sm font-medium text-gray-700 mb-1">
                  Banco
                </label>
                <select
                  id="bankName"
                  v-model="form.bankName"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors bg-white"
                >
                  <option value="">Selecciona un banco</option>
                  <option v-for="bank in HONDURAS_BANKS" :key="bank" :value="bank">
                    {{ bank }}
                  </option>
                </select>
              </div>

              <!-- Tipo de Cuenta -->
              <div>
                <label for="bankAccountType" class="block text-sm font-medium text-gray-700 mb-1">
                  Tipo de Cuenta
                </label>
                <select
                  id="bankAccountType"
                  v-model="form.bankAccountType"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors bg-white"
                >
                  <option value="">Selecciona tipo de cuenta</option>
                  <option value="ahorro_lempiras">Ahorro (Lempiras)</option>
                  <option value="ahorro_dolares">Ahorro (Dólares)</option>
                  <option value="corriente_lempiras">Corriente (Lempiras)</option>
                  <option value="corriente_dolares">Corriente (Dólares)</option>
                </select>
              </div>

              <!-- Número de Cuenta -->
              <div>
                <label for="bankAccountNumber" class="block text-sm font-medium text-gray-700 mb-1">
                  Número de Cuenta
                </label>
                <input
                  id="bankAccountNumber"
                  v-model="form.bankAccountNumber"
                  type="text"
                  placeholder="Ej: 123456789012"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                />
                <p class="text-xs text-gray-500 mt-1">
                  Este número se mostrará a los usuarios que paguen por transferencia
                </p>
              </div>

              <!-- Nombre del Titular -->
              <div>
                <label for="bankAccountHolder" class="block text-sm font-medium text-gray-700 mb-1">
                  Nombre del Titular
                </label>
                <input
                  id="bankAccountHolder"
                  v-model="form.bankAccountHolder"
                  type="text"
                  placeholder="Nombre como aparece en la cuenta"
                  class="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                />
              </div>
            </div>

            <!-- Preview de cómo se verá -->
            <div v-if="form.bankName && form.bankAccountNumber" class="mt-6 p-4 bg-gray-50 rounded-lg border border-gray-200">
              <p class="text-xs font-medium text-gray-500 mb-3 uppercase tracking-wider">Vista previa (cómo lo verán los usuarios)</p>
              <div class="bg-white rounded-lg p-4 border border-gray-200">
                <div class="flex items-center gap-2 mb-3">
                  <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                  <span class="font-semibold text-gray-900">Datos para Transferencia</span>
                </div>
                <div class="space-y-2 text-sm">
                  <p><span class="text-gray-500">Banco:</span> <span class="font-medium text-gray-900">{{ form.bankName }}</span></p>
                  <p v-if="form.bankAccountType"><span class="text-gray-500">Tipo:</span> <span class="font-medium text-gray-900">{{ formatAccountType(form.bankAccountType) }}</span></p>
                  <p><span class="text-gray-500">Cuenta:</span> <span class="font-medium text-gray-900 font-mono">{{ form.bankAccountNumber }}</span></p>
                  <p v-if="form.bankAccountHolder"><span class="text-gray-500">Titular:</span> <span class="font-medium text-gray-900">{{ form.bankAccountHolder }}</span></p>
                </div>
              </div>
            </div>
          </div>

        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { usersService } from '~/services/users.service'
import { HONDURAS_BANKS, type BankAccountType, type HondurasBank } from '~/types/auth'

definePageMeta({
  layout: 'owner',
  middleware: ['auth', 'owner']
})

const toast = useToast()

const loading = ref(true)
const isSubmitting = ref(false)

const profile = ref({
  email: '',
  name: '',
  businessName: '',
  businessDescription: '',
  isVerified: false,
  phone: '',
  whatsappNumber: '',
  instagram: '',
  facebook: '',
  linkedin: '',
  // Información bancaria
  bankName: '' as HondurasBank | '',
  bankAccountType: '' as BankAccountType | '',
  bankAccountNumber: '',
  bankAccountHolder: ''
})

const form = reactive({
  name: '',
  businessName: '',
  businessDescription: '',
  phone: '',
  whatsappNumber: '',
  instagram: '',
  facebook: '',
  linkedin: '',
  // Información bancaria
  bankName: '' as HondurasBank | '',
  bankAccountType: '' as BankAccountType | '',
  bankAccountNumber: '',
  bankAccountHolder: ''
})

const errors = reactive({
  name: '',
  businessName: ''
})

// Computed para detectar cambios
const hasChanges = computed(() => {
  return form.name !== profile.value.name ||
    form.businessName !== profile.value.businessName ||
    form.businessDescription !== profile.value.businessDescription ||
    form.phone !== profile.value.phone ||
    form.whatsappNumber !== profile.value.whatsappNumber ||
    form.instagram !== profile.value.instagram ||
    form.facebook !== profile.value.facebook ||
    form.linkedin !== profile.value.linkedin ||
    form.bankName !== profile.value.bankName ||
    form.bankAccountType !== profile.value.bankAccountType ||
    form.bankAccountNumber !== profile.value.bankAccountNumber ||
    form.bankAccountHolder !== profile.value.bankAccountHolder
})

// Helper para formatear tipo de cuenta
const formatAccountType = (type: BankAccountType | string | null | undefined): string => {
  const types: Record<string, string> = {
    'ahorro_lempiras': 'Ahorro (Lempiras)',
    'ahorro_dolares': 'Ahorro (Dólares)',
    'corriente_lempiras': 'Corriente (Lempiras)',
    'corriente_dolares': 'Corriente (Dólares)'
  }
  return types[type || ''] || ''
}

// Helper para enmascarar número de cuenta (para mostrar en el perfil del owner)
const maskAccountNumber = (number: string | null | undefined): string => {
  if (!number || number.length < 4) return number || ''
  return '*'.repeat(number.length - 4) + number.slice(-4)
}

// Helper para iniciales
const getInitials = (name: string) => {
  if (!name) return 'U'
  return name
    .split(' ')
    .map(n => n[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
}

// Cargar perfil
const loadProfile = async () => {
  try {
    loading.value = true
    const response = await usersService.getMyProfile()

    if (response.success && response.data) {
      profile.value = {
        email: response.data.email || '',
        name: response.data.name || '',
        businessName: response.data.businessName || '',
        businessDescription: response.data.businessDescription || '',
        isVerified: response.data.isVerified ?? false,
        phone: response.data.phone || '',
        whatsappNumber: response.data.whatsappNumber || '',
        instagram: response.data.instagram || '',
        facebook: response.data.facebook || '',
        linkedin: response.data.linkedin || '',
        // Información bancaria
        bankName: response.data.bankName || '',
        bankAccountType: response.data.bankAccountType || '',
        bankAccountNumber: response.data.bankAccountNumber || '',
        bankAccountHolder: response.data.bankAccountHolder || ''
      }

      // Copiar al formulario
      Object.assign(form, {
        name: profile.value.name,
        businessName: profile.value.businessName,
        businessDescription: profile.value.businessDescription,
        phone: profile.value.phone,
        whatsappNumber: profile.value.whatsappNumber,
        instagram: profile.value.instagram,
        facebook: profile.value.facebook,
        linkedin: profile.value.linkedin,
        // Información bancaria
        bankName: profile.value.bankName,
        bankAccountType: profile.value.bankAccountType,
        bankAccountNumber: profile.value.bankAccountNumber,
        bankAccountHolder: profile.value.bankAccountHolder
      })
    }
  } catch (error: any) {
    console.error('Error loading profile:', error)
    toast.error('Error al cargar el perfil')
  } finally {
    loading.value = false
  }
}

// Validar formulario
const validateForm = (): boolean => {
  let isValid = true
  errors.name = ''
  errors.businessName = ''

  if (!form.name.trim()) {
    errors.name = 'El nombre es requerido'
    isValid = false
  } else if (form.name.length < 2) {
    errors.name = 'El nombre debe tener al menos 2 caracteres'
    isValid = false
  }

  if (form.businessName && form.businessName.length < 2) {
    errors.businessName = 'El nombre del negocio debe tener al menos 2 caracteres'
    isValid = false
  }

  return isValid
}

// Enviar cambios
const handleSubmit = async () => {
  if (!validateForm()) {
    toast.error('Por favor corrige los errores antes de continuar')
    return
  }

  isSubmitting.value = true

  try {
    const response = await usersService.updateMyProfile({
      name: form.name.trim(),
      businessName: form.businessName.trim(),
      businessDescription: form.businessDescription.trim(),
      phone: form.phone.trim(),
      whatsappNumber: form.whatsappNumber.trim(),
      instagram: form.instagram.trim(),
      facebook: form.facebook.trim(),
      linkedin: form.linkedin.trim(),
      // Información bancaria
      bankName: form.bankName || null,
      bankAccountType: form.bankAccountType || null,
      bankAccountNumber: form.bankAccountNumber.trim() || null,
      bankAccountHolder: form.bankAccountHolder.trim() || null
    })

    if (response.success) {
      toast.success('Perfil actualizado exitosamente')
      await loadProfile()
    } else {
      toast.error(response.message || 'Error al actualizar el perfil')
    }
  } catch (error: any) {
    console.error('Error updating profile:', error)
    const errorMessage = error.data?.message || error.message || 'Error al actualizar el perfil'
    toast.error(errorMessage)
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  Object.assign(form, {
    name: profile.value.name,
    businessName: profile.value.businessName,
    businessDescription: profile.value.businessDescription,
    phone: profile.value.phone,
    whatsappNumber: profile.value.whatsappNumber,
    instagram: profile.value.instagram,
    facebook: profile.value.facebook,
    linkedin: profile.value.linkedin,
    // Información bancaria
    bankName: profile.value.bankName,
    bankAccountType: profile.value.bankAccountType,
    bankAccountNumber: profile.value.bankAccountNumber,
    bankAccountHolder: profile.value.bankAccountHolder
  })
  errors.name = ''
  errors.businessName = ''
}

// Copiar teléfono a WhatsApp
const copyPhoneToWhatsapp = () => {
  if (form.phone.trim()) {
    form.whatsappNumber = form.phone
    toast.success('Número copiado a WhatsApp')
  }
}

// Cargar al montar
onMounted(() => {
  loadProfile()
})
</script>
