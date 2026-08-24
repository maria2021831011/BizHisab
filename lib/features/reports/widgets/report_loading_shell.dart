import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Full-screen skeleton for the Reports screen — 5 shimmer cards stacked
/// where the summary grid + chart cards normally live. Mirrors the real
/// layout enough that the content swap doesn't cause a jarring reflow.
class ReportLoadingShell extends StatelessWidget {
  const ReportLoadingShell({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _Bar(width: MediaQuery.of(context).size.width - 32, height: 48),
          const SizedBox(height: 16),
          _Bar(width: MediaQuery.of(context).size.width - 32, height: 88),
          const SizedBox(height: 12),
          _Bar(width: MediaQuery.of(context).size.width - 32, height: 88),
          const SizedBox(height: 24),
          _Bar(width: MediaQuery.of(context).size.width - 32, height: 200),
          const SizedBox(height: 16),
          _Bar(width: MediaQuery.of(context).size.width - 32, height: 200),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;

  const _Bar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}