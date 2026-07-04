class Surah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String nameEnglishTranslation;
  final int ayahCount;
  final String revelationType;
  final List<Ayah>? ayahs;

  Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameEnglishTranslation,
    required this.ayahCount,
    required this.revelationType,
    this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int? ?? 0,
      nameArabic: json['name'] as String? ?? '',
      nameEnglish: json['englishName'] as String? ?? '',
      nameEnglishTranslation: json['englishNameTranslation'] as String? ?? '',
      ayahCount: json['numberOfAyahs'] as int? ?? 0,
      revelationType: json['revelationType'] as String? ?? '',
      ayahs:
          json['ayahs'] != null
              ? (json['ayahs'] as List)
                  .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': nameArabic,
      'englishName': nameEnglish,
      'englishNameTranslation': nameEnglishTranslation,
      'numberOfAyahs': ayahCount,
      'revelationType': revelationType,
      'ayahs': ayahs?.map((e) => e.toJson()).toList(),
    };
  }
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  String? audioUrl;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    this.audioUrl,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      juz: json['juz'] as int? ?? 1,
      manzil: json['manzil'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      ruku: json['ruku'] as int? ?? 1,
      hizbQuarter: json['hizbQuarter'] as int? ?? 1,
      sajda:
          json['sajda'] is bool
              ? json['sajda'] as bool
              : (json['sajda'] is Map && json['sajda'] != null ? true : false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
      'audioUrl': audioUrl,
    };
  }
}
