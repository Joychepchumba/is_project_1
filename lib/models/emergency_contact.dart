// Emergency Contact Model
// Create this file as models/emergency_contact.dart

class EmergencyContact2 {
  final int id;
  final String contactName;
  final String contactNumber;

  EmergencyContact2({
    required this.id,
    required this.contactName,
    required this.contactNumber,
  });

  factory EmergencyContact2.fromJson(Map<String, dynamic> json) {
    return EmergencyContact2(
      id: json['id'],
      contactName: json['name'],
      contactNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': contactName, 'phone_number': contactNumber};
  }

  @override
  String toString() {
    return 'EmergencyContact{id: $id, name: $contactName, phoneNumber: $contactNumber}';
  }
}
