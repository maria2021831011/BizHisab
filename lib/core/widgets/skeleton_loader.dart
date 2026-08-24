import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Lightweight shimmering rectangle. Use everywhere we need a placeholder
/// while data is loading.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A313A) : const Color(0xFFE7EAF0);
    final highlight =
        isDark ? const Color(0xFF3A424C) : const Color(0xFFF6F7FA);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: borderRadius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Generic card-shaped skeleton container. Composes [SkeletonBox]es inside
/// a soft rounded card so callers can stack multiple skeletons easily.
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const SkeletonCard({
    super.key,
    this.height = 96,
    this.padding = const EdgeInsets.all(16),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: SizedBox(height: height, child: child),
      ),
    );
  }
}

/// Pre-built placeholder for a single summary metric (e.g. "Today's Sales").
class MetricSkeleton extends StatelessWidget {
  const MetricSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SkeletonBox(width: 90, height: 12),
          SizedBox(height: 12),
          SkeletonBox(width: 120, height: 22),
        ],
      ),
    );
  }
}

/// List-row skeleton (used for recent-transactions placeholder).
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 10),
              ],
            ),
          ),
          const SkeletonBox(width: 70, height: 14),
        ],
      ),
    );
  }
}

/// Subtle section title placeholder (used while loading).
class SectionTitleSkeleton extends StatelessWidget {
  const SectionTitleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SkeletonBox(width: 140, height: 14),
    );
  }
}

/// Static utility - a fixed skeleton used by the dashboard while the very
/// first load for a businessId is in flight. Mirrors the layout the real
/// screen renders so the transition is seamless.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting header
          Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 22),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 14),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Today section
          Row(
            children: const [
              Expanded(child: MetricSkeleton()),
              SizedBox(width: 12),
              Expanded(child: MetricSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonCard(
            height: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 90, height: 12),
                SizedBox(height: 12),
                SkeletonBox(width: 160, height: 22),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Month section
          const SectionTitleSkeleton(),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: MetricSkeleton()),
              SizedBox(width: 12),
              Expanded(child: MetricSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: MetricSkeleton()),
              SizedBox(width: 12),
              Expanded(child: MetricSkeleton()),
            ],
          ),
          const SizedBox(height: 20),
          // Recent transactions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 14),
                  SizedBox(height: 12),
                  ListRowSkeleton(),
                  ListRowSkeleton(),
                  ListRowSkeleton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact shimmer block used by [AppColors.primary] surfaces so the
/// dashboard hero card has a matching placeholder.
class HeroSkeleton extends StatelessWidget {
  const HeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.35),
        highlightColor: Colors.white.withValues(alpha: 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            SkeletonBox(width: 120, height: 12),
            SizedBox(height: 12),
            SkeletonBox(width: 200, height: 28),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 70, height: 10),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 16),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 70, height: 10),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
