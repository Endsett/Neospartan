import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';

/// Shimmer Loading - Skeleton loading states for data loading
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: LaconicTheme.ironGray.withOpacity(0.3),
      highlightColor: LaconicTheme.surfaceOverlay.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray,
          borderRadius: isCircle
              ? BorderRadius.circular(height / 2)
              : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Card skeleton for list items
class CardSkeleton extends StatelessWidget {
  final int lines;

  const CardSkeleton({
    super.key,
    this.lines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LaconicTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerLoading(width: 48, height: 48, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 120, height: 16),
                    const SizedBox(height: 8),
                    ShimmerLoading(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < lines; i++) ...[
            ShimmerLoading(
              width: double.infinity,
              height: 12,
              borderRadius: 6,
            ),
            if (i < lines - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Grid skeleton for exercise or workout grids
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(
        itemCount,
        (index) => const CardSkeleton(lines: 2),
      ),
    );
  }
}
