import 'package:flutter/material.dart';

/// عنصر واحد في [AvahiDropdown].
class AvahiDropdownItem<T> {
  const AvahiDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// قائمة منسدلة موحّدة لتطبيق Avahi — غلاف عام (Generic) فوق
/// [DropdownButtonFormField] مبني بنفس أسلوب [AvahiTextField] البصري.
///
/// مكوّن عرض بحت؛ لا يحتوي على أي بيانات أو منطق عمل مضمّن.
class AvahiDropdown<T> extends StatelessWidget {
  const AvahiDropdown({
    required this.items,
    super.key,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  final List<AvahiDropdownItem<T>> items;
  final T? value;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
      ),
      items: items
          .map(
            (AvahiDropdownItem<T> item) => DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (item.icon != null) ...<Widget>[
                    Icon(item.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
