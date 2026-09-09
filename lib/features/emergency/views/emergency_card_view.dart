import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/emergency_card.dart';
import '../providers/emergency_provider.dart';

/// Emergency SOS Card View.
/// Accessible WITHOUT vault PIN from Settings and the shell navigation.
/// Shows blood type, allergies, and emergency contacts in a bold, readable layout.
class EmergencyCardView extends ConsumerWidget {
  const EmergencyCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(emergencyCardProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0000), // Deep red background for SOS urgency
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.red, size: 18),
            ),
            const SizedBox(width: 8),
            Text(strings.emergencyCardTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
            tooltip: 'Edit Kartu Darurat',
            onPressed: () => _showEditDialog(context, ref, cardAsync.value),
          ),
        ],
      ),
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (card) {
          if (card == null) {
            return _buildEmptyState(context, ref, strings);
          }
          return _buildCardContent(context, ref, card, strings);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, dynamic strings) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emergency_outlined, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(strings.emergencyCardEmpty, style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(context, ref, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Isi Kartu Darurat'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref, EmergencyCard card, dynamic strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Owner & Blood Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.ownerName.isNotEmpty)
                      Text(card.ownerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(strings.emergencyCardOwner, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              if (card.bloodType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text(card.bloodType, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const Text('Gol. Darah', style: TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Allergies
          if (card.allergies.isNotEmpty) ...[
            _SosSection(
              icon: '⚠️',
              title: strings.emergencyAllergyLabel,
              content: card.allergies,
              highlight: true,
            ),
            const SizedBox(height: 12),
          ],

          // Medical Notes
          if (card.medicalNotes.isNotEmpty) ...[
            _SosSection(
              icon: '🏥',
              title: strings.emergencyMedicalLabel,
              content: card.medicalNotes,
            ),
            const SizedBox(height: 12),
          ],

          // Emergency Contacts
          if (card.emergencyContacts.isNotEmpty) ...[
            Text(strings.emergencyContactsLabel, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...card.emergencyContacts.map((contact) => _EmergencyContactTile(contact: contact)),
          ],

          const SizedBox(height: 32),
          Center(
            child: Text(
              'No PIN required • Always accessible',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, EmergencyCard? existing) {
    showDialog(
      context: context,
      builder: (_) => _EmergencyEditDialog(existing: existing),
    );
  }
}

class _SosSection extends StatelessWidget {
  const _SosSection({required this.icon, required this.title, required this.content, this.highlight = false});
  final String icon;
  final String title;
  final String content;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? Colors.red.withOpacity(0.4) : Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({required this.contact});
  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Copy phone to clipboard on tap
          Clipboard.setData(ClipboardData(text: contact.phone));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nomor ${contact.name} disalin'), duration: const Duration(seconds: 2)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.red, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (contact.relationship.isNotEmpty)
                      Text(contact.relationship, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(contact.phone, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Text('Ketuk untuk salin', style: TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Emergency Card Edit Dialog — StatefulWidget
// ─────────────────────────────────────────────
class _EmergencyEditDialog extends ConsumerStatefulWidget {
  const _EmergencyEditDialog({this.existing});
  final EmergencyCard? existing;

  @override
  ConsumerState<_EmergencyEditDialog> createState() => _EmergencyEditDialogState();
}

class _EmergencyEditDialogState extends ConsumerState<_EmergencyEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bloodTypeCtrl;
  late final TextEditingController _allergyCtrl;
  late final TextEditingController _medNotesCtrl;
  late List<EmergencyContact> _contacts;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.ownerName ?? '');
    _bloodTypeCtrl = TextEditingController(text: widget.existing?.bloodType ?? '');
    _allergyCtrl = TextEditingController(text: widget.existing?.allergies ?? '');
    _medNotesCtrl = TextEditingController(text: widget.existing?.medicalNotes ?? '');
    _contacts = List.from(widget.existing?.emergencyContacts ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bloodTypeCtrl.dispose();
    _allergyCtrl.dispose();
    _medNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Kartu Darurat', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _buildTextField(_nameCtrl, 'Nama Pemilik', Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _buildTextField(_bloodTypeCtrl, 'Golongan Darah (A, B, AB, O)', Icons.bloodtype_rounded),
                const SizedBox(height: 10),
                _buildTextField(_allergyCtrl, 'Alergi (pisahkan dengan koma)', Icons.warning_amber_rounded, maxLines: 2),
                const SizedBox(height: 10),
                _buildTextField(_medNotesCtrl, 'Catatan Medis', Icons.medical_information_rounded, maxLines: 3),
                const SizedBox(height: 16),
                // Contacts
                const Text('Kontak Darurat', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._contacts.asMap().entries.map((e) => _contactRow(e.key, e.value)),
                TextButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah Kontak'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Simpan'),
                      ),
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

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      scrollPadding: const EdgeInsets.only(bottom: 160),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }

  Widget _contactRow(int index, EmergencyContact contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(contact.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.expense, size: 20),
            onPressed: () => setState(() => _contacts.removeAt(index)),
          ),
        ],
      ),
    );
  }

  void _addContact() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kontak Darurat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama'), scrollPadding: const EdgeInsets.only(bottom: 200)),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor Telepon'), scrollPadding: const EdgeInsets.only(bottom: 200)),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Hubungan (Ibu, Ayah, dll.)'), scrollPadding: const EdgeInsets.only(bottom: 200)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                setState(() {
                  _contacts.add(EmergencyContact(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), relationship: relCtrl.text.trim()));
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    final card = EmergencyCard(
      ownerName: _nameCtrl.text.trim(),
      bloodType: _bloodTypeCtrl.text.trim(),
      allergies: _allergyCtrl.text.trim(),
      medicalNotes: _medNotesCtrl.text.trim(),
      emergencyContacts: _contacts,
      updatedAt: DateTime.now(),
    );
    await ref.read(emergencyCardProvider.notifier).saveCard(card);
    if (mounted) Navigator.of(context).pop();
  }
}
