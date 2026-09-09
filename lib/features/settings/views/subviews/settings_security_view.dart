import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../notes/providers/notes_auth_provider.dart';
import '../../providers/settings_providers.dart';

class SettingsSecurityView extends ConsumerWidget {
  const SettingsSecurityView({super.key});

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ChangePinDialog(),
    );
  }

  void _showEmergencyRecoveryDialog(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final recoveryCode = await ref.read(notesAuthNotifierProvider.notifier).getRecoveryCode();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(strings.emergencyRecoveryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.emergencyRecoverySubtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                recoveryCode ?? 'RECOVERY-NOT-INITIALIZED',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          if (recoveryCode != null)
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(strings.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: recoveryCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.copied)),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final autoLockTimeout = ref.watch(autoLockTimeoutProvider);
    final vaultState = ref.watch(notesAuthNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsSecurityTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master PIN Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.vaultSecurityKeyTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vaultState != NotesAuthStatus.unconfigured
                                  ? 'PIN Aktif & Terlindungi AES-256'
                                  : 'PIN Belum Diatur',
                              style: TextStyle(
                                color: vaultState != NotesAuthStatus.unconfigured
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showChangePinDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text(strings.changeMasterPinButton),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auto-Lock Timeout Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.autoLockTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.autoLockSubtitle,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimeoutChip(ref, 30, '30 Detik', autoLockTimeout),
                      _buildTimeoutChip(ref, 60, '1 Menit', autoLockTimeout),
                      _buildTimeoutChip(ref, 300, '5 Menit', autoLockTimeout),
                      _buildTimeoutChip(ref, 900, '15 Menit', autoLockTimeout),
                      _buildTimeoutChip(ref, 1800, '30 Menit', autoLockTimeout),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Recovery Code Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  strings.emergencyRecoveryTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  strings.emergencyRecoverySubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => _showEmergencyRecoveryDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutChip(WidgetRef ref, int seconds, String label, int currentSeconds) {
    final isSelected = currentSeconds == seconds;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
      ),
      onSelected: (_) {
        ref.read(autoLockTimeoutProvider.notifier).state = seconds;
      },
    );
  }
}

class _ChangePinDialog extends ConsumerStatefulWidget {
  const _ChangePinDialog();

  @override
  ConsumerState<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<_ChangePinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPinCtrl;
  late final TextEditingController _newPinCtrl;
  late final TextEditingController _confirmPinCtrl;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPinCtrl = TextEditingController();
    _newPinCtrl = TextEditingController();
    _confirmPinCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPinCtrl.text != _confirmPinCtrl.text) {
      setState(() => _errorMessage = 'PIN baru dan konfirmasi tidak cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(notesAuthNotifierProvider.notifier).changeMasterPin(
            currentPin: _currentPinCtrl.text,
            newPin: _newPinCtrl.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Master berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.changePinDialogTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ),
                TextFormField(
                  controller: _currentPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    labelText: strings.currentPinLabel,
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v == null || v.length != 6 ? 'Wajib 6 digit angka' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    labelText: strings.newPin6DigitLabel,
                    counterText: '',
                    prefixIcon: const Icon(Icons.pin_rounded),
                  ),
                  validator: (v) => v == null || v.length != 6 ? 'Wajib 6 digit angka' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: InputDecoration(
                    labelText: strings.confirmNewPinLabel,
                    counterText: '',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  ),
                  validator: (v) => v == null || v.length != 6 ? 'Wajib 6 digit angka' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(strings.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(strings.updatePinButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
