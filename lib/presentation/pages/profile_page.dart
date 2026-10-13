import 'package:flutter/material.dart';

import '../../domain/entities/study_user.dart';
import '../../domain/repositories/authentication_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.authenticationRepository,
    this.statusMessage,
  });

  final StudyUser user;
  final AuthenticationRepository authenticationRepository;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName.characters.first.toUpperCase()
        : user.email.characters.first.toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070D1E),
              Color(0xFF0B132B),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundImage: user.photoUrl.isEmpty
                          ? null
                          : NetworkImage(user.photoUrl),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: const Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusMessage!,
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF152033)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      _ProfileField(label: 'Tên hiển thị', value: user.displayName),
                      const Divider(color: Color(0xFF334155), height: 1),
                      _ProfileField(label: 'Email Google', value: user.email),
                      const Divider(color: Color(0xFF334155), height: 1),
                      _ProfileField(
                        label: 'Email đã xác minh',
                        value: user.emailVerified ? 'Có' : 'Chưa',
                      ),
                      const Divider(color: Color(0xFF334155), height: 1),
                      _ProfileField(label: 'Firebase UID', value: user.id),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('signOutButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: Text(
                          'Bạn có chắc muốn đăng xuất khỏi tài khoản ${user.email}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      try {
                        await authenticationRepository.signOut();
                      } catch (e) {
                        debugPrint('SignOut error: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: SelectableText(
      value.isEmpty ? 'Chưa cung cấp' : value,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFFF8FAFC),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
