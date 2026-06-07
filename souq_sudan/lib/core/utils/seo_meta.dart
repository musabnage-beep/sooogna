import 'package:web/web.dart' as web;

import '../constants/app_constants.dart';

/// Runtime per-route SEO/social meta injection for Flutter web (Feature 12).
///
/// True crawler SEO is served by the pre-rendered static pages produced by
/// `scripts/generate_seo.mjs`. This helper additionally updates the live
/// document head so JS-executing social scrapers and the browser tab reflect
/// the current ad/store/service. It is a no-op cost on non-detail routes.
class SeoMeta {
  SeoMeta._();

  static const _defaultTitle =
      'سوق السودان - الإعلانات المبوبة والخدمات والمتاجر';
  static const _defaultDescription =
      'سوق السودان - منصة الإعلانات المبوبة والخدمات والمتاجر في السودان.';
  static const _defaultImage =
      '${AppConstants.webBaseUrl}/icons/Icon-512.png';

  /// Update head tags for a specific entity page.
  static void set({
    required String title,
    required String description,
    String? imageUrl,
    String? url,
  }) {
    final desc = _truncate(description, 160);
    web.document.title = title;
    _setMeta(name: 'description', content: desc);
    _setMeta(property: 'og:title', content: title);
    _setMeta(property: 'og:description', content: desc);
    _setMeta(property: 'og:image', content: imageUrl ?? _defaultImage);
    if (url != null) {
      _setMeta(property: 'og:url', content: url);
      _setCanonical(url);
    }
    _setMeta(name: 'twitter:title', content: title);
    _setMeta(name: 'twitter:description', content: desc);
    _setMeta(name: 'twitter:image', content: imageUrl ?? _defaultImage);
  }

  /// Restore the global defaults (call when leaving a detail route).
  static void reset() {
    set(
      title: _defaultTitle,
      description: _defaultDescription,
      imageUrl: _defaultImage,
      url: '${AppConstants.webBaseUrl}/',
    );
  }

  static void _setMeta({String? name, String? property, required String content}) {
    final selector =
        name != null ? 'meta[name="$name"]' : 'meta[property="$property"]';
    var el = web.document.querySelector(selector) as web.HTMLMetaElement?;
    if (el == null) {
      el = web.document.createElement('meta') as web.HTMLMetaElement;
      if (name != null) {
        el.setAttribute('name', name);
      } else if (property != null) {
        el.setAttribute('property', property);
      }
      web.document.head?.appendChild(el);
    }
    el.content = content;
  }

  static void _setCanonical(String href) {
    var el =
        web.document.querySelector('link[rel="canonical"]') as web.HTMLLinkElement?;
    if (el == null) {
      el = web.document.createElement('link') as web.HTMLLinkElement;
      el.rel = 'canonical';
      web.document.head?.appendChild(el);
    }
    el.href = href;
  }

  static String _truncate(String s, int max) {
    final clean = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= max ? clean : '${clean.substring(0, max - 1)}…';
  }
}
