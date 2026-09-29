import 'package:flutter/material.dart';

import '../core/validators.dart';

class TextFieldSpec {
  const TextFieldSpec({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final Validator? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
}

List<Widget> buildDeclarativeTextFields({
  required List<TextFieldSpec> fields,
  required VoidCallback onDirty,
}) {
  final children = <Widget>[];
  for (final field in fields) {
    children.add(
      TextFormField(
        controller: field.controller,
        keyboardType: field.keyboardType,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        validator: field.validator,
        onChanged: (value) {
          field.onChanged?.call(value);
          onDirty();
        },
      ),
    );
    children.add(const SizedBox(height: 16));
  }
  return children;
}
