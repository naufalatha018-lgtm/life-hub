import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsAiView extends ConsumerStatefulWidget {
  const SettingsAiView({super.key});

  @override
  ConsumerState<SettingsAiView> createState() => _SettingsAiViewState();
}

class _SettingsAiViewState extends ConsumerState<SettingsAiView> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _hasKey = false;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _statusMessage;
  bool _statusIsSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final has = await AiService.instance.hasApiKey();
    if (mounted) setState(() => _hasKey = has);
  }

  Future<void> _saveKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final success = await AiService.instance.saveApiKey(key);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasKey = success;
        _statusIsSuccess = success;
        _statusMessage = success
            ? ref.read(appStringsProvider).aiApiKeySaved
            : ref.read(appStringsProvider).aiApiKeyTestFail;
      });

      if (success) _apiKeyController.clear();
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    final strings = ref.read(appStringsProvider);
    final lang = ref.read(localeProvider).code;

    final result = await AiService.instance.generateFinancialInsight(
      totalIncome: 5000000,
      totalExpenses: 3200000,
      categoryBreakdown: const {'Food': 1200000, 'Transport': 800000, 'Entertainment': 600000},
      language: lang,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _statusIsSuccess = result != null;
        _statusMessage = result != null
            ? strings.aiApiKeyTestSuccess
            : strings.aiApiKeyTestFail;
      });
    }
  }

  Future<void> _removeKey() async {
    final strings = ref.read(appStringsProvider);
    await AiService.instance.removeApiKey();
    if (mounted) {
      setState(() {
        _hasKey = false;
        _statusIsSuccess = false;
        _statusMessage = strings.aiApiKeyRemoved;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(strings.aiAssistantTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          _buildHeaderCard(theme, strings),
          const SizedBox(height: 20),

          // Key status
          _buildKeyStatusCard(theme, strings),
          const SizedBox(height: 20),

          // API key input (shown when no key or updating)
          _buildApiKeyInputCard(theme, strings),
          const SizedBox(height: 20),

          // How to get API key guidance
          _buildGuidanceCard(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.aiAssistantTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.aiAssistantSubtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatusCard(ThemeData theme, dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasKey
              ? AppColors.income.withOpacity(0.3)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (_hasKey ? AppColors.income : AppColors.textMuted).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _hasKey ? Icons.check_circle_rounded : Icons.key_off_rounded,
                  color: _hasKey ? AppColors.income : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.aiApiKeyLabel,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _hasKey ? '••••••••••••••••••••••••••••••' : strings.aiApiKeyNotSet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _hasKey ? AppColors.textSecondary : AppColors.textMuted,
                        fontFamily: _hasKey ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasKey)
                Row(
                  children: [
                    _isTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : TextButton(
                            onPressed: _testConnection,
                            child: Text(strings.aiApiKeyTest, style: const TextStyle(fontSize: 12)),
                          ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                      onPressed: _removeKey,
                      tooltip: strings.aiApiKeyRemoved,
                    ),
                  ],
                ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (_statusIsSuccess ? AppColors.income : AppColors.expense).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusIsSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _statusIsSuccess ? AppColors.income : AppColors.expense,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusIsSuccess ? AppColors.income : AppColors.expense,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeyInputCard(ThemeData theme, dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasKey ? strings.aiApiKeyLabel + ' (Update)' : strings.aiApiKeyLabel,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              hintText: strings.aiApiKeyHint,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveKey,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(strings.save),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(ThemeData theme) {
    final isId = ref.read(localeProvider).code == 'id';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                isId ? 'Cara Mendapatkan Kunci API' : 'How to Get API Key',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[ 
            isId ? '1. Buka aistudio.google.com' : '1. Visit aistudio.google.com',
            isId ? '2. Masuk dengan akun Google Anda' : '2. Sign in with your Google account',
            isId ? '3. Klik "Get API key" → "Create API key"' : '3. Click "Get API key" → "Create API key"',
            isId ? '4. Salin kunci dan tempel di atas' : '4. Copy the key and paste it above',
            isId ? '5. Kunci tersimpan lokal di perangkat Anda' : '5. Key is stored locally on your device',
          ].map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(step, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          )),
          const SizedBox(height: 4),
          Text(
            isId
                ? '✓ Kunci API tidak pernah dikirim ke server Life OS. Disimpan terenkripsi di perangkat Anda.'
                : '✓ Your API key is never sent to Life OS servers. It\'s encrypted on your device only.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.income,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
