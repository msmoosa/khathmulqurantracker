import 'quran.dart';

/// A verse or hadith that encourages reading the Quran.
class Inspiration {
  const Inspiration.verse(this.verse, this.meaning)
    : narrator = null,
      source = null;

  const Inspiration.hadith(
    this.meaning, {
    required this.narrator,
    required this.source,
  }) : verse = null;

  /// The verse, shown in Arabic from the bundled text; null for a hadith.
  final VerseRef? verse;

  /// Its meaning in English.
  final String meaning;

  /// Who narrated a hadith, e.g. 'Aishah'.
  final String? narrator;

  /// Where a hadith is collected, e.g. 'Sahih al-Bukhari 5027'.
  final String? source;
}

/// Hadith numbers follow sunnah.com.
const inspirations = <Inspiration>[
  Inspiration.verse(
    VerseRef(96, 1),
    'Read in the name of your Lord who created.',
  ),
  Inspiration.verse(
    VerseRef(54, 17),
    'We have made the Quran easy to remember. So is there anyone who will '
    'take heed?',
  ),
  Inspiration.verse(
    VerseRef(38, 29),
    'A blessed Book that We have sent down to you, so that they reflect on '
    'its verses, and so that people of understanding take it to heart.',
  ),
  Inspiration.verse(
    VerseRef(17, 9),
    'This Quran guides to the way that is most upright, and gives the '
    'believers who do good the glad news that theirs is a great reward.',
  ),
  Inspiration.verse(
    VerseRef(10, 57),
    'O people, there has come to you counsel from your Lord, a healing for '
    'what is in the hearts, and guidance and mercy for the believers.',
  ),
  Inspiration.verse(
    VerseRef(17, 82),
    'We send down in the Quran what is healing and mercy for the believers.',
  ),
  Inspiration.verse(
    VerseRef(13, 28),
    'Those who believe and whose hearts find rest in the remembrance of '
    'Allah. Truly, in the remembrance of Allah hearts find rest.',
  ),
  Inspiration.verse(
    VerseRef(73, 4),
    'Or a little more; and recite the Quran in a measured, unhurried way.',
  ),
  Inspiration.verse(
    VerseRef(47, 24),
    'Do they not reflect on the Quran, or are there locks upon their '
    'hearts?',
  ),
  Inspiration.verse(
    VerseRef(35, 29),
    'Those who recite the Book of Allah, keep up the prayer, and give from '
    'what We have provided them, in secret and openly, hope for a trade '
    'that will never fail.',
  ),
  Inspiration.verse(
    VerseRef(2, 121),
    'Those to whom We have given the Book recite it as it should be '
    'recited. It is they who believe in it.',
  ),
  Inspiration.verse(
    VerseRef(59, 21),
    'Had We sent this Quran down upon a mountain, you would have seen it '
    'humbled, splitting apart in awe of Allah. Such are the examples We '
    'set out for people, so that they may reflect.',
  ),
  Inspiration.hadith(
    'The best of you are those who learn the Quran and teach it.',
    narrator: 'Uthman ibn Affan',
    source: 'Sahih al-Bukhari 5027',
  ),
  Inspiration.hadith(
    'Read the Quran, for on the Day of Resurrection it will come as an '
    'intercessor for its companions.',
    narrator: 'Abu Umamah al-Bahili',
    source: 'Sahih Muslim 804',
  ),
  Inspiration.hadith(
    'Whoever reads a letter from the Book of Allah has a good deed for it, '
    'and a good deed is rewarded tenfold. I do not say that Alif Lam Mim '
    'is a letter; rather Alif is a letter, Lam is a letter and Mim is a '
    'letter.',
    narrator: "Abdullah ibn Mas'ud",
    source: "Jami' at-Tirmidhi 2910",
  ),
  Inspiration.hadith(
    'The one who is skilled in the Quran is with the noble and righteous '
    'scribes, and the one who reads the Quran and stumbles over it, '
    'finding it hard, has two rewards.',
    narrator: 'Aishah',
    source: 'Sahih al-Bukhari 4937, Sahih Muslim 798',
  ),
  Inspiration.hadith(
    'It will be said to the companion of the Quran: Read, rise, and recite '
    'as you used to recite in the world, for your place will be at the '
    'last verse you recite.',
    narrator: 'Abdullah ibn Amr',
    source: "Sunan Abi Dawud 1464, Jami' at-Tirmidhi 2914",
  ),
  Inspiration.hadith(
    'No people gather in one of the houses of Allah, reciting the Book of '
    'Allah and studying it together, except that tranquillity descends '
    'upon them, mercy covers them, the angels surround them, and Allah '
    'mentions them to those with Him.',
    narrator: 'Abu Hurairah',
    source: 'Sahih Muslim 2699',
  ),
  Inspiration.hadith(
    'The believer who recites the Quran is like a citron: its fragrance is '
    'pleasant and its taste is pleasant.',
    narrator: "Abu Musa al-Ash'ari",
    source: 'Sahih al-Bukhari 5020, Sahih Muslim 797',
  ),
  Inspiration.hadith(
    'The deeds most beloved to Allah are those done consistently, even if '
    'they are small.',
    narrator: 'Aishah',
    source: 'Sahih al-Bukhari 6464, Sahih Muslim 783',
  ),
  Inspiration.hadith(
    'Do not make your houses into graves. Satan flees from the house in '
    'which Surah al-Baqarah is recited.',
    narrator: 'Abu Hurairah',
    source: 'Sahih Muslim 780',
  ),
  Inspiration.hadith(
    'Read the whole Quran in a month.',
    narrator: 'Abdullah ibn Amr',
    source: 'Sahih al-Bukhari 5054',
  ),
];
