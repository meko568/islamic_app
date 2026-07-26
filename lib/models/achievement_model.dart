enum AchievementCategory { streak, prayer, azkar, tasbeeh, quran, targets, general }

class Achievement {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final AchievementCategory category;
  final int xpReward;
  final String icon; // Path to icon or icon name

  const Achievement({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.category,
    required this.xpReward,
    required this.icon,
  });

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String description(String lang) => lang == 'ar' ? descriptionAr : descriptionEn;

  static const List<Achievement> allAchievements = [
    // --- STREAKS ---
    Achievement(
      id: 'streak_3',
      titleAr: 'بداية الالتزام',
      titleEn: 'Commitment Start',
      descriptionAr: 'أكملت جميع المهام لـ ٣ أيام متتالية',
      descriptionEn: 'Completed all tasks for 3 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 50,
      icon: 'assets/badges/streak_3.png',
    ),
    Achievement(
      id: 'streak_7',
      titleAr: 'أسبوع من الإنجاز',
      titleEn: 'Week of Achievement',
      descriptionAr: 'أكملت جميع المهام لـ ٧ أيام متتالية',
      descriptionEn: 'Completed all tasks for 7 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 150,
      icon: 'assets/badges/streak_7.png',
    ),
    Achievement(
      id: 'streak_30',
      titleAr: 'شهر من النور',
      titleEn: 'Month of Light',
      descriptionAr: 'أكملت جميع المهام لـ ٣٠ يوم متتالية',
      descriptionEn: 'Completed all tasks for 30 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 1000,
      icon: 'assets/badges/streak_30.png',
    ),
    Achievement(
      id: 'streak_100',
      titleAr: 'مئة يوم من التقوى',
      titleEn: '100 Days of Piety',
      descriptionAr: 'أكملت جميع المهام لـ ١٠٠ يوم متتالية',
      descriptionEn: 'Completed all tasks for 100 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 5000,
      icon: 'assets/badges/streak_100.png',
    ),

    // --- PRAYERS ---
    Achievement(
      id: 'fajr_7',
      titleAr: 'فجر النشاط',
      titleEn: 'Active Fajr',
      descriptionAr: 'أديت صلاة الفجر لـ ٧ أيام متتالية',
      descriptionEn: 'Performed Fajr prayer for 7 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 100,
      icon: 'assets/badges/fajr_7.png',
    ),
    Achievement(
      id: 'prayer_consistent_10',
      titleAr: 'مصلٍ مواظب',
      titleEn: 'Consistent Prayer',
      descriptionAr: 'أكملت جميع الصلوات لـ ١٠ أيام',
      descriptionEn: 'Completed all prayers for 10 days',
      category: AchievementCategory.prayer,
      xpReward: 300,
      icon: 'assets/badges/prayer_10.png',
    ),
    Achievement(
      id: 'prayer_consistent_50',
      titleAr: 'حارس الصلوات',
      titleEn: 'Prayer Guardian',
      descriptionAr: 'أكملت جميع الصلوات لـ ٥٠ يوم',
      descriptionEn: 'Completed all prayers for 50 days',
      category: AchievementCategory.prayer,
      xpReward: 2000,
      icon: 'assets/badges/prayer_50.png',
    ),

    // --- TASBEEH ---
    Achievement(
      id: 'tasbeeh_1000',
      titleAr: 'ألف تسبيحة',
      titleEn: '1,000 Tasbeeh',
      descriptionAr: 'أكملت ١٠٠٠ تسبيحة في المجموع',
      descriptionEn: 'Completed 1,000 tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 100,
      icon: 'assets/badges/tasbeeh_1000.png',
    ),
    Achievement(
      id: 'tasbeeh_10000',
      titleAr: 'عشرة آلاف تسبيحة',
      titleEn: '10,000 Tasbeeh',
      descriptionAr: 'أكملت ١٠٠٠٠ تسبيحة في المجموع',
      descriptionEn: 'Completed 10,000 tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 1000,
      icon: 'assets/badges/tasbeeh_10000.png',
    ),
    Achievement(
      id: 'tasbeeh_100000',
      titleAr: 'مئة ألف تسبيحة',
      titleEn: '100,000 Tasbeeh',
      descriptionAr: 'أكملت ١٠٠٠٠٠ تسبيحة في المجموع',
      descriptionEn: 'Completed 100,000 tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 10000,
      icon: 'assets/badges/tasbeeh_100000.png',
    ),

    // --- AZKAR ---
    Achievement(
      id: 'azkar_daily_7',
      titleAr: 'ذاكر أسبوعي',
      titleEn: 'Weekly Rememberer',
      descriptionAr: 'أكملت أذكار الصباح والمساء لـ ٧ أيام متتالية',
      descriptionEn: 'Completed Morning and Evening Azkar for 7 consecutive days',
      category: AchievementCategory.azkar,
      xpReward: 200,
      icon: 'assets/badges/azkar_7.png',
    ),
    Achievement(
      id: 'azkar_daily_30',
      titleAr: 'مطمئن القلب',
      titleEn: 'Peaceful Heart',
      descriptionAr: 'أكملت أذكار الصباح والمساء لـ ٣٠ يوم متتالية',
      descriptionEn: 'Completed Morning and Evening Azkar for 30 consecutive days',
      category: AchievementCategory.azkar,
      xpReward: 1500,
      icon: 'assets/badges/azkar_30.png',
    ),

    // --- QURAN ---
    Achievement(
      id: 'quran_7',
      titleAr: 'قارئ الأسبوع',
      titleEn: 'Reader of the Week',
      descriptionAr: 'قرأت وردك القرآني لـ ٧ أيام متتالية',
      descriptionEn: 'Read your Quran portion for 7 consecutive days',
      category: AchievementCategory.quran,
      xpReward: 200,
      icon: 'assets/badges/quran_7.png',
    ),
    Achievement(
      id: 'quran_30',
      titleAr: 'صاحب القرآن',
      titleEn: 'Companion of Quran',
      descriptionAr: 'قرأت وردك القرآني لـ ٣٠ يوم متتالية',
      descriptionEn: 'Read your Quran portion for 30 consecutive days',
      category: AchievementCategory.quran,
      xpReward: 1500,
      icon: 'assets/badges/quran_30.png',
    ),

    // --- TARGETS ---
    Achievement(
      id: 'targets_1',
      titleAr: 'أول الغيث',
      titleEn: 'First Goal',
      descriptionAr: 'أنجزت أول أهدافك الإسلامية',
      descriptionEn: 'Completed your first Islamic target',
      category: AchievementCategory.targets,
      xpReward: 100,
      icon: 'assets/badges/target_1.png',
    ),
    Achievement(
      id: 'targets_5',
      titleAr: 'خماسية الإنجاز',
      titleEn: 'Five Goals',
      descriptionAr: 'أنجزت ٥ أهداف إسلامية',
      descriptionEn: 'Completed 5 Islamic targets',
      category: AchievementCategory.targets,
      xpReward: 500,
      icon: 'assets/badges/target_5.png',
    ),
    Achievement(
      id: 'targets_10',
      titleAr: 'مُحقق الأهداف',
      titleEn: 'Goal Achiever',
      descriptionAr: 'أنجزت ١٠ أهداف إسلامية',
      descriptionEn: 'Completed 10 Islamic targets',
      category: AchievementCategory.targets,
      xpReward: 1000,
      icon: 'assets/badges/target_10.png',
    ),
    Achievement(
      id: 'targets_25',
      titleAr: 'عزيمة لا تلين',
      titleEn: 'Unwavering Resolve',
      descriptionAr: 'أنجزت ٢٥ هدفاً إسلامياً',
      descriptionEn: 'Completed 25 Islamic targets',
      category: AchievementCategory.targets,
      xpReward: 3000,
      icon: 'assets/badges/target_25.png',
    ),
    Achievement(
      id: 'targets_50',
      titleAr: 'سيد الأهداف',
      titleEn: 'Master of Goals',
      descriptionAr: 'أنجزت ٥٠ هدفاً إسلامياً',
      descriptionEn: 'Completed 50 Islamic targets',
      category: AchievementCategory.targets,
      xpReward: 7000,
      icon: 'assets/badges/target_50.png',
    ),
    
    // --- Add more to reach 50 ---
    Achievement(
      id: 'streak_15',
      titleAr: 'نصف شهر من الالتزام',
      titleEn: 'Half Month Commitment',
      descriptionAr: 'أكملت جميع المهام لـ ١٥ يوم متتالية',
      descriptionEn: 'Completed all tasks for 15 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 500,
      icon: 'assets/badges/streak_15.png',
    ),
    Achievement(
      id: 'streak_60',
      titleAr: 'شهران من الهدى',
      titleEn: 'Two Months of Guidance',
      descriptionAr: 'أكملت جميع المهام لـ ٦٠ يوم متتالية',
      descriptionEn: 'Completed all tasks for 60 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 2500,
      icon: 'assets/badges/streak_60.png',
    ),
    Achievement(
      id: 'fajr_30',
      titleAr: 'فجر الثبات',
      titleEn: 'Steadfast Fajr',
      descriptionAr: 'أديت صلاة الفجر لـ ٣٠ يوم متتالية',
      descriptionEn: 'Performed Fajr prayer for 30 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 800,
      icon: 'assets/badges/fajr_30.png',
    ),
    Achievement(
      id: 'fajr_100',
      titleAr: 'بطل الفجر',
      titleEn: 'Fajr Hero',
      descriptionAr: 'أديت صلاة الفجر لـ ١٠٠ يوم متتالية',
      descriptionEn: 'Performed Fajr prayer for 100 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 4000,
      icon: 'assets/badges/fajr_100.png',
    ),
    Achievement(
      id: 'isha_7',
      titleAr: 'ختامها مسك',
      titleEn: 'Good Ending',
      descriptionAr: 'أديت صلاة العشاء لـ ٧ أيام متتالية',
      descriptionEn: 'Performed Isha prayer for 7 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 100,
      icon: 'assets/badges/isha_7.png',
    ),
    Achievement(
      id: 'tasbeeh_50000',
      titleAr: 'نصف مئة ألف',
      titleEn: '50,000 Tasbeeh',
      descriptionAr: 'أكملت ٥٠٠٠٠ تسبيحة في المجموع',
      descriptionEn: 'Completed 50,000 tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 4000,
      icon: 'assets/badges/tasbeeh_50000.png',
    ),
    Achievement(
      id: 'tasbeeh_500000',
      titleAr: 'نصف مليون تسبيحة',
      titleEn: 'Half Million Tasbeeh',
      descriptionAr: 'أكملت ٥٠٠٠٠٠ تسبيحة في المجموع',
      descriptionEn: 'Completed 500,000 tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 25000,
      icon: 'assets/badges/tasbeeh_500000.png',
    ),
    Achievement(
      id: 'tasbeeh_1000000',
      titleAr: 'مليون تسبيحة',
      titleEn: 'One Million Tasbeeh',
      descriptionAr: 'أكملت مليون تسبيحة في المجموع',
      descriptionEn: 'Completed one million tasbeeh in total',
      category: AchievementCategory.tasbeeh,
      xpReward: 100000,
      icon: 'assets/badges/tasbeeh_1000000.png',
    ),
    Achievement(
      id: 'consistent_100_tasks',
      titleAr: 'مئة عمل صالح',
      titleEn: '100 Good Deeds',
      descriptionAr: 'أكملت ١٠٠ مهمة إجمالاً',
      descriptionEn: 'Completed 100 total tasks',
      category: AchievementCategory.general,
      xpReward: 500,
      icon: 'assets/badges/deeds_100.png',
    ),
    Achievement(
      id: 'consistent_1000_tasks',
      titleAr: 'ألف عمل صالح',
      titleEn: '1,000 Good Deeds',
      descriptionAr: 'أكملت ١٠٠٠ مهمة إجمالاً',
      descriptionEn: 'Completed 1,000 total tasks',
      category: AchievementCategory.general,
      xpReward: 6000,
      icon: 'assets/badges/deeds_1000.png',
    ),
    Achievement(
      id: 'early_bird_7',
      titleAr: 'بكور البركة',
      titleEn: 'Blessed Morning',
      descriptionAr: 'أكملت الفجر وأذكار الصباح لـ ٧ أيام متتالية',
      descriptionEn: 'Completed Fajr and Morning Azkar for 7 consecutive days',
      category: AchievementCategory.general,
      xpReward: 300,
      icon: 'assets/badges/early_bird_7.png',
    ),
    Achievement(
      id: 'friday_master',
      titleAr: 'سيد الجمعة',
      titleEn: 'Friday Master',
      descriptionAr: 'أكملت جميع المهام في يوم جمعة',
      descriptionEn: 'Completed all tasks on a Friday',
      category: AchievementCategory.general,
      xpReward: 200,
      icon: 'assets/badges/friday.png',
    ),
    Achievement(
      id: 'custom_tasks_5',
      titleAr: 'مُنظم خاص',
      titleEn: 'Custom Organizer',
      descriptionAr: 'أضفت ٥ مهام مخصصة',
      descriptionEn: 'Added 5 custom tasks',
      category: AchievementCategory.general,
      xpReward: 150,
      icon: 'assets/badges/custom_5.png',
    ),
    Achievement(
      id: 'streak_2',
      titleAr: 'اليوم الثاني',
      titleEn: 'Day Two',
      descriptionAr: 'أكملت يومين متتاليين',
      descriptionEn: 'Completed two consecutive days',
      category: AchievementCategory.streak,
      xpReward: 20,
      icon: 'assets/badges/streak_2.png',
    ),
    Achievement(
      id: 'streak_5',
      titleAr: 'خماسية الإنجاز',
      titleEn: 'Five Day Streak',
      descriptionAr: 'أكملت ٥ أيام متتالية',
      descriptionEn: 'Completed 5 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 100,
      icon: 'assets/badges/streak_5.png',
    ),
    Achievement(
      id: 'streak_14',
      titleAr: 'أسبوعان من الثبات',
      titleEn: 'Two Weeks Steadfast',
      descriptionAr: 'أكملت ١٤ يوماً متتالياً',
      descriptionEn: 'Completed 14 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 400,
      icon: 'assets/badges/streak_14.png',
    ),
    Achievement(
      id: 'streak_21',
      titleAr: 'ثلاثة أسابيع',
      titleEn: 'Three Weeks',
      descriptionAr: 'أكملت ٢١ يوماً متتالياً',
      descriptionEn: 'Completed 21 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 600,
      icon: 'assets/badges/streak_21.png',
    ),
    Achievement(
      id: 'streak_40',
      titleAr: 'أربعون يوماً',
      titleEn: 'Forty Days',
      descriptionAr: 'أكملت ٤٠ يوماً متتالياً',
      descriptionEn: 'Completed 40 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 1500,
      icon: 'assets/badges/streak_40.png',
    ),
    Achievement(
      id: 'streak_50',
      titleAr: 'اليوبيل الذهبي',
      titleEn: 'Golden Jubilee',
      descriptionAr: 'أكملت ٥٠ يوماً متتالياً',
      descriptionEn: 'Completed 50 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 2000,
      icon: 'assets/badges/streak_50.png',
    ),
    Achievement(
      id: 'streak_75',
      titleAr: 'ثلاثة أرباع المئة',
      titleEn: 'Three Quarters to 100',
      descriptionAr: 'أكملت ٧٥ يوماً متتالياً',
      descriptionEn: 'Completed 75 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 3500,
      icon: 'assets/badges/streak_75.png',
    ),
    Achievement(
      id: 'streak_150',
      titleAr: 'نصف سنة تقريباً',
      titleEn: 'Half a Year Almost',
      descriptionAr: 'أكملت ١٥٠ يوماً متتالياً',
      descriptionEn: 'Completed 150 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 8000,
      icon: 'assets/badges/streak_150.png',
    ),
    Achievement(
      id: 'streak_200',
      titleAr: 'مئتا يوم',
      titleEn: 'Two Hundred Days',
      descriptionAr: 'أكملت ٢٠٠ يوم متتالي',
      descriptionEn: 'Completed 200 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 12000,
      icon: 'assets/badges/streak_200.png',
    ),
    Achievement(
      id: 'streak_365',
      titleAr: 'سنة كاملة',
      titleEn: 'One Full Year',
      descriptionAr: 'أكملت ٣٦٥ يوماً متتالياً',
      descriptionEn: 'Completed 365 consecutive days',
      category: AchievementCategory.streak,
      xpReward: 50000,
      icon: 'assets/badges/streak_365.png',
    ),
    Achievement(
      id: 'fajr_1',
      titleAr: 'فجر أول',
      titleEn: 'First Fajr',
      descriptionAr: 'أديت صلاة الفجر لأول مرة في التطبيق',
      descriptionEn: 'Performed Fajr for the first time in the app',
      category: AchievementCategory.prayer,
      xpReward: 10,
      icon: 'assets/badges/fajr_1.png',
    ),
    Achievement(
      id: 'fajr_3',
      titleAr: 'ثلاثية الفجر',
      titleEn: 'Fajr Trio',
      descriptionAr: 'أديت صلاة الفجر لـ ٣ أيام متتالية',
      descriptionEn: 'Performed Fajr for 3 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 40,
      icon: 'assets/badges/fajr_3.png',
    ),
    Achievement(
      id: 'fajr_14',
      titleAr: 'أسبوعا الفجر',
      titleEn: 'Two Weeks of Fajr',
      descriptionAr: 'أديت صلاة الفجر لـ ١٤ يوماً متتالياً',
      descriptionEn: 'Performed Fajr for 14 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 250,
      icon: 'assets/badges/fajr_14.png',
    ),
    Achievement(
      id: 'dhuhr_7',
      titleAr: 'ظهر مستمر',
      titleEn: 'Continuous Dhuhr',
      descriptionAr: 'أديت صلاة الظهر لـ ٧ أيام متتالية',
      descriptionEn: 'Performed Dhuhr for 7 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 100,
      icon: 'assets/badges/dhuhr_7.png',
    ),
    Achievement(
      id: 'asr_7',
      titleAr: 'عصر الالتزام',
      titleEn: 'Asr Commitment',
      descriptionAr: 'أديت صلاة العصر لـ ٧ أيام متتالية',
      descriptionEn: 'Performed Asr for 7 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 100,
      icon: 'assets/badges/asr_7.png',
    ),
    Achievement(
      id: 'maghrib_7',
      titleAr: 'مغرب المداومة',
      titleEn: 'Maghrib Persistence',
      descriptionAr: 'أديت صلاة المغرب لـ ٧ أيام متتالية',
      descriptionEn: 'Performed Maghrib for 7 consecutive days',
      category: AchievementCategory.prayer,
      xpReward: 100,
      icon: 'assets/badges/maghrib_7.png',
    ),
    Achievement(
      id: 'prayer_all_1',
      titleAr: 'يوم كامل',
      titleEn: 'Full Day',
      descriptionAr: 'أكملت جميع الصلوات في يوم واحد',
      descriptionEn: 'Completed all prayers in one day',
      category: AchievementCategory.prayer,
      xpReward: 50,
      icon: 'assets/badges/prayer_all_1.png',
    ),
    Achievement(
      id: 'azkar_1',
      titleAr: 'بداية الذكر',
      titleEn: 'First Azkar',
      descriptionAr: 'أكملت ورد الأذكار لأول مرة',
      descriptionEn: 'Completed your first Azkar portion',
      category: AchievementCategory.azkar,
      xpReward: 20,
      icon: 'assets/badges/azkar_1.png',
    ),
    Achievement(
      id: 'azkar_3',
      titleAr: 'ثلاثية الأذكار',
      titleEn: 'Azkar Trio',
      descriptionAr: 'أكملت أذكار الصباح والمساء لـ ٣ أيام متتالية',
      descriptionEn: 'Completed Morning and Evening Azkar for 3 consecutive days',
      category: AchievementCategory.azkar,
      xpReward: 70,
      icon: 'assets/badges/azkar_3.png',
    ),
    Achievement(
      id: 'azkar_14',
      titleAr: 'أسبوعا الذكر',
      titleEn: 'Two Weeks of Remembrance',
      descriptionAr: 'أكملت أذكار الصباح والمساء لـ ١٤ يوماً متتالياً',
      descriptionEn: 'Completed Morning and Evening Azkar for 14 consecutive days',
      category: AchievementCategory.azkar,
      xpReward: 500,
      icon: 'assets/badges/azkar_14.png',
    ),
    Achievement(
      id: 'tasbeeh_100',
      titleAr: 'مئة تسبيحة',
      titleEn: '100 Tasbeeh',
      descriptionAr: 'أكملت ١٠٠ تسبيحة',
      descriptionEn: 'Completed 100 tasbeeh',
      category: AchievementCategory.tasbeeh,
      xpReward: 10,
      icon: 'assets/badges/tasbeeh_100.png',
    ),
    Achievement(
      id: 'tasbeeh_500',
      titleAr: 'خمسمئة تسبيحة',
      titleEn: '500 Tasbeeh',
      descriptionAr: 'أكملت ٥٠٠ تسبيحة',
      descriptionEn: 'Completed 500 tasbeeh',
      category: AchievementCategory.tasbeeh,
      xpReward: 40,
      icon: 'assets/badges/tasbeeh_500.png',
    ),
    Achievement(
      id: 'tasbeeh_5000',
      titleAr: 'خمسة آلاف تسبيحة',
      titleEn: '5,000 Tasbeeh',
      descriptionAr: 'أكملت ٥٠٠٠ تسبيحة',
      descriptionEn: 'Completed 5,000 tasbeeh',
      category: AchievementCategory.tasbeeh,
      xpReward: 400,
      icon: 'assets/badges/tasbeeh_5000.png',
    ),
    Achievement(
      id: 'tasbeeh_25000',
      titleAr: 'خمس وعشرون ألفاً',
      titleEn: '25,000 Tasbeeh',
      descriptionAr: 'أكملت ٢٥٠٠٠ تسبيحة',
      descriptionEn: 'Completed 25,000 tasbeeh',
      category: AchievementCategory.tasbeeh,
      xpReward: 2000,
      icon: 'assets/badges/tasbeeh_25000.png',
    ),
    Achievement(
      id: 'quran_1',
      titleAr: 'بداية التلاوة',
      titleEn: 'First Reading',
      descriptionAr: 'قرأت ورد القرآن لأول مرة',
      descriptionEn: 'Read your first Quran portion',
      category: AchievementCategory.quran,
      xpReward: 20,
      icon: 'assets/badges/quran_1.png',
    ),
    Achievement(
      id: 'quran_3',
      titleAr: 'ثلاثية القرآن',
      titleEn: 'Quran Trio',
      descriptionAr: 'قرأت وردك القرآني لـ ٣ أيام متتالية',
      descriptionEn: 'Read your Quran portion for 3 consecutive days',
      category: AchievementCategory.quran,
      xpReward: 70,
      icon: 'assets/badges/quran_3.png',
    ),
    Achievement(
      id: 'quran_14',
      titleAr: 'أسبوعا التلاوة',
      titleEn: 'Two Weeks of Quran',
      descriptionAr: 'قرأت وردك القرآني لـ ١٤ يوماً متتالياً',
      descriptionEn: 'Read your Quran portion for 14 consecutive days',
      category: AchievementCategory.quran,
      xpReward: 500,
      icon: 'assets/badges/quran_14.png',
    ),
    Achievement(
      id: 'consistent_10_tasks',
      titleAr: 'عشر خطوات',
      titleEn: 'Ten Steps',
      descriptionAr: 'أكملت ١٠ مهام إجمالاً',
      descriptionEn: 'Completed 10 total tasks',
      category: AchievementCategory.general,
      xpReward: 30,
      icon: 'assets/badges/deeds_10.png',
    ),
    Achievement(
      id: 'consistent_50_tasks',
      titleAr: 'خمسون عملاً',
      titleEn: 'Fifty Deeds',
      descriptionAr: 'أكملت ٥٠ مهمة إجمالاً',
      descriptionEn: 'Completed 50 total tasks',
      category: AchievementCategory.general,
      xpReward: 200,
      icon: 'assets/badges/deeds_50.png',
    ),
    Achievement(
      id: 'consistent_500_tasks',
      titleAr: 'نصف ألف عمل',
      titleEn: '500 Deeds',
      descriptionAr: 'أكملت ٥٠٠ مهمة إجمالاً',
      descriptionEn: 'Completed 500 total tasks',
      category: AchievementCategory.general,
      xpReward: 2500,
      icon: 'assets/badges/deeds_500.png',
    ),
    Achievement(
      id: 'custom_tasks_1',
      titleAr: 'منظم ناشئ',
      titleEn: 'Rising Organizer',
      descriptionAr: 'أضفت أول مهمة مخصصة',
      descriptionEn: 'Added your first custom task',
      category: AchievementCategory.general,
      xpReward: 20,
      icon: 'assets/badges/custom_1.png',
    ),
  ];
}

class UserStats {
  final int totalXp;
  final List<String> unlockedAchievementIds;
  final DateTime? lastSync;

  UserStats({
    this.totalXp = 0,
    List<String>? unlockedAchievementIds,
    this.lastSync,
  }) : unlockedAchievementIds = unlockedAchievementIds ?? [];

  int get level {
    // Basic level formula: level = sqrt(xp / 100)
    if (totalXp <= 0) return 1;
    return (0.1 * (totalXp / 10).clamp(0, double.infinity)).truncate() + 1;
    // Let's use something simpler: level 1 is 0-500 XP, level 2 is 500-1500 XP, etc.
    // Let's use a linear-progressive level:
    // Level 1: 0
    // Level 2: 500
    // Level 3: 1500
    // Level 4: 3000
    // xpForLevel(L) = 250 * L * (L - 1)
  }
  
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return 250 * level * (level - 1);
  }
  
  int get currentLevel => calculateLevel(totalXp);
  
  static int calculateLevel(int xp) {
    int level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  double get levelProgress {
    int currentLevelXp = xpForLevel(currentLevel);
    int nextLevelXp = xpForLevel(currentLevel + 1);
    int progressXp = totalXp - currentLevelXp;
    int neededXp = nextLevelXp - currentLevelXp;
    return (progressXp / neededXp).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'unlockedAchievementIds': unlockedAchievementIds,
    'lastSync': lastSync?.toIso8601String(),
  };

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    totalXp: j['totalXp'] as int? ?? 0,
    unlockedAchievementIds: List<String>.from(j['unlockedAchievementIds'] as Iterable? ?? []),
    lastSync: j['lastSync'] != null ? DateTime.parse(j['lastSync'] as String) : null,
  );
}
