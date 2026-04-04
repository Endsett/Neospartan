import 'package:flutter/material.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';

/// Banner to indicate guest mode
class GuestModeBanner extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const GuestModeBanner({super.key, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: LaconicTheme.spartanBronze.withValues(alpha: 1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are using Guest Mode - Data stored locally only',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ),
          if (onUpgrade != null) ...[
            TextButton(
              onPressed: onUpgrade,
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small guest mode indicator for use in headers
class GuestModeIndicator extends StatelessWidget {
  const GuestModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            color: LaconicTheme.spartanBronze,
            size: 14,
          ),
          const SizedBox(width: 4),
          const Text(
            'GUEST',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
