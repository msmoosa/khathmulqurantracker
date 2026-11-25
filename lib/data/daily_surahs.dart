import 'quran.dart';

/// How strong a hadith's chain is judged to be.
enum HadithStrength {
  /// Sahih or hasan: relied on.
  strong,

  /// Da'if or worse: shown so readers know it, but not relied on.
  weak,
}

/// A hadith about reciting a surah, with its grading.
class SurahVirtue {
  const SurahVirtue(
    this.meaning, {
    required this.narrator,
    required this.source,
    required this.grade,
    required this.strength,
  });

  /// Its meaning in English.
  final String meaning;
  final String narrator;

  /// Where it is collected. Hadith numbers follow sunnah.com.
  final String source;

  /// The grading and who gave it, e.g. 'Sahih (al-Albani)'.
  final String grade;
  final HadithStrength strength;
}

/// A surah (or verse) commonly read every day, offered as a shortcut above
/// the surah index.
class DailySurah {
  const DailySurah(this.label, this.start, this.virtues, {this.verse = false});

  final String label;

  /// Where to open the reader.
  final VerseRef start;

  /// Whether this is a single verse (Ayat al-Kursi) rather than a surah,
  /// so it has no surah mark of its own.
  final bool verse;
  final List<SurahVirtue> virtues;
}

const _sleepWithSajdahAndMulk = SurahVirtue(
  'The Prophet ﷺ would not sleep until he had recited Alif Lam Mim Tanzil '
  '(as-Sajdah) and Tabarak alladhi biyadihil-mulk (al-Mulk).',
  narrator: 'Jabir ibn Abdullah',
  source: "Jami' at-Tirmidhi 2892",
  grade: 'Sahih (al-Albani)',
  strength: HadithStrength.strong,
);

const dailySurahs = <DailySurah>[
  DailySurah('Al-Mulk', VerseRef(67, 1), [
    SurahVirtue(
      'There is a surah in the Quran of thirty verses which interceded for a '
      'man until he was forgiven. It is: Blessed is He in whose hand is the '
      'dominion (al-Mulk).',
      narrator: 'Abu Hurairah',
      source: "Jami' at-Tirmidhi 2891, Sunan Abi Dawud 1400",
      grade: 'Hasan (at-Tirmidhi)',
      strength: HadithStrength.strong,
    ),
    _sleepWithSajdahAndMulk,
  ]),
  DailySurah('Ya-Sin', VerseRef(36, 1), [
    SurahVirtue(
      'Everything has a heart, and the heart of the Quran is Ya-Sin. Whoever '
      'recites Ya-Sin, Allah records for him the reward of reciting the '
      'Quran ten times.',
      narrator: 'Anas ibn Malik',
      source: "Jami' at-Tirmidhi 2887",
      grade: "Weak (at-Tirmidhi called it gharib; al-Albani: fabricated)",
      strength: HadithStrength.weak,
    ),
    SurahVirtue(
      'Recite Ya-Sin over your dying.',
      narrator: "Ma'qil ibn Yasar",
      source: 'Sunan Abi Dawud 3121',
      grade: "Da'if (al-Albani)",
      strength: HadithStrength.weak,
    ),
    SurahVirtue(
      'Whoever reads a letter from the Book of Allah has a good deed for it, '
      'and a good deed is rewarded tenfold. (On reading any part of the '
      'Quran.)',
      narrator: "Abdullah ibn Mas'ud",
      source: "Jami' at-Tirmidhi 2910",
      grade: 'Sahih (at-Tirmidhi, al-Albani)',
      strength: HadithStrength.strong,
    ),
  ]),
  DailySurah('Al-Kahf', VerseRef(18, 1), [
    SurahVirtue(
      'Whoever memorises ten verses from the beginning of Surah al-Kahf will '
      'be protected from the Dajjal.',
      narrator: "Abu ad-Darda'",
      source: 'Sahih Muslim 809',
      grade: 'Sahih (Muslim)',
      strength: HadithStrength.strong,
    ),
    SurahVirtue(
      'Whoever recites Surah al-Kahf on Friday, a light will shine for him '
      'between the two Fridays.',
      narrator: "Abu Sa'id al-Khudri",
      source: 'al-Hakim, al-Mustadrak; al-Bayhaqi',
      grade: "Sahih (al-Albani, Sahih al-Jami' 6470)",
      strength: HadithStrength.strong,
    ),
  ]),
  DailySurah('Ayat al-Kursi', VerseRef(2, 255), verse: true, [
    SurahVirtue(
      'The Prophet ﷺ asked Ubayy which verse in the Book of Allah is the '
      'greatest. He said: "Allah, there is no god but He, the Ever-Living, '
      'the Sustainer." The Prophet ﷺ struck his chest and said: "May '
      'knowledge be pleasing to you, Abul-Mundhir."',
      narrator: "Ubayy ibn Ka'b",
      source: 'Sahih Muslim 810',
      grade: 'Sahih (Muslim)',
      strength: HadithStrength.strong,
    ),
    SurahVirtue(
      'When you go to your bed, recite Ayat al-Kursi, and a guardian from '
      'Allah will stay with you, and no devil will come near you until '
      'morning.',
      narrator: 'Abu Hurairah',
      source: 'Sahih al-Bukhari 5010',
      grade: 'Sahih (al-Bukhari)',
      strength: HadithStrength.strong,
    ),
    SurahVirtue(
      'Whoever recites Ayat al-Kursi after every obligatory prayer, nothing '
      'stands between him and entering Paradise except death.',
      narrator: 'Abu Umamah al-Bahili',
      source: "an-Nasa'i, as-Sunan al-Kubra 9848",
      grade: "Sahih (al-Albani, Sahih al-Jami' 6464)",
      strength: HadithStrength.strong,
    ),
  ]),
  DailySurah('Ar-Rahman', VerseRef(55, 1), [
    SurahVirtue(
      'The Prophet ﷺ recited Surah ar-Rahman to his companions and they were '
      'silent. He said: "I recited it to the jinn and they responded better '
      'than you. Whenever I reached \'Which of the favours of your Lord will '
      'you deny?\' they said: \'We deny none of Your favours, our Lord; to '
      'You belongs all praise.\'"',
      narrator: 'Jabir ibn Abdullah',
      source: "Jami' at-Tirmidhi 3291",
      grade: 'Hasan (al-Albani)',
      strength: HadithStrength.strong,
    ),
    SurahVirtue(
      'Everything has an adornment, and the adornment of the Quran is '
      'ar-Rahman.',
      narrator: 'Ali ibn Abi Talib',
      source: "al-Bayhaqi, Shu'ab al-Iman 2265",
      grade: 'Weak (al-Albani: munkar)',
      strength: HadithStrength.weak,
    ),
  ]),
  DailySurah('As-Sajdah', VerseRef(32, 1), [
    _sleepWithSajdahAndMulk,
    SurahVirtue(
      'On Fridays the Prophet ﷺ used to recite Alif Lam Mim Tanzil '
      '(as-Sajdah) and Hal ata \'alal-insan (al-Insan) in the Fajr prayer.',
      narrator: 'Abu Hurairah',
      source: 'Sahih al-Bukhari 891',
      grade: 'Sahih (al-Bukhari)',
      strength: HadithStrength.strong,
    ),
  ]),
];
