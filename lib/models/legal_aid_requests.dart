class User {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'].toString(),
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phone_number'],
      );
    } catch (e) {
      print('Error parsing User: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class ExpertiseArea {
  final String id;
  final String name;
  final String? description;

  ExpertiseArea({required this.id, required this.name, this.description});

  factory ExpertiseArea.fromJson(Map<String, dynamic> json) {
    try {
      return ExpertiseArea(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        description: json['description'],
      );
    } catch (e) {
      print('Error parsing ExpertiseArea: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class LegalAidProvider {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String status;
  final String? profileImage;
  final String pskNumber;
  final List<ExpertiseArea> expertiseAreas;
  final DateTime createdAt;
  final String? about;

  LegalAidProvider({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.status,
    this.profileImage,
    required this.pskNumber,
    required this.about,
    required this.expertiseAreas,
    required this.createdAt,
  });

  factory LegalAidProvider.fromJson(Map<String, dynamic> json) {
    try {
      List<ExpertiseArea> expertiseList = [];

      if (json['expertise_areas'] != null) {
        final expertiseData = json['expertise_areas'];
        if (expertiseData is List) {
          expertiseList = expertiseData
              .map((e) => ExpertiseArea.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      return LegalAidProvider(
        id: json['id'].toString(),
        fullName: json['full_name'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        email: json['email'] ?? '',
        status: json['status'] ?? 'unknown',
        profileImage: json['profile_image'],
        pskNumber: json['psk_number'] ?? '',
        about: json['about'],
        expertiseAreas: expertiseList,
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing LegalAidProvider: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  String get primaryExpertise {
    return expertiseAreas.isNotEmpty
        ? expertiseAreas.first.name
        : 'General Law';
  }

  String get allExpertiseAreas {
    return expertiseAreas.map((e) => e.name).join(', ');
  }
}

class LegalAidRequest {
  final String id;
  final String userId;
  final String legalAidProviderId;
  final String title;
  final String description;
  final DateTime createdAt;
  final String status;
  final User? user;
  final LegalAidProvider? legalAidProvider;

  LegalAidRequest({
    required this.id,
    required this.userId,
    required this.legalAidProviderId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
    this.user,
    this.legalAidProvider,
  });

  factory LegalAidRequest.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing LegalAidRequest JSON: $json');

      return LegalAidRequest(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        legalAidProviderId: json['legal_aid_provider_id'].toString(),
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'pending',
        user: json['user'] != null
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        legalAidProvider: json['legal_aid_provider'] != null
            ? LegalAidProvider.fromJson(
                json['legal_aid_provider'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e) {
      print('Error parsing LegalAidRequest: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  String get providerName {
    return legalAidProvider?.fullName ?? 'Unknown Provider';
  }
}
