import 'package:flutter/material.dart';
import '../../theme/glassmorphic_card.dart';

class ProfileAccountSection extends StatelessWidget {
  final dynamic user;
  final dynamic avatar;
  final VoidCallback onSwitchAccount;

  const ProfileAccountSection({
    super.key,
    required this.user,
    required this.avatar,
    required this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
      child: Hero(
        tag: "profile-icon",
        child: GlassmorphicCard(
          borderRadius: 34,
          blur: 18,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: avatar as ImageProvider,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.09),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? "User",
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user?.email ?? "",
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.switch_account),
                label: const Text("Switch"),
                onPressed: onSwitchAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.86),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
