// legal_tips_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:is_project_1/models/legal_tips_models.dart';
import 'package:is_project_1/services/api_service.dart';

// Models

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}

class LegalTipsService {
  static String baseUrl =
      'https://8088-197-136-185-70.ngrok-free.app'; // Initialize with default value

  Future<Map<String, String>> _headers() async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception("Missing auth token");
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Convert File to base64
  Future<String> _fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Determine MIME type
      String mimeType = 'image/jpeg'; // default
      final extension = file.path.split('.').last.toLowerCase();

      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      throw Exception('Error converting image to base64: $e');
    }
  }

  // Create legal tip
  Future<ApiResponse<LegalTip>> createLegalTip({
    required String title,
    required String description,
    File? imageFile,
    TipStatus status = TipStatus.draft,
    required String legalAidProviderId,
  }) async {
    try {
      String? imageBase64;
      if (imageFile != null) {
        imageBase64 = await _fileToBase64(imageFile);
      }

      final request = CreateLegalTipRequest(
        title: title,
        description: description,
        imageBase64: imageBase64,
        status: status,
        legalAidProviderId: legalAidProviderId,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/legal-tips/create'),
        headers: await _headers(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: true,
          data: LegalTip.fromJson(data),
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: false,
          error: error['detail'] ?? 'Failed to create legal tip',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<LegalTip>(success: false, error: 'Network error: $e');
    }
  }

  // Update legal tip
  Future<ApiResponse<LegalTip>> updateLegalTip({
    required String tipId,
    String? title,
    String? description,
    File? imageFile,
    bool? removeImage,
    TipStatus? status,
  }) async {
    try {
      String? imageBase64;

      if (removeImage == true) {
        imageBase64 = ''; // Empty string to remove image
      } else if (imageFile != null) {
        imageBase64 = await _fileToBase64(imageFile);
      }

      final request = UpdateLegalTipRequest(
        title: title,
        description: description,
        imageBase64: imageBase64,
        status: status,
      );

      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/legal-tips/$tipId/update'),
        headers: await _headers(), // Fixed: await the headers
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: true,
          data: LegalTip.fromJson(data),
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: false,
          error: error['detail'] ?? 'Failed to update legal tip',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<LegalTip>(success: false, error: 'Network error: $e');
    }
  }

  // Get all legal tips
  Future<ApiResponse<List<LegalTip>>> getLegalTips({
    int skip = 0,
    int limit = 100,
    TipStatus? statusFilter,
    String? providerId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (statusFilter != null) {
        queryParams['status_filter'] = statusFilter.toString().split('.').last;
      }
      if (providerId != null) {
        queryParams['provider_id'] = providerId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/legal-tips',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _headers(),
      ); // Fixed: await the headers

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tips = data.map((json) => LegalTip.fromJson(json)).toList();
        return ApiResponse<List<LegalTip>>(success: true, data: tips);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<LegalTip>>(
          success: false,
          error: error['detail'] ?? 'Failed to fetch legal tips',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<LegalTip>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get specific legal tip
  Future<ApiResponse<LegalTip>> getLegalTip(String tipId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/legal-tips/$tipId'),
        headers: await _headers(), // Fixed: await the headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: true,
          data: LegalTip.fromJson(data),
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: false,
          error: error['detail'] ?? 'Failed to fetch legal tip',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<LegalTip>(success: false, error: 'Network error: $e');
    }
  }

  // Update tip status
  Future<ApiResponse<LegalTip>> updateTipStatus({
    required String tipId,
    required TipStatus status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/legal-tips/$tipId/status'),
        headers: await _headers(), // Fixed: await the headers
        body: jsonEncode({'new_status': status.toString().split('.').last}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: true,
          data: LegalTip.fromJson(data),
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<LegalTip>(
          success: false,
          error: error['detail'] ?? 'Failed to update tip status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<LegalTip>(success: false, error: 'Network error: $e');
    }
  }

  // Delete legal tip
  Future<ApiResponse<void>> deleteLegalTip(String tipId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/legal-tips/$tipId'),
        headers: await _headers(), // Fixed: await the headers
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<void>(
          success: false,
          error: error['detail'] ?? 'Failed to delete legal tip',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(success: false, error: 'Network error: $e');
    }
  }

  // Get tips by provider
  Future<ApiResponse<List<LegalTip>>> getTipsByProvider({
    required String providerId,
    int skip = 0,
    int limit = 100,
    TipStatus? statusFilter,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (statusFilter != null) {
        queryParams['status_filter'] = statusFilter.toString().split('.').last;
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/legal-tips/provider/$providerId',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _headers(),
      ); // Fixed: await the headers

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tips = data.map((json) => LegalTip.fromJson(json)).toList();
        return ApiResponse<List<LegalTip>>(success: true, data: tips);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<LegalTip>>(
          success: false,
          error: error['detail'] ?? 'Failed to fetch provider tips',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<LegalTip>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get recent published tips
  Future<ApiResponse<List<LegalTip>>> getRecentPublishedTips({
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/legal-tips/published/recent?limit=$limit'),
        headers: await _headers(), // Fixed: await the headers
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tips = data.map((json) => LegalTip.fromJson(json)).toList();
        return ApiResponse<List<LegalTip>>(success: true, data: tips);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<List<LegalTip>>(
          success: false,
          error: error['detail'] ?? 'Failed to fetch recent tips',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<LegalTip>>(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Upload base64 image separately
  Future<ApiResponse<String>> uploadBase64Image({
    required String base64Data,
    String? filename,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/legal-tips/upload-base64-image'),
        headers: await _headers(), // Fixed: await the headers
        body: jsonEncode({'image_data': base64Data, 'filename': filename}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse<String>(success: true, data: data['image_url']);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<String>(
          success: false,
          error: error['detail'] ?? 'Failed to upload image',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<String>(success: false, error: 'Network error: $e');
    }
  }

  // Helper method to publish a draft tip
  Future<ApiResponse<LegalTip>> publishTip(String tipId) async {
    return updateTipStatus(tipId: tipId, status: TipStatus.published);
  }

  // Helper method to save as draft
  Future<ApiResponse<LegalTip>> saveAsDraft(String tipId) async {
    return updateTipStatus(tipId: tipId, status: TipStatus.draft);
  }

  // Helper method to archive tip
  Future<ApiResponse<LegalTip>> archiveTip(String tipId) async {
    return updateTipStatus(tipId: tipId, status: TipStatus.archived);
  }

  static Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
      baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    } catch (e) {
      print('Error loading .env file: $e');
      baseUrl = 'http://localhost:8000';
    }
  }
}
