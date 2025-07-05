// lib/constants/api_constants.dart

class ApiConstants {
  // Replace with your actual API base URL
  static const String baseUrl =
      'https://8088-197-136-185-70.ngrok-free.app'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // For iOS simulator
  // static const String baseUrl = 'http://your-production-url.com'; // For production

  // API endpoints
  static const String legalTipsEndpoint = '/api/v1/legal-tips';
  static const String uploadEndpoint = '/api/v1/legal-tips/upload-image';

  // Helper method to get full URL for relative paths
  static String getFullUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    return '$baseUrl$relativePath';
  }

  // Helper method to get full image URL
  static String? getFullImageUrl(String? imagePath) {
    if (imagePath == null) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return '$baseUrl$imagePath';
  }
}
