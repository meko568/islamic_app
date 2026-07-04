import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    this.isActive = true,
    this.onTap,
    this.gradient,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _controller.forward();
  }

  void _onTapUp() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.isActive ? (_) => _onTapDown() : null,
      onTapUp: widget.isActive ? (_) => _onTapUp() : null,
      onTapCancel: widget.isActive ? _onTapUp : null,
      onTap: widget.isActive ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: widget.isActive ? 4 : 1,
          color: Colors.transparent,
          shadowColor: AppColors.primary.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient:
                  widget.isActive
                      ? (widget.gradient ??
                          LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight.withValues(alpha: 0.15),
                              AppColors.accent.withValues(alpha: 0.1),
                            ],
                          ))
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[300]!.withValues(alpha: 0.5),
                          Colors.grey[400]!.withValues(alpha: 0.3),
                        ],
                      ),
              border: Border.all(
                color:
                    widget.isActive
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.grey[300]!.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 48,
                        color:
                            widget.isActive
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                                : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              widget.isActive
                                  ? (isDark
                                      ? AppColors.lightText
                                      : AppColors.darkText)
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isActive)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
