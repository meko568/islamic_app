import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/azkar_model.dart';
import '../widgets/azkar_item_card.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/tracker_provider.dart';

class AzkarDetailScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarDetailScreen({super.key, required this.category});

  @override
  State<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends State<AzkarDetailScreen> {
  // Map to store current count for each azkar item (indexed by azkar text)
  late Map<String, int> counters;

  @override
  void initState() {
    super.initState();
    // Initialize counters for all azkar items
    counters = {};
    for (var item in widget.category.items) {
      counters[item.zekr] = 0;
    }
  }

  void updateCounter(String azkarZekr, int newCount) {
    setState(() {
      counters[azkarZekr] = newCount;
    });
    _checkCategoryCompletion();
  }

  void _checkCategoryCompletion() {
    if (getCompletedCount() != widget.category.items.length) return;
    final taskId = switch (widget.category.name) {
      'Morning' => 'morning_azkar',
      'Evening' => 'evening_azkar',
      _ => null,
    };
    if (taskId != null) {
      context.read<TrackerProvider>().markAutoDone(taskId);
    }
  }

  void resetCounter(String azkarZekr) {
    setState(() {
      counters[azkarZekr] = 0;
    });
  }

  int getCompletedCount() {
    return widget.category.items.where((item) {
      final count = counters[item.zekr] ?? 0;
      return count >= item.repeat;
    }).length;
  }

  String _getCategoryTitle(String categoryName, String lang) {
    // Map the category name (from API / _categoryMappings) to AppStrings key
    switch (categoryName) {
      case 'Morning':
        return AppStrings.get('morning_azkar', lang);
      case 'Evening':
        return AppStrings.get('evening_azkar', lang);
      case 'After Salah':
        return AppStrings.get('after_salah', lang);
      case 'Before Sleep':
        return AppStrings.get('before_sleep', lang);
      case 'Waking Up':
        return AppStrings.get('waking_up', lang);
      case 'Prayer':
        return AppStrings.get('prayer_related', lang);
      case 'Mosque':
        return AppStrings.get('mosque_related', lang);
      case 'Travel':
        return AppStrings.get('travel_duas', lang);
      case 'Food and Drink':
        return AppStrings.get('food_drink', lang);
      case 'Home':
        return AppStrings.get('home_duas', lang);
      case 'Anxiety and Distress':
        return AppStrings.get('anxiety_distress', lang);
      case 'Protection':
        return AppStrings.get('protection_duas', lang);
      case 'Forgiveness':
        return AppStrings.get('forgiveness_repentance', lang);
      case 'Hajj and Umrah':
        return AppStrings.get('hajj_umrah', lang);
      case 'Bathroom - Entering':
        return AppStrings.get('bathroom_entering', lang);
      case 'Bathroom - Leaving':
        return AppStrings.get('bathroom_leaving', lang);
      case 'Clothing - Wearing':
        return AppStrings.get('clothing_wearing', lang);
      case 'Clothing - New Garment':
        return AppStrings.get('clothing_new_garment', lang);
      case 'Clothing - Seeing Someone Wear New':
        return AppStrings.get('clothing_seeing_new', lang);
      case 'Clothing - Before Undressing':
        return AppStrings.get('clothing_before_undressing', lang);
      case 'Ablution - Before':
        return AppStrings.get('ablution_before', lang);
      case 'Ablution - After':
        return AppStrings.get('ablution_after', lang);
      case 'Debt - Settling':
      case 'Debt - When Settled':
        return AppStrings.get('debt_settling', lang);
      case 'Sick - Visiting':
        return AppStrings.get('sick_visiting', lang);
      case 'Sick - Excellence of Visiting':
        return AppStrings.get('sick_excellence_visiting', lang);
      case 'Sick - When Renounced Hope':
        return AppStrings.get('sick_renounced_hope', lang);
      case 'Sneezing - Upon Sneezing':
        return AppStrings.get('sneezing_upon', lang);
      case 'Sneezing - Non-Muslim Praises':
        return AppStrings.get('sneezing_non_muslim', lang);
      case 'Market - Entering':
        return AppStrings.get('market_entering', lang);
      case 'Praise - When Praised':
        return AppStrings.get('praise_when_praised', lang);
      default:
        // Fallback if we don't have the key
        return categoryName;
    }
  }

  bool _isDuaCategory(String categoryName) {
    final title = _getCategoryTitle(categoryName, 'ar');
    return title.contains('أدعية');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final completedCount = getCompletedCount();
    final totalItems = widget.category.items.length;
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getCategoryTitle(widget.category.name, lang),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 28),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  for (var item in widget.category.items) {
                    counters[item.zekr] = 0;
                  }
                });
              },
              tooltip: AppStrings.get('reset_all', lang),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header with category info
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get('total_items', lang),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accent.withValues(alpha: 0.2),
                                AppColors.accent.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            AppStrings.get(
                              'completed',
                              lang,
                              params: {
                                'completed': completedCount.toString(),
                                'total': totalItems.toString(),
                              },
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Progress bar
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value:
                              totalItems > 0 ? completedCount / totalItems : 0,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Azkar items list
              if (widget.category.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('no_items_yet', lang),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.category.items.length,
                    itemBuilder: (context, index) {
                      final azkarItem = widget.category.items[index];
                      final currentCount = counters[azkarItem.zekr] ?? 0;

                      return AzkarItemCard(
                        azkarItem: azkarItem,
                        currentCount: currentCount,
                        onCountChange: (newCount) {
                          updateCounter(azkarItem.zekr, newCount);
                        },
                        onReset: () {
                          resetCounter(azkarItem.zekr);
                        },
                        lang: lang,
                        showCounter: !_isDuaCategory(widget.category.name),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
