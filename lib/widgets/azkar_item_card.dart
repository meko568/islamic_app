import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/azkar_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class AzkarItemCard extends StatefulWidget {
  final AzkarItem azkarItem;
  final int currentCount;
  final Function(int) onCountChange;
  final VoidCallback? onReset;
  final String lang;
  final bool showCounter;

  const AzkarItemCard({
    super.key,
    required this.azkarItem,
    required this.currentCount,
    required this.onCountChange,
    this.onReset,
    required this.lang,
    this.showCounter = true,
  });

  @override
  State<AzkarItemCard> createState() => _AzkarItemCardState();
}

class _AzkarItemCardState extends State<AzkarItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  bool get isCompleted => widget.currentCount >= widget.azkarItem.repeat;

  double get progressPercent => widget.currentCount / widget.azkarItem.repeat;

  Color get counterButtonColor {
    if (isCompleted) return AppColors.accent;
    if (progressPercent > 0.75) return AppColors.primaryLight;
    if (progressPercent > 0.5) return AppColors.primary;
    return AppColors.primary;
  }

  String _normalizeAzkarText(String value) {
    return value
        .replaceAll('الكافر', 'غير المسلم')
        .replaceAll('كافر', 'غير مسلم');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDirection =
        widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isCompleted ? Colors.grey.withValues(alpha: 0.3) : null,
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                widget.lang == 'ar'
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              // Header with reset icon
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCompleted && widget.onReset != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: widget.onReset,
                      tooltip: AppStrings.get('reset_this_item', widget.lang),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Arabic text (aligned based on language)
              Directionality(
                textDirection: textDirection,
                child: Text(
                  _normalizeAzkarText(widget.azkarItem.zekr),
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color:
                        isCompleted
                            ? Colors.grey.withValues(alpha: 0.7)
                            : (isDark
                                ? AppColors.lightText
                                : AppColors.darkText),
                    height: 1.8,
                  ),
                  textAlign:
                      widget.lang == 'ar' ? TextAlign.right : TextAlign.left,
                ),
              ),
              const SizedBox(height: 16),

              // Reference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.azkarItem.source,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Importance/Virtue
              if (widget.azkarItem.importance != null &&
                  widget.azkarItem.importance!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        widget.lang == 'ar'
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.get('importance', widget.lang),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: textDirection,
                        child: Text(
                          _normalizeAzkarText(widget.azkarItem.importance!),
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.lightText.withValues(alpha: 0.9)
                                    : AppColors.darkText.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                          textAlign:
                              widget.lang == 'ar'
                                  ? TextAlign.right
                                  : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Counter section (only show if showCounter is true)
              if (widget.showCounter) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress indicator
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('progress', widget.lang),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted
                                      ? AppColors.accent
                                      : counterButtonColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.currentCount}/${widget.azkarItem.repeat}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: counterButtonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tap counter button
                    GestureDetector(
                      onTapDown:
                          isCompleted ? null : (_) => _tapController.forward(),
                      onTapUp:
                          isCompleted
                              ? null
                              : (_) {
                                _tapController.reverse();
                                widget.onCountChange(widget.currentCount + 1);
                              },
                      onTapCancel:
                          isCompleted ? null : () => _tapController.reverse(),
                      child: IgnorePointer(
                        ignoring: isCompleted,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.88).animate(
                            CurvedAnimation(
                              parent: _tapController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors:
                                    isCompleted
                                        ? [
                                          Colors.grey.withValues(alpha: 0.5),
                                          Colors.grey.withValues(alpha: 0.3),
                                        ]
                                        : [
                                          counterButtonColor.withValues(
                                            alpha: 0.9,
                                          ),
                                          counterButtonColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isCompleted
                                          ? Colors.transparent
                                          : counterButtonColor.withValues(
                                            alpha: 0.3,
                                          ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isCompleted)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 28,
                                  )
                                else
                                  Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                if (!isCompleted) ...[
                                  const SizedBox(height: 2),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Completion indicator
              if (isCompleted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.get('completed_exclamation', widget.lang),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
