class AppSession {
  // Datos del usuario (por defecto)
  static String userName = 'Admin';
  static String farmName = 'Hacienda El Paraíso';
  static String? accessToken;

  // Método para limpiar la sesión (para cuando cierre sesión)
  static void clear() {
    userName = 'Admin';
    farmName = 'Hacienda El Paraíso';
    accessToken = null;
  }
}
