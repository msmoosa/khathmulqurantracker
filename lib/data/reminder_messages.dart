/// Sayings for the daily reminder: verses of the Quran and hadith that
/// encourage reciting it, with their sources.
const reminderSayings = [
  (
    '"Read the Quran, for it will come as an intercessor for its companions '
        'on the Day of Resurrection."',
    'Sahih Muslim 804',
  ),
  (
    '"The best of you are those who learn the Quran and teach it."',
    'Sahih al-Bukhari 5027',
  ),
  (
    '"Whoever reads a letter from the Book of Allah receives a good deed, '
        'and a good deed is multiplied by ten."',
    'Jami at-Tirmidhi 2910',
  ),
  ('"Verily, in the remembrance of Allah do hearts find rest."', 'Quran 13:28'),
  (
    '"The most beloved of deeds to Allah are those done regularly, even if '
        'they are small."',
    'Sahih al-Bukhari 6464',
  ),
  ('"Indeed, this Quran guides to that which is most upright."', 'Quran 17:9'),
  (
    '"The one who recites the Quran with difficulty, stammering over it, '
        'has a double reward."',
    'Sahih Muslim 798',
  ),
  (
    '"And We have certainly made the Quran easy to remember. So is there '
        'anyone who will be mindful?"',
    'Quran 54:17',
  ),
  (
    '"It will be said to the companion of the Quran: Recite and rise, as '
        'you used to recite in the world."',
    'Sunan Abi Dawud 1464',
  ),
  (
    '"We send down in the Quran that which is healing and mercy for the '
        'believers."',
    'Quran 17:82',
  ),
  (
    '"The believer who recites the Quran is like a citron: its fragrance is '
        'pleasant and its taste is pleasant."',
    'Sahih al-Bukhari 5020',
  ),
  (
    '"A blessed Book which We have revealed to you, that they may reflect '
        'upon its verses."',
    'Quran 38:29',
  ),
  ('"And recite the Quran with measured recitation."', 'Quran 73:4'),
];

const reminderTitles = [
  'Time for your daily recitation',
  'A few verses before the day ends?',
  'Your khathm is waiting',
  'Open the mushaf for a moment',
  'Keep your connection with the Quran',
];

/// The reminder for [day]: rotates through the titles and sayings so
/// consecutive days differ. [streak] is the reading streak to protect, if
/// known.
({String title, String body}) reminderFor(DateTime day, {int streak = 0}) {
  // Days since the epoch, counted on the calendar so DST doesn't matter.
  final n =
      DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final (saying, source) = reminderSayings[n % reminderSayings.length];
  final title = streak > 1
      ? 'Keep your $streak-day streak going'
      : reminderTitles[n % reminderTitles.length];
  return (title: title, body: '$saying ($source)');
}
