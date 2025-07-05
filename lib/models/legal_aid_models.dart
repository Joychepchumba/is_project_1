class ExpertiseArea {
  final int id;
  final String name;
  final String? description;

  ExpertiseArea({required this.id, required this.name, this.description});

  factory ExpertiseArea.fromJson(Map<String, dynamic> json) {
    return ExpertiseArea(
      id: json['id'],
      name: json['name'],
      description: json['description'], // <-- will be null, and that's fine now
    );
  }
}

class LegalAidRequest {
  final String userId;
  final String legalAidProviderId;
  final String title;
  final String description;
  final DateTime createdAt;
  final String status;

  LegalAidRequest({
    required this.userId,
    required this.legalAidProviderId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory LegalAidRequest.fromJson(Map<String, dynamic> json) {
    return LegalAidRequest(
      userId: json['user_id'],
      legalAidProviderId: json['legal_aid_provider_id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }
}
