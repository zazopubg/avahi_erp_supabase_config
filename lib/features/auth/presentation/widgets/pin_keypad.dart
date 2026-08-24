import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_spacing.dart';

/// لوحة أرقام كبيرة (0-9 + مسح) لإدخال رمز PIN — مكوّن عرض بحت بلا أي
/// حالة داخلية لقيمة الرمز نفسه (تُدار بالكامل في `pin_screen.dart`)،
/// يستدعي [onDigit] عند لمس رقم و[onBackspace] عند لمس زر المسح.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  static const List<String> _rows = <String>[
    '123',
    '456',
    '789',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String row in _rows) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              for (final String digit in row.split(''))
                _PinKey(label: digit, enabled: enabled, onTap: onDigit),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const SizedBox(width: 72, height: 72),
            _PinKey(label: '0', enabled: enabled, onTap: onDigit),
            _PinBackspaceKey(enabled: enabled, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () => onTap(label) : null,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
      ),
    );
  }
}

class _PinBackspaceKey extends StatelessWidget {
  const _PinBackspaceKey({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }
}
