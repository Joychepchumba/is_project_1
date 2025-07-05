// models/legal_tips.dart
import '../constants/api_constants.dart';

class LegalTip {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final TipStatus status;
  final String legalAidProviderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final LegalAidProvider? legalAidProvider;

  // Computed property for full image URL
  String? get fullImageUrl {
    return ApiConstants.getFullImageUrl(imageUrl);
  }

  LegalTip({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.legalAidProviderId,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.legalAidProvider,
  });

  factory LegalTip.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing LegalTip JSON: $json'); // Debug log

      return LegalTip(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled',
        description:
            json['description']?.toString() ?? 'No description available',
        imageUrl: json['image_url']?.toString(),
        status: _parseStatus(json['status']),
        legalAidProviderId: json['legal_aid_provider_id']?.toString() ?? '',
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
        publishedAt: _parseDateTime(json['published_at']),
        legalAidProvider: json['legal_aid_provider'] != null
            ? LegalAidProvider.fromJson(json['legal_aid_provider'])
            : null,
      );
    } catch (e) {
      print('Error parsing LegalTip from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static TipStatus _parseStatus(dynamic status) {
    if (status == null) return TipStatus.draft;

    String statusStr = status.toString().toLowerCase();
    return TipStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == statusStr,
      orElse: () => TipStatus.draft,
    );
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      } else {
        return null;
      }
    } catch (e) {
      print('Error parsing DateTime: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'status': status.toString().split('.').last,
      'legal_aid_provider_id': legalAidProviderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'legal_aid_provider': legalAidProvider?.toJson(),
    };
  }

  LegalTip copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    TipStatus? status,
    String? legalAidProviderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    LegalAidProvider? legalAidProvider,
  }) {
    return LegalTip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      legalAidProviderId: legalAidProviderId ?? this.legalAidProviderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      legalAidProvider: legalAidProvider ?? this.legalAidProvider,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegalTip &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.status == status &&
        other.legalAidProviderId == legalAidProviderId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.publishedAt == publishedAt &&
        other.legalAidProvider == legalAidProvider;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      imageUrl,
      status,
      legalAidProviderId,
      createdAt,
      updatedAt,
      publishedAt,
      legalAidProvider,
    );
  }

  @override
  String toString() {
    return 'LegalTip(id: $id, title: $title, description: $description, imageUrl: $imageUrl, status: $status, legalAidProviderId: $legalAidProviderId, createdAt: $createdAt, updatedAt: $updatedAt, publishedAt: $publishedAt, legalAidProvider: $legalAidProvider)';
  }
}

enum TipStatus { draft, published, archived, deleted }

// Updated LegalAidProvider class to match your database schema
class LegalAidProvider {
  final String id;
  final String? fullName; // Changed from 'name' to 'fullName' to match DB
  final String? phoneNumber; // Added to match DB
  final String? email; // Added to match DB
  final String? pskNumber; // Added to match DB
  final String? status; // Added to match DB
  final String? profileImage; // Added to match DB
  final String? about; // Added to match DB
  final String? description; // Keep for backward compatibility
  final String? contactInfo; // Keep for backward compatibility
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalAidProvider({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.pskNumber,
    this.status,
    this.profileImage,
    this.about,
    this.description,
    this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed property for display name
  String get displayName => fullName ?? 'Unknown Provider';

  // Keep 'name' getter for backward compatibility
  String get name => fullName ?? 'Unknown Provider';

  // Computed property for full image URL
  String? get fullImageUrl {
    return ApiConstants.getFullImageUrl(profileImage);
  }

  factory LegalAidProvider.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing LegalAidProvider JSON: $json'); // Debug log

      return LegalAidProvider(
        id: json['id']?.toString() ?? '',
        fullName: json['full_name']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        email: json['email']?.toString(),
        pskNumber: json['psk_number']?.toString(),
        status: json['status']?.toString(),
        profileImage: json['profile_image']?.toString(),
        about: json['about']?.toString(),
        description: json['description']?.toString(),
        contactInfo: json['contact_info']?.toString(),
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing LegalAidProvider from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print('Error parsing DateTime: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'psk_number': pskNumber,
      'status': status,
      'profile_image': profileImage,
      'about': about,
      'description': description,
      'contact_info': contactInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LegalAidProvider copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? pskNumber,
    String? status,
    String? profileImage,
    String? about,
    String? description,
    String? contactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LegalAidProvider(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      pskNumber: pskNumber ?? this.pskNumber,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      about: about ?? this.about,
      description: description ?? this.description,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegalAidProvider &&
        other.id == id &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.pskNumber == pskNumber &&
        other.status == status &&
        other.profileImage == profileImage &&
        other.about == about &&
        other.description == description &&
        other.contactInfo == contactInfo &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      phoneNumber,
      email,
      pskNumber,
      status,
      profileImage,
      about,
      description,
      contactInfo,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'LegalAidProvider(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, email: $email, pskNumber: $pskNumber, status: $status, profileImage: $profileImage, about: $about, description: $description, contactInfo: $contactInfo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class CreateLegalTipRequest {
  final String title;
  final String description;
  final String? imageBase64;
  final TipStatus status;
  final String legalAidProviderId;

  CreateLegalTipRequest({
    required this.title,
    required this.description,
    this.imageBase64,
    this.status = TipStatus.draft,
    required this.legalAidProviderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image_base64': imageBase64,
      'status': status.toString().split('.').last,
      'legal_aid_provider_id': legalAidProviderId,
    };
  }
}

class UpdateLegalTipRequest {
  final String? title;
  final String? description;
  final String? imageBase64;
  final TipStatus? status;

  UpdateLegalTipRequest({
    this.title,
    this.description,
    this.imageBase64,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (imageBase64 != null) json['image_base64'] = imageBase64;
    if (status != null) json['status'] = status.toString().split('.').last;
    return json;
  }
}
