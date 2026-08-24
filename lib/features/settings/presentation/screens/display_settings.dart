import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/local_settings_service.dart';
import '../../../../ui/modes/dark_mode_provider.dart';
import '../../../../ui/modes/text_scale_provider.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../widgets/text_scale_preview.dart';

/// شاشة إعدادات العرض — تتحكم فعلياً بـ [DarkModeCubit] (السمة) و
/// [TextScaleCubit] (مقياس النص الإضافي بتحكم المستخدم، Prompt 27)،
/// مع معاينة حية فورية لكل منهما عبر [TextScalePreview].
class DisplaySettings extends StatelessWidget {
  const DisplaySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final ThemeMode themeMode = context.watch<DarkModeCubit>().state;
    final double textScale = context.watch<TextScaleCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('العرض')),
      body: ListView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        children: <Widget>[
          Text(
            'المظهر',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('فاتح'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('داكن'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('تلقائي'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) =>
                _onThemeChanged(context, selection.first),
          ),
          const SizedBox(height: AvahiSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'حجم النص',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              Text(
                '${(textScale * 100).round()}٪',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.brand,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.xs),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.text_decrease_outlined),
                tooltip: 'تصغير',
                onPressed: textScale <= TextScaleCubit.minScale
                    ? null
                    : () => _onScaleChanged(
                          context,
                          context.read<TextScaleCubit>().state -
                              TextScaleCubit.step,
                        ),
              ),
              Expanded(
                child: Slider(
                  value: textScale,
                  min: TextScaleCubit.minScale,
                  max: TextScaleCubit.maxScale,
                  divisions:
                      ((TextScaleCubit.maxScale - TextScaleCubit.minScale) /
                              TextScaleCubit.step)
                          .round(),
                  label: '${(textScale * 100).round()}٪',
                  onChanged: (double value) => _onScaleChanged(context, value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase_outlined),
                tooltip: 'تكبير',
                onPressed: textScale >= TextScaleCubit.maxScale
                    ? null
                    : () => _onScaleChanged(
                          context,
                          context.read<TextScaleCubit>().state +
                              TextScaleCubit.step,
                        ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: textScale == 1.0
                  ? null
                  : () => _onScaleChanged(context, 1.0),
              child: const Text('إعادة للحجم الافتراضي'),
            ),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          TextScalePreview(scale: textScale),
        ],
      ),
    );
  }

  Future<void> _onThemeChanged(BuildContext context, ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        context.read<DarkModeCubit>().useLight();
      case ThemeMode.dark:
        context.read<DarkModeCubit>().useDark();
      case ThemeMode.system:
        context.read<DarkModeCubit>().useSystem();
    }
    await sl<LocalSettingsService>().saveThemeModeName(mode.name);
  }

  Future<void> _onScaleChanged(BuildContext context, double value) async {
    context.read<TextScaleCubit>().setScale(value);
    await sl<LocalSettingsService>().saveTextScale(
      context.read<TextScaleCubit>().state,
    );
  }
}
