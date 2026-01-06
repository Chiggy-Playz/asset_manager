import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A 6-digit OTP input field with individual boxes for each digit.
/// Works across all platforms (mobile, tablet, desktop).
class OtpInputField extends StatefulWidget {
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const OtpInputField({
    super.key,
    this.onCompleted,
    this.onChanged,
    this.controller,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  static const int _otpLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    // Sync with external controller if provided
    if (widget.controller != null) {
      _syncFromExternalController();
      widget.controller!.addListener(_syncFromExternalController);
    }
  }

  void _syncFromExternalController() {
    final text = widget.controller?.text ?? '';
    for (int i = 0; i < _otpLength; i++) {
      final newValue = i < text.length ? text[i] : '';
      if (_controllers[i].text != newValue) {
        _controllers[i].text = newValue;
      }
    }
  }

  void _syncToExternalController() {
    if (widget.controller != null) {
      final otp = _getOtp();
      if (widget.controller!.text != otp) {
        widget.controller!.text = otp;
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncFromExternalController);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    // Handle paste of full OTP
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final focusIndex = digits.length.clamp(0, _otpLength - 1);
      _focusNodes[focusIndex].requestFocus();
      _notifyChanges();
      return;
    }

    // Move to next field on valid input
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _notifyChanges();
  }

  void _notifyChanges() {
    _syncToExternalController();
    final otp = _getOtp();
    widget.onChanged?.call(otp);

    if (otp.length == _otpLength) {
      widget.onCompleted?.call(otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        _notifyChanges();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) => _onKeyEvent(index, event),
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onDigitChanged(index, value),
              ),
            ),
          ),
        );
      }),
    );
  }
}
