import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthdayDisplayCtrl;
  DateTime? _selectedBirthday;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = AuthService().cachedProfile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _birthdayDisplayCtrl = TextEditingController(
      text: p?.birthday != null ? _formatForDisplay(p!.birthday!) : '',
    );
    if (p?.birthday != null) {
      _selectedBirthday = _parseBirthday(p!.birthday!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthdayDisplayCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseBirthday(String raw) {
    try {
      if (raw.contains('-')) return DateTime.parse(raw);
      final parts = raw.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _formatForDisplay(String raw) {
    final date = _parseBirthday(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatForApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayDisplayCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().updateProfile(
        name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
        birthday: _selectedBirthday != null
            ? _formatForApi(_selectedBirthday!)
            : null,
      );
      if (!mounted) return;
      context.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = AuthService().cachedProfile?.phone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty &&
                            v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _birthdayDisplayCtrl,
                      readOnly: true,
                      onTap: _pickBirthday,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'Tap to select',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixIcon: Icon(Icons.calendar_today_outlined,
                            size: 18, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone read-only
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mobile Number',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                phone,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Cannot change',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
