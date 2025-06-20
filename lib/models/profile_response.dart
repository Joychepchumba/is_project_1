class ProfileResponse {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String userType;
  final int roleId;
  final String? expertiseArea; // Only for legal_aid users

  ProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    required this.userType,
    required this.roleId,
    this.expertiseArea,
  });

  // Helper function for safe integer parsing

  // Updated fromJson with safer parsing
  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ProfileResponse(
      id: safeParseInt(json['id']), // Safely handle int/double/string
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      profileImage: json['profile_image']?.toString(),
      userType: json['user_type']?.toString() ?? 'user',
      roleId: safeParseInt(json['role_id']),
      expertiseArea: json['expertise_area']?.toString(),
    );
  }
}

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
      id: json['id'] as int,
      contactName: json['contact_name'] as String,
      contactNumber: json['contact_number'] as String,
      emailContact: json['email_contact'] as String?,
    );
  }

  Null get phoneNumber => null;

  Null get name => null;
}
