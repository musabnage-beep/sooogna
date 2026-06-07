import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: Validators.validatePhone,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      decoration: const InputDecoration(
        labelText: 'رقم الهاتف',
        hintText: '+249XXXXXXXXX أو +1XXXXXXXXXX',
        prefixIcon: Icon(Icons.phone),
        hintTextDirection: TextDirection.ltr,
        helperText: 'أدخل رمز الدولة مثل +249 أو +1 أو +44',
        helperMaxLines: 2,
      ),
    );
  }
}
