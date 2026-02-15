import 'package:flutter/material.dart';
import 'package:yourapp/ui/theme/app_theme.dart';

class NightRiderLoading extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const NightRiderLoading({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  State<NightRiderLoading> createState() => _NightRiderLoadingState();
}

class _NightRiderLoadingState extends State<NightRiderLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _NightRiderPainter(
              progress: _controller.value,
              color: widget.color ?? AppColors.accentBlue,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _NightRiderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _NightRiderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const totalSegments = 3;
    final segmentAngle = (2 * 3.14159) / totalSegments;
    final startAngle = progress * 2 * 3.14159;

    for (int i = 0; i < totalSegments; i++) {
      final segmentProgress = (progress * totalSegments + i) % totalSegments;
      final opacity = (1.0 - segmentProgress / totalSegments).clamp(0.2, 1.0);

      paint.color = color.withValues(alpha: opacity);

      final sweepAngle = segmentAngle * 0.6;
      final angle = startAngle + (i * segmentAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NightRiderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class NightRiderButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;

  const NightRiderButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.textPrimary,
          side: BorderSide(
            color: isDisabled
                ? AppColors.border
                : (foregroundColor ?? AppColors.accentBlue),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: _buildChild(),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.accentBlue,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NightRiderLoading(
            size: 16,
            color: foregroundColor ?? Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

class NightRiderIndicator extends StatelessWidget {
  final String message;
  final Color? color;

  const NightRiderIndicator({
    super.key,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? AppColors.accentBlue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NightRiderLoading(
            size: 24,
            color: color ?? AppColors.accentBlue,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: AppTextStyles.monoSmall.copyWith(
              color: color ?? AppColors.accentBlue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
