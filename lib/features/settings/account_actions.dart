import 'package:flutter/material.dart';
import '../../theme/glassmorphic_card.dart';

class AccountActionsSection extends StatelessWidget {
  final VoidCallback onSignOut;
  final Function(BuildContext) onDelete;

  const AccountActionsSection({
    super.key,
    required this.onSignOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: GlassmorphicCard(
            borderRadius: 20,
            blur: 10,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sign Out", style: theme.textTheme.bodyLarge),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Sign Out"),
                  onPressed: onSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: GlassmorphicCard(
            borderRadius: 16,
            blur: 8,
            opacity: 0.22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Delete your Account",
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                      Text(
                        "Irreversible action!",
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete"),
                  onPressed: () => onDelete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
