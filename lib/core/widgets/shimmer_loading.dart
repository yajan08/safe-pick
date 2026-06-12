import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // Smoothed out the gradient contrast for a premium, calm transition sweep
    return Shimmer.fromColors(
      baseColor: AppTheme.surface.withValues(alpha: 0.6),
      highlightColor: Colors.grey.shade800.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  
  const ShimmerCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Elegant glassmorphism background surface
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24), // Smoothed rounding radius
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 140, height: 20, borderRadius: 10),
          const Spacer(),
          const ShimmerLoading(width: double.infinity, height: 14, borderRadius: 6),
          const SizedBox(height: 10),
          const ShimmerLoading(width: 180, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerCard(height: itemHeight);
      },
    );
  }
}

class ShimmerStudentRow extends StatelessWidget {
  const ShimmerStudentRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Profile ring placeholder
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
            ),
            child: const ShimmerLoading(width: 36, height: 36, borderRadius: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerLoading(width: 130, height: 16, borderRadius: 8),
                SizedBox(height: 8),
                ShimmerLoading(width: 75, height: 12, borderRadius: 6),
              ],
            ),
          ),
          // Action button/badge trailing placeholder
          const ShimmerLoading(width: 70, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}