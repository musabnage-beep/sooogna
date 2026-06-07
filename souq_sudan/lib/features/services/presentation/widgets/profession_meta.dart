import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Lookup helpers for service professions (id -> Arabic name / icon).
class ProfessionMeta {
  ProfessionMeta._();

  static String nameFor(String id) {
    final match = AppConstants.serviceProfessions
        .firstWhere((p) => p['id'] == id, orElse: () => const {'name': 'أخرى'});
    return match['name'] ?? 'أخرى';
  }

  static IconData iconFor(String id) {
    final match = AppConstants.serviceProfessions
        .firstWhere((p) => p['id'] == id, orElse: () => const {'icon': 'more_horiz'});
    return _iconForName(match['icon'] ?? 'more_horiz');
  }

  static IconData _iconForName(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'face_retouching_natural':
        return Icons.face_retouching_natural_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'electrical_services':
        return Icons.electrical_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'build_circle':
        return Icons.build_circle_rounded;
      case 'work_outline':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
