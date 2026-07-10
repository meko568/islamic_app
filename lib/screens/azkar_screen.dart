import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/azkar_data.dart';
import '../models/azkar_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import 'azkar_grouped_detail_screen.dart';

abstract class AzkarSection {}

class AzkarCategorySection extends AzkarSection {
  final AzkarCategory category;
  AzkarCategorySection(this.category);
}

class AzkarGroupedSection extends AzkarSection {
  final String name;
  final String arabicName;
  final List<AzkarCategory> categories;

  AzkarGroupedSection({
    required this.name,
    required this.arabicName,
    required this.categories,
  });
}

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  List<AzkarCategory> categories = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final data = await AzkarData.getCategories();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final data = await AzkarData.fetchAndCacheData();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      if (mounted) {
        final lang = context.read<SettingsProvider>().appLanguage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.get('failed_to_fetch_data', lang)}: $e',
            ),
          ),
        );
      }
    }
  }

  String _getCategoryTitle(String categoryName, String lang) {
    // Map the category name (from API / _categoryMappings) to AppStrings key
    switch (categoryName) {
      case 'Morning':
        return AppStrings.get('morning_azkar', lang);
      case 'Evening':
        return AppStrings.get('evening_azkar', lang);
      case 'Several Duas':
        return AppStrings.get('several_duas', lang);
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

  List<AzkarSection> _getDisplaySections() {
    final regularCategories =
        categories
            .where((category) => category.items.length >= 4)
            .map((category) => AzkarCategorySection(category))
            .toList();
    final shortCategories =
        categories.where((category) => category.items.length < 4).toList();

    if (shortCategories.isEmpty) {
      return regularCategories;
    }

    return [
      ...regularCategories,
      AzkarGroupedSection(
        name: 'Several Duas',
        arabicName: 'أدعية متنوعه',
        categories: shortCategories,
      ),
    ];
  }

  bool _isDuaSectionTitle(String title) {
    return title.contains('أدعية') || title.contains('ادعية');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('azkar', lang),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 28),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!AzkarData.isDataLoaded())
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _fetchData,
                tooltip: AppStrings.get('download_azkar', lang),
              ),
          ],
        ),
        body: SafeArea(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('failed_to_load_data', lang),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.download),
                          label: Text(AppStrings.get('download_azkar', lang)),
                        ),
                      ],
                    ),
                  )
                  : categories.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('no_azkar_data_loaded', lang),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.download),
                          label: Text(AppStrings.get('download_azkar', lang)),
                        ),
                      ],
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final displaySections = _getDisplaySections();
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displaySections.length,
                              itemBuilder: (context, index) {
                                final currentSection = displaySections[index];

                                if (currentSection is AzkarCategorySection) {
                                  final category = currentSection.category;
                                  final title = _getCategoryTitle(
                                    category.name,
                                    lang,
                                  );
                                  final itemCount = category.items.length;

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primaryLight.withValues(
                                              alpha: 0.08,
                                            ),
                                            AppColors.accent.withValues(
                                              alpha: 0.05,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/azkar-detail',
                                            arguments: category,
                                          );
                                        },
                                        leading: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.primary.withValues(
                                                  alpha: 0.9,
                                                ),
                                                AppColors.primaryLight
                                                    .withValues(alpha: 0.7),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.menu_book,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          title,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                AppStrings.get(
                                                  'items_count',
                                                  lang,
                                                  params: {
                                                    'count':
                                                        itemCount.toString(),
                                                    'plural':
                                                        itemCount == 1
                                                            ? ''
                                                            : 's',
                                                  },
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final groupedSection =
                                    currentSection as AzkarGroupedSection;
                                final title = _getCategoryTitle(
                                  groupedSection.name,
                                  lang,
                                );
                                final totalCount =
                                    groupedSection.categories
                                        .expand((category) => category.items)
                                        .length;

                                final canOpenGroupedDetail = _isDuaSectionTitle(
                                  groupedSection.arabicName,
                                );

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primaryLight.withValues(
                                            alpha: 0.08,
                                          ),
                                          AppColors.accent.withValues(
                                            alpha: 0.05,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap:
                                                canOpenGroupedDetail
                                                    ? () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AzkarGroupedDetailScreen(
                                                                title: title,
                                                                categories:
                                                                    groupedSection
                                                                        .categories,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                    : null,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .titleLarge,
                                                    ),
                                                  ),
                                                  if (canOpenGroupedDetail)
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Colors.grey[400],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              AppStrings.get(
                                                'items_count',
                                                lang,
                                                params: {
                                                  'count':
                                                      totalCount.toString(),
                                                  'plural':
                                                      totalCount == 1
                                                          ? ''
                                                          : 's',
                                                },
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
