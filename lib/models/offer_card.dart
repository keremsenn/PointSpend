import 'package:flutter/material.dart';

class OfferCard {
  const OfferCard({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.validUntil,
  });

  final String id;
  final String title;
  final String description;
  final Color color;
  final DateTime validUntil;

  OfferCard copyWith({
    String? id,
    String? title,
    String? description,
    Color? color,
    DateTime? validUntil,
  }) {
    return OfferCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'colorValue': color.toARGB32(),
      'validUntil': validUntil.toIso8601String(),
    };
  }

  factory OfferCard.fromMap(Map<String, dynamic> map) {
    return OfferCard(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      color: Color(map['colorValue'] as int? ?? 0xFFECFDF5),
      validUntil: map['validUntil'] != null
          ? DateTime.tryParse(map['validUntil'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
