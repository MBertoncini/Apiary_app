import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Internal plain grey box — filled by the parent Shimmer animation.
class _GreyBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _GreyBox({this.width, required this.height, this.borderRadius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Internal: content of one skeleton list row (no Shimmer wrapper — wraps all at once in SkeletonListView).
class _SkeletonListItemContent extends StatelessWidget {
  const _SkeletonListItemContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _GreyBox(width: 44, height: 44, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _GreyBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                _GreyBox(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _GreyBox(width: 20, height: 20, borderRadius: 10),
        ],
      ),
    );
  }
}

/// A shimmer list of skeleton items — replaces SizedBox.shrink() during initial load.
/// Must be placed inside an [Expanded] or container with bounded height.
class SkeletonListView extends StatelessWidget {
  final int itemCount;

  const SkeletonListView({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => const Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _SkeletonListItemContent(),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for a dashboard card content area (no outer Card wrapper —
/// [DashboardCardBase] provides that). Used for the loading state of dashboard widgets.
class SkeletonDashboardContent extends StatelessWidget {
  final double height;

  const SkeletonDashboardContent({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

/// A shimmer header + content skeleton for detail screens (shown when detail data is null).
class SkeletonDetailHeader extends StatelessWidget {
  const SkeletonDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _GreyBox(width: 56, height: 56, borderRadius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _GreyBox(width: double.infinity, height: 20),
                      SizedBox(height: 8),
                      _GreyBox(width: 160, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _GreyBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const _GreyBox(width: 200, height: 14),
            const SizedBox(height: 8),
            const _GreyBox(width: 160, height: 14),
          ],
        ),
      ),
    );
  }
}
