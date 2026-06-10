import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class _Country {
  final String name;
  final String nameAr;
  final String code; // dial code e.g. +249
  final String iso;  // ISO 3166-1 alpha-2 e.g. SD
  const _Country(this.name, this.nameAr, this.code, this.iso);

  String get flag {
    // Convert ISO code to regional indicator emoji flags
    return iso.toUpperCase().split('').map((c) {
      return String.fromCharCode(c.codeUnitAt(0) + 127397);
    }).join();
  }
}

const _countries = [
  // Africa – most common for Sudan users
  _Country('Sudan', 'السودان', '+249', 'SD'),
  _Country('Egypt', 'مصر', '+20', 'EG'),
  _Country('Saudi Arabia', 'السعودية', '+966', 'SA'),
  _Country('UAE', 'الإمارات', '+971', 'AE'),
  _Country('Qatar', 'قطر', '+974', 'QA'),
  _Country('Kuwait', 'الكويت', '+965', 'KW'),
  _Country('Bahrain', 'البحرين', '+973', 'BH'),
  _Country('Oman', 'عُمان', '+968', 'OM'),
  _Country('Libya', 'ليبيا', '+218', 'LY'),
  _Country('Ethiopia', 'إثيوبيا', '+251', 'ET'),
  _Country('South Sudan', 'جنوب السودان', '+211', 'SS'),
  _Country('Chad', 'تشاد', '+235', 'TD'),
  _Country('Jordan', 'الأردن', '+962', 'JO'),
  _Country('Iraq', 'العراق', '+964', 'IQ'),
  _Country('Syria', 'سوريا', '+963', 'SY'),
  _Country('Lebanon', 'لبنان', '+961', 'LB'),
  _Country('Yemen', 'اليمن', '+967', 'YE'),
  _Country('Morocco', 'المغرب', '+212', 'MA'),
  _Country('Tunisia', 'تونس', '+216', 'TN'),
  _Country('Algeria', 'الجزائر', '+213', 'DZ'),
  _Country('Somalia', 'الصومال', '+252', 'SO'),
  _Country('Eritrea', 'إريتريا', '+291', 'ER'),
  _Country('Kenya', 'كينيا', '+254', 'KE'),
  _Country('Nigeria', 'نيجيريا', '+234', 'NG'),
  // Europe & Americas
  _Country('United Kingdom', 'المملكة المتحدة', '+44', 'GB'),
  _Country('United States', 'الولايات المتحدة', '+1', 'US'),
  _Country('Canada', 'كندا', '+1', 'CA'),
  _Country('Germany', 'ألمانيا', '+49', 'DE'),
  _Country('France', 'فرنسا', '+33', 'FR'),
  _Country('Netherlands', 'هولندا', '+31', 'NL'),
  _Country('Sweden', 'السويد', '+46', 'SE'),
  _Country('Norway', 'النرويج', '+47', 'NO'),
  _Country('Denmark', 'الدنمارك', '+45', 'DK'),
  _Country('Australia', 'أستراليا', '+61', 'AU'),
  _Country('Turkey', 'تركيا', '+90', 'TR'),
  _Country('India', 'الهند', '+91', 'IN'),
  _Country('Pakistan', 'باكستان', '+92', 'PK'),
  _Country('China', 'الصين', '+86', 'CN'),
  _Country('Russia', 'روسيا', '+7', 'RU'),
  _Country('Brazil', 'البرازيل', '+55', 'BR'),
];

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;

  const PhoneInputField({super.key, required this.controller});

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  _Country _selected = _countries.first; // Sudan default
  final _localCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If controller already has a value (e.g. from retry), try to parse it
    final existing = widget.controller.text.trim();
    if (existing.isNotEmpty && existing.startsWith('+')) {
      for (final c in _countries) {
        if (existing.startsWith(c.code)) {
          _selected = c;
          _localCtrl.text = existing.substring(c.code.length);
          break;
        }
      }
    }
    _localCtrl.addListener(_sync);
  }

  @override
  void dispose() {
    _localCtrl.removeListener(_sync);
    _localCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    final local = _localCtrl.text.trim().replaceAll(' ', '').replaceAll('-', '');
    widget.controller.text = local.isEmpty ? '' : '${_selected.code}$local';
  }

  void _pickCountry() async {
    final result = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryPickerSheet(),
    );
    if (result != null) {
      setState(() => _selected = result);
      _sync();
    }
  }

  String? _validate(String? _) {
    final local = _localCtrl.text.trim().replaceAll(' ', '').replaceAll('-', '');
    if (local.isEmpty) return 'يرجى إدخال رقم الهاتف';
    if (!RegExp(r'^\d{4,14}$').hasMatch(local)) return 'رقم الهاتف غير صحيح';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country picker button
        GestureDetector(
          onTap: _pickCountry,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selected.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text(
                  _selected.code,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Local number field
        Expanded(
          child: TextFormField(
            controller: _localCtrl,
            validator: _validate,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]'))],
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: '912345678',
              hintTextDirection: TextDirection.ltr,
              hintStyle: TextStyle(color: AppColors.textHint),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_Country> _filtered = _countries;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _countries
            : _countries.where((c) =>
                c.nameAr.contains(q) ||
                c.name.toLowerCase().contains(q) ||
                c.code.contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('اختر الدولة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث عن دولة...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                  title: Text(c.nameAr, style: const TextStyle(fontSize: 15)),
                  subtitle: Text(c.name, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  trailing: Text(
                    c.code,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    textDirection: TextDirection.ltr,
                  ),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
