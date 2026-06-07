import 'package:flutter/material.dart';

/// Single source of truth for category iconography.
///
/// Every icon belongs to the Material Symbols **Rounded** family so the whole
/// app shares one consistent stroke weight and visual style. Legacy ids
/// (clothes/livestock) and the string icon names stored in
/// `AppConstants.categories` both resolve here, so callers never branch.
class CategoryIcons {
  CategoryIcons._();

  static const IconData _fallback = Icons.category_rounded;

  static const Map<String, IconData> _byId = {
    'cars': Icons.directions_car_rounded,
    'real_estate': Icons.home_rounded,
    'mobiles': Icons.smartphone_rounded,
    'electronics': Icons.devices_rounded,
    'furniture': Icons.chair_rounded,
    'fashion': Icons.checkroom_rounded,
    'clothes': Icons.checkroom_rounded, // legacy alias
    'animals': Icons.pets_rounded,
    'livestock': Icons.pets_rounded, // legacy alias
    'food': Icons.restaurant_rounded,
    'services': Icons.handyman_rounded,
    'jobs': Icons.work_rounded,
    'stores': Icons.storefront_rounded,
    'other': Icons.category_rounded,
  };

  /// Icon for a category [id] (e.g. `cars`, `real_estate`).
  static IconData forId(String? id) => _byId[id] ?? _fallback;

  /// Brand accent color per category (matches the marketplace mockup).
  /// Legacy ids resolve to the same color as their canonical id.
  static const Map<String, Color> _colorById = {
    'cars': Color(0xFFE63946), // red
    'real_estate': Color(0xFF007A3D), // green
    'mobiles': Color(0xFF2196F3), // blue
    'electronics': Color(0xFF00BCD4), // cyan
    'furniture': Color(0xFF8D6E63), // brown
    'fashion': Color(0xFFE91E63), // pink
    'clothes': Color(0xFFE91E63), // legacy alias
    'animals': Color(0xFFFF9800), // orange
    'livestock': Color(0xFFFF9800), // legacy alias
    'food': Color(0xFFF4511E), // deep orange
    'services': Color(0xFFFF7A00), // orange wrench
    'jobs': Color(0xFFFFD700), // gold
    'stores': Color(0xFF9C27B0), // purple
    'other': Color(0xFF9CA3AF), // grey
  };

  static const Color _colorFallback = Color(0xFF9CA3AF);

  /// Accent color for a category [id]; falls back to neutral grey.
  static Color colorForId(String? id) => _colorById[id] ?? _colorFallback;

  /// Accent color resolved from the stored `icon` string or id.
  static Color colorForName(String? name) {
    if (name == null) return _colorFallback;
    return _colorById[name] ?? _colorFallback;
  }

  /// Icon for the legacy string `icon` name stored in category maps.
  /// Falls back to id resolution, then the generic fallback.
  static IconData forName(String? name) {
    if (name == null) return _fallback;
    if (_byId.containsKey(name)) return _byId[name]!;
    return _byName[name] ?? _fallback;
  }

  static const Map<String, IconData> _byName = {
    'directions_car': Icons.directions_car_rounded,
    'home_work': Icons.home_rounded,
    'home_rounded': Icons.home_rounded,
    'phone_android': Icons.smartphone_rounded,
    'smartphone_rounded': Icons.smartphone_rounded,
    'devices': Icons.devices_rounded,
    'work': Icons.work_rounded,
    'build': Icons.handyman_rounded,
    'handyman_rounded': Icons.handyman_rounded,
    'pets': Icons.pets_rounded,
    'chair': Icons.chair_rounded,
    'checkroom': Icons.checkroom_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'storefront_rounded': Icons.storefront_rounded,
    'more_horiz': Icons.category_rounded,
  };
}
