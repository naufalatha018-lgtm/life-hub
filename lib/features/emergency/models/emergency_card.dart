import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  final String name;
  final String phone;
  final String relationship;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
    );
  }
}

@immutable
class EmergencyCard {
  const EmergencyCard({
    this.bloodType = '',
    this.allergies = '',
    this.medicalNotes = '',
    this.emergencyContacts = const [],
    this.ownerName = '',
    required this.updatedAt,
  });

  final String bloodType;
  final String allergies;
  final String medicalNotes;
  final List<EmergencyContact> emergencyContacts;
  final String ownerName;
  final DateTime updatedAt;

  EmergencyCard copyWith({
    String? bloodType,
    String? allergies,
    String? medicalNotes,
    List<EmergencyContact>? emergencyContacts,
    String? ownerName,
    DateTime? updatedAt,
  }) {
    return EmergencyCard(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      ownerName: ownerName ?? this.ownerName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blood_type': bloodType,
      'allergies': allergies,
      'medical_notes': medicalNotes,
      'emergency_contacts_json': jsonEncode(emergencyContacts.map((c) => c.toJson()).toList()),
      'owner_name': ownerName,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EmergencyCard.fromMap(Map<String, dynamic> map) {
    List<EmergencyContact> contacts = [];
    try {
      final raw = jsonDecode(map['emergency_contacts_json'] as String? ?? '[]');
      contacts = (raw as List).map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    return EmergencyCard(
      bloodType: map['blood_type'] as String? ?? '',
      allergies: map['allergies'] as String? ?? '',
      medicalNotes: map['medical_notes'] as String? ?? '',
      emergencyContacts: contacts,
      ownerName: map['owner_name'] as String? ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }
}
