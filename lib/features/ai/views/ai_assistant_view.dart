import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  const ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

final _chatHistoryProvider = StateProvider<List<ChatMessage>>((ref) => []);
final _chatLoadingProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class AiAssistantView extends ConsumerStatefulWidget {
  const AiAssistantView({super.key});

  @override
  ConsumerState<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends ConsumerState<AiAssistantView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();
    final history = ref.read(_chatHistoryProvider);
    final lang = ref.read(localeProvider).code;

    // Add user message
    ref.read(_chatHistoryProvider.notifier).state = [
      ...history,
      ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
    ];
    _scrollToBottom();

    ref.read(_chatLoadingProvider.notifier).state = true;

    // Convert history to format expected by AI service
    final aiHistory = history
        .map((m) => (role: m.isUser ? 'user' : 'model', text: m.text))
        .toList();

    final response = await AiService.instance.chat(
      history: aiHistory,
      userMessage: trimmed,
      language: lang,
    );

    ref.read(_chatLoadingProvider.notifier).state = false;

    final responseText = response ??
        (lang == 'id'
            ? 'Maaf, AI tidak tersedia. Pastikan kunci API sudah diatur di Pengaturan.'
            : 'Sorry, AI is not available. Please set your API key in Settings.');

    ref.read(_chatHistoryProvider.notifier).state = [
      ...ref.read(_chatHistoryProvider),
      ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now()),
    ];
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final messages = ref.watch(_chatHistoryProvider);
    final isLoading = ref.watch(_chatLoadingProvider);
    final theme = Theme.of(context);
    final isAiAvailable = AiService.instance.isAvailable;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.aiAssistantTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  isAiAvailable ? 'Gemini 1.5 Flash' : strings.aiApiKeyNotSet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isAiAvailable ? AppColors.income : AppColors.expense,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, size: 20),
              tooltip: 'Clear chat',
              onPressed: () {
                ref.read(_chatHistoryProvider.notifier).state = [];
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Welcome / empty state
          if (messages.isEmpty) _buildEmptyState(strings, theme, isAiAvailable),

          // Chat messages
          if (messages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _ChatBubble(message: messages[i]),
              ),
            ),

          // Loading indicator
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const _TypingIndicator(),
                ],
              ),
            ),

          // Input bar
          _buildInputBar(strings, theme, isAiAvailable),
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic strings, ThemeData theme, bool isAiAvailable) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              strings.aiAssistantTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              strings.aiAssistantSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _buildSuggestions(strings).map((s) => _SuggestionChip(
                label: s,
                onTap: () => _sendMessage(s),
              )).toList(),
            ),
            if (!isAiAvailable) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.expense.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, color: AppColors.expense, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.aiApiKeyNotSet,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _buildSuggestions(dynamic strings) {
    final lang = ref.read(localeProvider).code;
    if (lang == 'id') {
      return [
        'Bagaimana kondisi keuangan saya bulan ini?',
        'Tips menghemat pengeluaran',
        'Bantu buat rencana menabung',
        'Apa kebiasaan baik untuk produktivitas?',
      ];
    }
    return [
      'How are my finances this month?',
      'Tips to reduce spending',
      'Help me plan savings',
      'What habits boost productivity?',
    ];
  }

  Widget _buildInputBar(dynamic strings, ThemeData theme, bool isAiAvailable) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: strings.aiChatPlaceholder,
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.small(
              heroTag: 'ai_send',
              backgroundColor: AppColors.primary,
              onPressed: () => _sendMessage(_textController.text),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isUser ? null : Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion Chip
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGlow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .asMap()
        .entries
        .map((e) => CurvedAnimation(
              parent: e.value,
              curve: Interval(e.key * 0.2, 1.0, curve: Curves.easeInOut),
            ))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (ctx, _) => Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.4 + _animations[i].value * 0.6),
              shape: BoxShape.circle,
            ),
            transform: Matrix4.translationValues(0, -4 * _animations[i].value, 0),
          ),
        );
      }),
    );
  }
}
