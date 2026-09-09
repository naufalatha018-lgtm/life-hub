import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/notes_auth_provider.dart';

class ResetPinDialog extends ConsumerStatefulWidget {
  const ResetPinDialog({super.key});

  @override
  ConsumerState<ResetPinDialog> createState() => _ResetPinDialogState();
}

class _ResetPinDialogState extends ConsumerState<ResetPinDialog> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _newPinCtrl;
  late final FocusNode _codeFocus;
  late final FocusNode _pinFocus;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _newPinCtrl = TextEditingController();
    _codeFocus = FocusNode();
    _pinFocus = FocusNode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _newPinCtrl.dispose();
    _codeFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final code = _codeCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();

    if (newPin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.newPin6DigitLabel)),
      );
      return;
    }

    final ok = await ref
        .read(notesAuthNotifierProvider.notifier)
        .resetPinWithRecoveryCode(code, newPin);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.success)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.error),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderSubtle),
      ),
      title: Text(
        strings.resetPinTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              decoration: InputDecoration(
                labelText: strings.recoveryCodeLabel,
                hintText: 'LH-XXXX-XXXX-XXXX-XXXX',
                prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPinCtrl,
              focusNode: _pinFocus,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.newPinLabel,
                hintText: '••••••',
                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(strings.resetAndUnlock),
        ),
      ],
    );
  }
}
