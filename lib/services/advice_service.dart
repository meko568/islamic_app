import 'dart:math';

class AdviceService {
  static final _random = Random();

  static const _generalAdvicesAr = [
    'المداومة على القليل خير من الانقطاع عن الكثير.',
    'إن الله يحب إذا عمل أحدكم عملاً أن يتقنه.',
    'لا تيأس من روح الله، فغداً سيكون أفضل بإذن الله.',
    'اجعل لنفسك وِرداً يومياً لا تتركه أبداً.',
    'تذكر أن كل عمل صالح تقرباً لله هو رفعة لك في الدرجات.',
  ];

  static const _generalAdvicesEn = [
    'Consistency in small deeds is better than large deeds that are interrupted.',
    'Allah loves it when you do something, to do it excellently.',
    'Never despair of the mercy of Allah; tomorrow will be better, God willing.',
    'Establish a daily routine for yourself and never abandon it.',
    'Remember that every good deed done for Allah raises your status in the hereafter.',
  ];

  static const _prayerAdvicesAr = [
    'الصلاة هي عماد الدين، حاول ألا تفوتك أي صلاة في وقتها.',
    'أقرب ما يكون العبد من ربه وهو ساجد، فأكثر من الدعاء.',
    'الصلاة تجلب الرزق وتبارك في الوقت، حافظ عليها.',
  ];

  static const _prayerAdvicesEn = [
    'Prayer is the pillar of religion; try not to miss any prayer on time.',
    'The closest a servant is to his Lord is when he is prostrating, so increase your supplication.',
    'Prayer brings provision and blesses time; maintain it carefully.',
  ];

  static const _azkarAdvicesAr = [
    'ألا بذكر الله تطمئن القلوب، حافظ على أذكارك لتجد السكينة.',
    'من حافظ على أذكار الصباح والمساء كان في حفظ الله طوال يومه.',
    'الذكر هو حياة القلب، فلا تدع قلبك يذبل.',
  ];

  static const _azkarAdvicesEn = [
    'Verily, in the remembrance of Allah do hearts find rest. Keep your Azkar to find peace.',
    'Whoever maintains the Morning and Evening Azkar will be under the protection of Allah throughout the day.',
    'Remembrance (Dhikr) is the life of the heart; do not let your heart wither.',
  ];

  static String getRandomAdvice(String lang, {AdviceType type = AdviceType.general}) {
    // Use current date as seed so advice is consistent for the day
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed + type.index);
    
    final isAr = lang == 'ar';
    List<String> advices;

    switch (type) {
      case AdviceType.prayer:
        advices = isAr ? _prayerAdvicesAr : _prayerAdvicesEn;
        break;
      case AdviceType.azkar:
        advices = isAr ? _azkarAdvicesAr : _azkarAdvicesEn;
        break;
      case AdviceType.general:
      default:
        advices = isAr ? _generalAdvicesAr : _generalAdvicesEn;
    }

    return advices[random.nextInt(advices.length)];
  }
}

enum AdviceType { general, prayer, azkar }
