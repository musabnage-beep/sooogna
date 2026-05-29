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
        hintText: '+249XXXXXXXXX',
        prefixIcon: Icon(Icons.phone),
        hintTextDirection: TextDirection.ltr,
      ),
      onChanged: (value) {
        if (value.isNotEmpty && !value.startsWith('+') && !value.startsWith('0')) {
          controller.value = controller.value.copyWith(
            text: '+249$value',
            selection: TextSelection.collapsed(offset: '+249$value'.length),
          );
        }
      },
    );
  }
}
