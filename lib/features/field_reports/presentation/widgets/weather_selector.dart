import 'package:flutter/material.dart';

import '../../../../domain/enums/weather_condition.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../ui/widgets/common/avahi_text_field.dart';

/// أيقونة/تسمية عربية معيارية لكل [WeatherCondition] — مُشتركة بين
/// [WeatherSelector] ومعاينة `report_preview_screen.dart`.
(IconData, String) weatherConditionDisplay(WeatherCondition condition) {
  return switch (condition) {
    WeatherCondition.sunny => (Icons.wb_sunny_outlined, 'مشمس'),
    WeatherCondition.cloudy => (Icons.cloud_outlined, 'غائم'),
    WeatherCondition.partlyCloudy => (Icons.wb_cloudy_outlined, 'غائم جزئياً'),
    WeatherCondition.rainy => (Icons.water_drop_outlined, 'ممطر'),
    WeatherCondition.stormy => (Icons.bolt, 'عاصف رعدي'),
    WeatherCondition.foggy => (Icons.blur_linear, 'ضبابي'),
    WeatherCondition.dusty => (Icons.blur_on, 'غبار'),
    WeatherCondition.windy => (Icons.air, 'رياح شديدة'),
    WeatherCondition.extremeHeat => (Icons.local_fire_department_outlined, 'حرارة قصوى'),
    WeatherCondition.unknown => (Icons.help_outline, 'غير محدد'),
  };
}

/// حقلا حالة الطقس ودرجة الحرارة، مع تعبئة تلقائية عبر
/// `weather_api_service.dart` (`ReportFormCubit._autoFillWeather`) —
/// كلا الحقلين يبقيان قابلين للتعديل اليدوي الكامل دوماً، بما فيها أثناء
/// جلب البيانات التلقائي (لا قفل مؤقت للحقل).
class WeatherSelector extends StatelessWidget {
  const WeatherSelector({
    required this.condition,
    required this.temperatureC,
    required this.isLoading,
    required this.onConditionChanged,
    required this.onTemperatureChanged,
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  final WeatherCondition? condition;
  final double? temperatureC;
  final bool isLoading;
  final ValueChanged<WeatherCondition> onConditionChanged;
  final ValueChanged<double> onTemperatureChanged;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('الطقس', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: AvahiSpacing.xs),
            if (isLoading)
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: AvahiSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: AvahiDropdown<WeatherCondition>(
                label: 'حالة الطقس',
                value: condition,
                items: WeatherCondition.values
                    .map((WeatherCondition c) {
                      final (IconData icon, String label) = weatherConditionDisplay(c);
                      return AvahiDropdownItem<WeatherCondition>(
                        value: c,
                        label: label,
                        icon: icon,
                      );
                    })
                    .toList(growable: false),
                onChanged: (WeatherCondition? value) {
                  if (value != null) onConditionChanged(value);
                },
              ),
            ),
            const SizedBox(width: AvahiSpacing.sm),
            Expanded(
              flex: 2,
              child: _TemperatureField(
                temperatureC: temperatureC,
                onChanged: onTemperatureChanged,
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xxs),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ],
      ],
    );
  }
}

/// حقل درجة الحرارة كعنصر Stateful منفصل — يحمل `TextEditingController`
/// خاصاً به بدل إعادة إنشائه في كل بناء لـ [WeatherSelector] (والذي
/// يُعاد بناؤه بتكرار مرتفع نسبياً بفعل `BlocBuilder` الأب)، مع مزامنة
/// نصه مع [temperatureC] الوارد من الخارج عند تغيّره فعلياً فقط (تعبئة
/// تلقائية ناجحة) دون قطع تحرير المستخدم الجاري.
class _TemperatureField extends StatefulWidget {
  const _TemperatureField({required this.temperatureC, required this.onChanged});

  final double? temperatureC;
  final ValueChanged<double> onChanged;

  @override
  State<_TemperatureField> createState() => _TemperatureFieldState();
}

class _TemperatureFieldState extends State<_TemperatureField> {
  late final TextEditingController _controller;
  double? _lastExternalValue;

  @override
  void initState() {
    super.initState();
    _lastExternalValue = widget.temperatureC;
    _controller = TextEditingController(text: _format(widget.temperatureC));
  }

  @override
  void didUpdateWidget(covariant _TemperatureField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.temperatureC != _lastExternalValue && !_controller.selection.isValid) {
      _lastExternalValue = widget.temperatureC;
      _controller.text = _format(widget.temperatureC);
    } else if (widget.temperatureC != _lastExternalValue &&
        widget.temperatureC != double.tryParse(_controller.text.trim())) {
      // تحديث خارجي فعلي (تعبئة تلقائية) بينما الحقل غير مُركَّز عليه حالياً.
      _lastExternalValue = widget.temperatureC;
      _controller.text = _format(widget.temperatureC);
    }
  }

  String _format(double? value) => value == null ? '' : value.toStringAsFixed(1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvahiTextField(
      label: 'الحرارة (°م)',
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      textAlign: TextAlign.center,
      onChanged: (String value) {
        final double? parsed = double.tryParse(value.trim());
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}
