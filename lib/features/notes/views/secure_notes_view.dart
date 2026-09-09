import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../vault/providers/vault_files_provider.dart';
import '../../vault/views/secure_file_vault_view.dart';
import '../models/secure_note.dart';
import '../providers/notes_auth_provider.dart';
import '../providers/notes_crud_provider.dart';
import 'widgets/note_card_widget.dart';
import 'widgets/note_editor_dialog.dart';
import 'widgets/pin_pad_widget.dart';
import 'widgets/reset_pin_dialog.dart';

class SecureNotesView extends ConsumerStatefulWidget {
  const SecureNotesView({super.key});

  @override
  ConsumerState<SecureNotesView> createState() => _SecureNotesViewState();
}

class _SecureNotesViewState extends ConsumerState<SecureNotesView> {
  final GlobalKey<PinPadWidgetState> _pinPadKey = GlobalKey<PinPadWidgetState>();
  String? _pinErrorMessage;

  // PIN Setup state
  String? _setupInitialPin;
  bool _isConfirmingSetup = false;
  int _selectedVaultTab = 0; // 0: Notes, 1: Documents

  void _onUnlockPinComplete(String pin) async {
    setState(() => _pinErrorMessage = null);
    final strings = ref.read(appStringsProvider);
    final success = await ref.read(notesAuthNotifierProvider.notifier).unlockWithPin(pin);
    if (!success) {
      setState(() {
        _pinErrorMessage = strings.incorrectPinError;
      });
      _pinPadKey.currentState?.triggerShake();
    }
  }

  void _onSetupPinComplete(String pin) async {
    final strings = ref.read(appStringsProvider);
    if (!_isConfirmingSetup) {
      setState(() {
        _setupInitialPin = pin;
        _isConfirmingSetup = true;
        _pinErrorMessage = null;
      });
      _pinPadKey.currentState?.triggerShake();
    } else {
      if (pin == _setupInitialPin) {
        final recoveryCode =
            await ref.read(notesAuthNotifierProvider.notifier).setupMasterPin(pin);
        setState(() {
          _setupInitialPin = null;
          _isConfirmingSetup = false;
          _pinErrorMessage = null;
        });

        if (mounted) {
          _showRecoveryCodeDialog(recoveryCode);
        }
      } else {
        setState(() {
          _pinErrorMessage = strings.pinMismatchError;
          _setupInitialPin = null;
          _isConfirmingSetup = false;
        });
        _pinPadKey.currentState?.triggerShake();
      }
    }
  }

  void _showRecoveryCodeDialog(String code) {
    bool hasAcknowledged = false;
    final strings = ref.read(appStringsProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorderSubtle),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.incomeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppColors.income, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.recoveryDialogTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.recoveryDialogNotice,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                        tooltip: strings.copy,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.recoveryCodeCopied),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () {
                    setDialogState(() {
                      hasAcknowledged = !hasAcknowledged;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: hasAcknowledged,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              hasAcknowledged = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            strings.recoveryAcknowledgment,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: hasAcknowledged ? () => Navigator.of(ctx).pop() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                strings.unlockAndEnterVault,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoveryPrompt() {
    showDialog(
      context: context,
      builder: (_) => const ResetPinDialog(),
    );
  }

  void _openNoteEditor(BuildContext context, [SecureNote? existing]) {
    showDialog(
      context: context,
      builder: (_) => NoteEditorDialog(existingNote: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(notesAuthNotifierProvider);
    final strings = ref.watch(appStringsProvider);

    switch (authStatus) {
      case NotesAuthStatus.loading:
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

      case NotesAuthStatus.unconfigured:
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: PinPadWidget(
            key: _pinPadKey,
            title: _isConfirmingSetup ? strings.confirmPinTitle : strings.createPinTitle,
            stepLabel: _isConfirmingSetup ? strings.createPinStep2 : strings.createPinStep1,
            subtitle: _isConfirmingSetup
                ? strings.createPinSubtitle2
                : strings.createPinSubtitle1,
            errorMessage: _pinErrorMessage,
            onPinComplete: _onSetupPinComplete,
          ),
        );

      case NotesAuthStatus.locked:
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PinPadWidget(
                    key: _pinPadKey,
                    title: strings.enterPinTitle,
                    subtitle: strings.enterPinSubtitle,
                    errorMessage: _pinErrorMessage,
                    onPinComplete: _onUnlockPinComplete,
                  ),
                  TextButton.icon(
                    onPressed: _showRecoveryPrompt,
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    label: Text(strings.forgotPinPrompt),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case NotesAuthStatus.unlocked:
        return _buildVaultHub(context, strings);
    }
  }

  Widget _buildVaultHub(BuildContext context, strings) {
    final notesAsync = ref.watch(decryptedNotesProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final filesAsync = ref.watch(decryptedVaultFilesProvider);
    final allNotes = notesAsync.value ?? [];
    final filesCount = filesAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.incomeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_open_rounded, color: AppColors.income, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              strings.vaultTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.expense),
            label: Text(
              strings.lockVault,
              style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
            },
          ),
          if (_selectedVaultTab == 0)
            IconButton(
              tooltip: strings.newNote,
              icon: const Icon(Icons.note_add_rounded, color: AppColors.primary),
              onPressed: () => _openNoteEditor(context),
            ),
        ],
      ),
      floatingActionButton: _selectedVaultTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openNoteEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.newNote, style: const TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          // Sub-Tab Switcher (Notes vs Documents)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GlassContainer(
              blur: 8,
              backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.7),
              borderColor: AppColors.cardBorderSubtle,
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTab(
                      index: 0,
                      label: strings.confidentialNotes,
                      icon: Icons.note_alt_outlined,
                      count: allNotes.length,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSubTab(
                      index: 1,
                      label: strings.encryptedFiles,
                      icon: Icons.folder_shared_outlined,
                      count: filesCount,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedVaultTab == 0
                ? _buildNotesSection(context, notesAsync, filteredNotes, strings)
                : const SecureFileVaultView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab({
    required int index,
    required String label,
    required IconData icon,
    required int count,
  }) {
    final isSelected = _selectedVaultTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedVaultTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    AsyncValue<List<SecureNote>> notesAsync,
    List<SecureNote> filteredNotes,
    strings,
  ) {
    // Extract unique tags
    final allTags = <String>{};
    for (final note in filteredNotes) {
      allTags.addAll(note.tags);
    }

    return notesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Text(
          '${strings.error}: $err',
          style: const TextStyle(color: AppColors.expense),
        ),
      ),
      data: (notes) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: strings.searchNotes,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderSubtle),
                  ),
                ),
                onChanged: (val) {
                  ref.read(notesSearchQueryProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 12),

              // Tags Filter Bar
              if (allTags.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: ref.watch(notesSelectedTagProvider) == null,
                        label: Text(strings.all),
                        onSelected: (_) {
                          ref.read(notesSelectedTagProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(width: 8),
                      ...allTags.map((tag) {
                        final isSelected = ref.watch(notesSelectedTagProvider) == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(tag),
                            onSelected: (selected) {
                              ref.read(notesSelectedTagProvider.notifier).state =
                                  selected ? tag : null;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (filteredNotes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          strings.noNotesTitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.noNotesSubtitle,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 180,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return NoteCardWidget(note: note);
                        },
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredNotes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return NoteCardWidget(note: note);
                      },
                    );
                  },
                ),
              const SizedBox(height: 80), // Fab spacing
            ],
          ),
        );
      },
    );
  }
}
