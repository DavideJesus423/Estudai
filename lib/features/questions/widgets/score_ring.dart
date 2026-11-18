import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Anel de aproveitamento (0 a 1) com o percentual no centro.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.value, this.size = 156});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Semantics(
      label: 'Aproveitamento: $percent por cento',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.primarySoft,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
