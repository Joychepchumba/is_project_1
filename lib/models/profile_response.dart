// Updated ProfileResponse to handle multiple expertise areas
class ProfileResponse {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String userType;
  final int roleId;
  final List<ExpertiseArea>
  expertiseAreas; // Changed from single string to list
  final EmergencyContact? emergencyContact; // Added emergency contact

  ProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    required this.userType,
    required this.roleId,
    this.expertiseAreas = const [],
    this.emergencyContact,
  });

  // Helper function for safe integer parsing
  static int safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Updated fromJson with safer parsing
  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: safeParseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      profileImage: json['profile_image']?.toString(),
      userType: json['user_type']?.toString() ?? 'user',
      roleId: safeParseInt(json['role_id']),
      expertiseAreas: _parseExpertiseAreas(json['expertise_areas']),
      emergencyContact: json['emergency_contact'] != null
          ? EmergencyContact.fromJson(json['emergency_contact'])
          : null,
    );
  }

  // Helper method to parse expertise areas
  static List<ExpertiseArea> _parseExpertiseAreas(dynamic expertiseData) {
    if (expertiseData == null) return [];

    if (expertiseData is List) {
      return expertiseData
          .map((item) => ExpertiseArea.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  // Helper method to get expertise areas as a formatted string
  String get expertiseAreasString {
    if (expertiseAreas.isEmpty) return '';
    return expertiseAreas.map((area) => area.name).join(', ');
  }

  // Helper method to get expertise area IDs as a list
  List<int> get expertiseAreaIds {
    return expertiseAreas.map((area) => area.id).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'user_type': userType,
      'role_id': roleId,
      'expertise_areas': expertiseAreas.map((area) => area.toJson()).toList(),
      'emergency_contact': emergencyContact?.toJson(),
    };
  }
}

// New ExpertiseArea model
class ExpertiseArea {
  final int id;
  final String name;

  ExpertiseArea({required this.id, required this.name});

  factory ExpertiseArea.fromJson(Map<String, dynamic> json) {
    return ExpertiseArea(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpertiseArea && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => name;
}

// Updated EmergencyContact model
class EmergencyContact {
  final int id;
  final String contactName;
  final String contactNumber;
  final String? emailContact;

  EmergencyContact({
    required this.id,
    required this.contactName,
    required this.contactNumber,
    this.emailContact,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: ProfileResponse.safeParseInt(json['id']), // Use safe parsing
      contactName: json['contact_name']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      emailContact: json['email_contact']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_name': contactName,
      'contact_number': contactNumber,
      'email_contact': emailContact,
    };
  }

  // Getter methods for backward compatibility or convenience
  String get phoneNumber => contactNumber;
  String get name => contactName;
}

// Additional helper class for handling different user types
class UserProfile {
  final ProfileResponse profile;
  final bool isLegalAidProvider;
  final bool isSafetyConcernedIndividual;

  UserProfile({required this.profile})
    : isLegalAidProvider = profile.roleId == 6,
      isSafetyConcernedIndividual = profile.roleId == 5;

  // Convenience getters
  String get displayName => profile.name;
  String get email => profile.email;
  String? get phoneNumber => profile.phoneNumber;
  String? get profileImage => profile.profileImage;
  List<ExpertiseArea> get expertiseAreas => profile.expertiseAreas;
  EmergencyContact? get emergencyContact => profile.emergencyContact;

  // Helper method to check if user has specific expertise
  bool hasExpertise(String expertiseName) {
    return profile.expertiseAreas.any(
      (area) => area.name.toLowerCase() == expertiseName.toLowerCase(),
    );
  }

  // Helper method to get formatted expertise display
  String getExpertiseDisplay() {
    if (!isLegalAidProvider || profile.expertiseAreas.isEmpty) {
      return '';
    }

    if (profile.expertiseAreas.length == 1) {
      return profile.expertiseAreas.first.name;
    } else if (profile.expertiseAreas.length <= 3) {
      return profile.expertiseAreas.map((e) => e.name).join(', ');
    } else {
      return '${profile.expertiseAreas.take(2).map((e) => e.name).join(', ')} +${profile.expertiseAreas.length - 2} more';
    }
  }
}
