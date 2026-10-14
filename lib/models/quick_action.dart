import 'package:flutter/material.dart';

class QuickAction {
  const QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    this.route = '',
  });

  final String id;
  final IconData icon;
  final String label;
  final String route;

  QuickAction copyWith({
    String? id,
    IconData? icon,
    String? label,
    String? route,
  }) {
    return QuickAction(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      route: route ?? this.route,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'route': route,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
    };
  }

  factory QuickAction.fromMap(Map<String, dynamic> map) {
    final icon = IconData(
      map['iconCodePoint'] as int? ?? Icons.flash_on.codePoint,
      fontFamily: map['iconFontFamily'] as String?,
      fontPackage: map['iconFontPackage'] as String?,
    );

    return QuickAction(
      id: map['id'] as String? ?? '',
      icon: icon,
      label: map['label'] as String? ?? '',
      route: map['route'] as String? ?? '',
    );
  }
}
