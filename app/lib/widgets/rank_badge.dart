import 'package:flutter/material.dart';
import '../warrior_theme.dart';
import '../warrior_constants.dart';

/// Rank Badge Widget - Displays warrior rank with visual flair
class RankBadge extends StatelessWidget {
  final int rankLevel;
  final double size;
  final bool showProgress;
  final int? currentXp;
  final int? xpToNext;

  const RankBadge({
    super.key,
    required this.rankLevel,
    this.size = 120,
    this.showProgress = false,
    this.currentXp,
    this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    final rank = WarriorConstants.getRank(rankLevel);
    final progress = showProgress && currentXp != null && xpToNext != null
        ? (currentXp! / (currentXp! + xpToNext!)).clamp(0.0, 1.0)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                rank.color.withValues(alpha: 0.8),
                rank.color,
                rank.color.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: rank.color.withValues(alpha: 0.4),
                blurRadius: size * 0.2,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Progress ring
              if (progress != null)
                CustomPaint(
                  painter: ProgressRingPainter(
                    progress: progress,
                    color: WarriorTheme.gold,
                    backgroundColor: WarriorTheme.ironDark,
                    strokeWidth: size * 0.06,
                  ),
                ),
              
              // Icon
              Center(
                child: Icon(
                  rank.icon,
                  size: size * 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: WarriorTheme.spaceMd),
        
        // Rank Name
        Text(
          rank.name.toUpperCase(),
          style: WarriorTheme.labelMedium.copyWith(
            color: rank.color,
            letterSpacing: 2,
          ),
        ),
        
        const SizedBox(height: WarriorTheme.spaceXs),
        
        // Subtitle
        Text(
          rank.subtitle,
          style: WarriorTheme.bodySmall.copyWith(
            color: WarriorTheme.ash,
          ),
        ),
        
        // XP Progress
        if (showProgress && currentXp != null && xpToNext != null) ...[
          const SizedBox(height: WarriorTheme.spaceSm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$currentXp',
                style: WarriorTheme.labelSmall.copyWith(
                  color: WarriorTheme.bronze,
                ),
              ),
              Text(
                ' / ${currentXp! + xpToNext!} XP',
                style: WarriorTheme.labelSmall.copyWith(
                  color: WarriorTheme.ash,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Compact Rank Badge for inline use
class RankBadgeCompact extends StatelessWidget {
  final int rankLevel;
  final double size;

  const RankBadgeCompact({
    super.key,
    required this.rankLevel,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final rank = WarriorConstants.getRank(rankLevel);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(WarriorTheme.cornerMinimal),
        border: Border.all(
          color: rank.color,
          width: 1,
        ),
      ),
      child: Icon(
        rank.icon,
        size: size * 0.5,
        color: rank.color,
      ),
    );
  }
}

/// Mini rank chip with name
class RankChip extends StatelessWidget {
  final int rankLevel;
  final VoidCallback? onTap;

  const RankChip({
    super.key,
    required this.rankLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rank = WarriorConstants.getRank(rankLevel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WarriorTheme.spaceMd,
          vertical: WarriorTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: rank.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(WarriorTheme.cornerMinimal),
          border: Border.all(
            color: rank.color.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rank.icon,
              size: 16,
              color: rank.color,
            ),
            const SizedBox(width: WarriorTheme.spaceSm),
            Text(
              rank.name.toUpperCase(),
              style: WarriorTheme.labelSmall.copyWith(
                color: rank.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress Ring Painter
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (3.14159 / 180), // Start from top
      progress * 2 * 3.14159,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// XP Progress Bar
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int xpToNext;
  final double height;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.xpToNext,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp / (currentXp + xpToNext)).clamp(0.0, 1.0);
    final total = currentXp + xpToNext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: WarriorTheme.ironDark,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    WarriorTheme.bronze,
                    WarriorTheme.gold,
                    WarriorTheme.bronze,
                  ],
                ),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: WarriorTheme.spaceSm),
        
        // XP text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentXp XP',
              style: WarriorTheme.labelSmall.copyWith(
                color: WarriorTheme.bronze,
              ),
            ),
            Text(
              '$total XP',
              style: WarriorTheme.labelSmall.copyWith(
                color: WarriorTheme.ash,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
