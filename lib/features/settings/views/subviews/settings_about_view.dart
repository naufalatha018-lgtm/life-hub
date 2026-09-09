import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';

class SettingsAboutView extends ConsumerWidget {
  const SettingsAboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsAboutTitle,
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
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Actividata',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.aboutMultiPlatform,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildInfoRow('Versi Aplikasi', '1.0.0 (Build 1)'),
                  const Divider(height: 18, color: AppColors.cardBorderSubtle),
                  _buildInfoRow('Platform Engine', 'Flutter 3.x (Multi-Platform)'),
                  const Divider(height: 18, color: AppColors.cardBorderSubtle),
                  _buildInfoRow('Database Enkripsi', 'SQLite FFI + AES-256-GCM'),
                  const Divider(height: 18, color: AppColors.cardBorderSubtle),
                  _buildInfoRow('Keamanan Kunci', 'PBKDF2-HMAC-SHA256 (100k iters)'),
                  const Divider(height: 18, color: AppColors.cardBorderSubtle),
                  _buildInfoRow('Lisensi & Distribusi', 'Commercial Production Ready'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Privasi & Desain Offline-First',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Seluruh catatan transaksi keuangan, agenda tugas, berkas rahasia, dan catatan pribadi Anda disimpan secara lokal pada perangkat Anda dengan enkripsi end-to-end berstandar militer. Tidak ada data pribadi yang dikirimkan ke server pihak ketiga.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
