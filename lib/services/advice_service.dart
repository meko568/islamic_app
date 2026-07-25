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

  static const _encouragementAdvicesAr = [
    'لا تحزن على ما فاتك اليوم، استعن بالله واجعل هدفك إكماله غداً.',
    'كل يوم هو فرصة جديدة لبداية أفضل مع الله، لا تستسلم.',
    'المهم هو الاستمرار وعدم اليأس، حاول مرة أخرى غداً بكل عزم.',
    'تذكر أن الله يحب العبد الذي يحاول ويجتهد، غداً سيكون أفضل بإذن الله.',
    'اجعل تقصير اليوم دافعاً لك للتميز والنشاط في الغد.',
  ];

  static const _encouragementAdvicesEn = [
    'Do not grieve over what you missed today; seek help from Allah and aim to complete it tomorrow.',
    'Every day is a new opportunity for a better start with Allah; do not give up.',
    'The important thing is to continue and not despair; try again tomorrow with full determination.',
    'Remember that Allah loves the servant who tries and strives; tomorrow will be better, God willing.',
    'Let today\'s shortcoming be a motivation for you to excel and be active tomorrow.',
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
      case AdviceType.encouragement:
        advices = isAr ? _encouragementAdvicesAr : _encouragementAdvicesEn;
        break;
      case AdviceType.general:
      default:
        advices = isAr ? _generalAdvicesAr : _generalAdvicesEn;
    }

    return advices[random.nextInt(advices.length)];
  }

  static String getCustomEncouragement(String lang, String itemName) {
    final isAr = lang == 'ar';
    if (isAr) {
      return 'تذكر أن $itemName فرصة عظيمة للأجر، حاول ألا تفوتك غداً بإذن الله.';
    } else {
      return 'Remember that $itemName is a great opportunity for reward; try not to miss it tomorrow, God willing.';
    }
  }
}

enum AdviceType { general, prayer, azkar, encouragement }
