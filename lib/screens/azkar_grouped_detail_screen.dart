import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/azkar_model.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class AzkarGroupedDetailScreen extends StatelessWidget {
  final String title;
  final List<AzkarCategory> categories;

  const AzkarGroupedDetailScreen({
    super.key,
    required this.title,
    required this.categories,
  });

  String _getCategoryTitle(String categoryName, String lang) {
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
        return categoryName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final textDirection = lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 28),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryTitle = _getCategoryTitle(category.name, lang);

              return Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        lang == 'ar'
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              categoryTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign:
                                  lang == 'ar'
                                      ? TextAlign.right
                                      : TextAlign.left,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${category.items.length}',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment:
                            lang == 'ar'
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children:
                            category.items.map((item) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      lang == 'ar'
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Directionality(
                                      textDirection: textDirection,
                                      child: Text(
                                        item.zekr,
                                        style: GoogleFonts.amiri(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                        ),
                                        textAlign:
                                            lang == 'ar'
                                                ? TextAlign.right
                                                : TextAlign.left,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.source,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign:
                                          lang == 'ar'
                                              ? TextAlign.right
                                              : TextAlign.left,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
