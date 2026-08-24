import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../state/attendance_cubit.dart';
import '../../state/attendance_state.dart';
import '../../widgets/qr_scanner_overlay.dart';

/// شاشة مسح رمز QR لتسجيل الحضور — تُفتح عبر `Navigator.push` من
/// `check_in_screen.dart` عند اختيار طريقة "رمز QR". تعتمد حزمة
/// `mobile_scanner` لمعاينة الكاميرا والكشف الفعلي عن الرمز، و
/// [QrScannerOverlay] كطبقة زخرفية بحتة فوقها فقط.
///
/// تمنع أكثر من عملية مسح واحدة متزامنة عبر [_hasDetected] (يوقف
/// الكاميرا فور أول كشف صالح ريثما يكتمل استدعاء
/// `AttendanceCubit.checkInQr`، ثم يُغلق الشاشة تلقائياً عند النجاح).
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetected = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    final String? rawValue = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasDetected = true);
    unawaited(_controller.stop());
    context.read<AttendanceCubit>().checkInQr(user: widget.user, qrCodeId: rawValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('امسح رمز QR الخاص بالموقع'),
      ),
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (BuildContext context, AttendanceState state) {
          state.maybeWhen<void>(
            orElse: () {},
            checkInSuccess: (_) => Navigator.of(context).pop(),
            checkInGeofenceWarning: (_) => Navigator.of(context).pop(),
            error: (_) {
              if (mounted) {
                setState(() => _hasDetected = false);
                unawaited(_controller.start());
              }
            },
          );
        },
        builder: (BuildContext context, AttendanceState state) {
          final bool isBusy = state is AttendanceCheckInProgress;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              MobileScanner(controller: _controller, onDetect: _onDetect),
              const QrScannerOverlay(),
              if (isBusy)
                const ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Positioned(
                bottom: AvahiSpacing.xl,
                left: AvahiSpacing.lg,
                right: AvahiSpacing.lg,
                child: Text(
                  'وجّه الكاميرا نحو رمز QR الخاص بالموقع لتسجيل حضورك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
