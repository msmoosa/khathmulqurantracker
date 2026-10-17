/// Static metadata for the 114 surahs of the Quran.
class Surah {
  const Surah(this.number, this.name, this.verseCount);

  final int number;
  final String name;
  final int verseCount;
}

const List<Surah> surahs = [
  Surah(1, 'Al-Fatihah', 7),
  Surah(2, 'Al-Baqarah', 286),
  Surah(3, 'Al-Imran', 200),
  Surah(4, 'An-Nisa', 176),
  Surah(5, "Al-Ma'idah", 120),
  Surah(6, "Al-An'am", 165),
  Surah(7, "Al-A'raf", 206),
  Surah(8, 'Al-Anfal', 75),
  Surah(9, 'At-Tawbah', 129),
  Surah(10, 'Yunus', 109),
  Surah(11, 'Hud', 123),
  Surah(12, 'Yusuf', 111),
  Surah(13, "Ar-Ra'd", 43),
  Surah(14, 'Ibrahim', 52),
  Surah(15, 'Al-Hijr', 99),
  Surah(16, 'An-Nahl', 128),
  Surah(17, 'Al-Isra', 111),
  Surah(18, 'Al-Kahf', 110),
  Surah(19, 'Maryam', 98),
  Surah(20, 'Ta-Ha', 135),
  Surah(21, 'Al-Anbiya', 112),
  Surah(22, 'Al-Hajj', 78),
  Surah(23, "Al-Mu'minun", 118),
  Surah(24, 'An-Nur', 64),
  Surah(25, 'Al-Furqan', 77),
  Surah(26, "Ash-Shu'ara", 227),
  Surah(27, 'An-Naml', 93),
  Surah(28, 'Al-Qasas', 88),
  Surah(29, 'Al-Ankabut', 69),
  Surah(30, 'Ar-Rum', 60),
  Surah(31, 'Luqman', 34),
  Surah(32, 'As-Sajdah', 30),
  Surah(33, 'Al-Ahzab', 73),
  Surah(34, 'Saba', 54),
  Surah(35, 'Fatir', 45),
  Surah(36, 'Ya-Sin', 83),
  Surah(37, 'As-Saffat', 182),
  Surah(38, 'Sad', 88),
  Surah(39, 'Az-Zumar', 75),
  Surah(40, 'Ghafir', 85),
  Surah(41, 'Fussilat', 54),
  Surah(42, 'Ash-Shura', 53),
  Surah(43, 'Az-Zukhruf', 89),
  Surah(44, 'Ad-Dukhan', 59),
  Surah(45, 'Al-Jathiyah', 37),
  Surah(46, 'Al-Ahqaf', 35),
  Surah(47, 'Muhammad', 38),
  Surah(48, 'Al-Fath', 29),
  Surah(49, 'Al-Hujurat', 18),
  Surah(50, 'Qaf', 45),
  Surah(51, 'Adh-Dhariyat', 60),
  Surah(52, 'At-Tur', 49),
  Surah(53, 'An-Najm', 62),
  Surah(54, 'Al-Qamar', 55),
  Surah(55, 'Ar-Rahman', 78),
  Surah(56, "Al-Waqi'ah", 96),
  Surah(57, 'Al-Hadid', 29),
  Surah(58, 'Al-Mujadilah', 22),
  Surah(59, 'Al-Hashr', 24),
  Surah(60, 'Al-Mumtahanah', 13),
  Surah(61, 'As-Saff', 14),
  Surah(62, "Al-Jumu'ah", 11),
  Surah(63, 'Al-Munafiqun', 11),
  Surah(64, 'At-Taghabun', 18),
  Surah(65, 'At-Talaq', 12),
  Surah(66, 'At-Tahrim', 12),
  Surah(67, 'Al-Mulk', 30),
  Surah(68, 'Al-Qalam', 52),
  Surah(69, 'Al-Haqqah', 52),
  Surah(70, "Al-Ma'arij", 44),
  Surah(71, 'Nuh', 28),
  Surah(72, 'Al-Jinn', 28),
  Surah(73, 'Al-Muzzammil', 20),
  Surah(74, 'Al-Muddaththir', 56),
  Surah(75, 'Al-Qiyamah', 40),
  Surah(76, 'Al-Insan', 31),
  Surah(77, 'Al-Mursalat', 50),
  Surah(78, 'An-Naba', 40),
  Surah(79, "An-Nazi'at", 46),
  Surah(80, 'Abasa', 42),
  Surah(81, 'At-Takwir', 29),
  Surah(82, 'Al-Infitar', 19),
  Surah(83, 'Al-Mutaffifin', 36),
  Surah(84, 'Al-Inshiqaq', 25),
  Surah(85, 'Al-Buruj', 22),
  Surah(86, 'At-Tariq', 17),
  Surah(87, "Al-A'la", 19),
  Surah(88, 'Al-Ghashiyah', 26),
  Surah(89, 'Al-Fajr', 30),
  Surah(90, 'Al-Balad', 20),
  Surah(91, 'Ash-Shams', 15),
  Surah(92, 'Al-Layl', 21),
  Surah(93, 'Ad-Duha', 11),
  Surah(94, 'Ash-Sharh', 8),
  Surah(95, 'At-Tin', 8),
  Surah(96, 'Al-Alaq', 19),
  Surah(97, 'Al-Qadr', 5),
  Surah(98, 'Al-Bayyinah', 8),
  Surah(99, 'Az-Zalzalah', 8),
  Surah(100, 'Al-Adiyat', 11),
  Surah(101, "Al-Qari'ah", 11),
  Surah(102, 'At-Takathur', 8),
  Surah(103, 'Al-Asr', 3),
  Surah(104, 'Al-Humazah', 9),
  Surah(105, 'Al-Fil', 5),
  Surah(106, 'Quraysh', 4),
  Surah(107, "Al-Ma'un", 7),
  Surah(108, 'Al-Kawthar', 3),
  Surah(109, 'Al-Kafirun', 6),
  Surah(110, 'An-Nasr', 3),
  Surah(111, 'Al-Masad', 5),
  Surah(112, 'Al-Ikhlas', 4),
  Surah(113, 'Al-Falaq', 5),
  Surah(114, 'An-Nas', 6),
];

/// Number of verses preceding each surah, indexed by surah number - 1.
final List<int> _versesBefore = () {
  final result = <int>[];
  var running = 0;
  for (final s in surahs) {
    result.add(running);
    running += s.verseCount;
  }
  return result;
}();

/// Total verses in the Quran (6236).
final int totalVerses =
    _versesBefore.last + surahs.last.verseCount;

/// Converts a (surah, verse) position into a 1-based index across the
/// whole Quran, so Al-Fatihah 1 is 1 and An-Nas 6 is [totalVerses].
int absoluteVerse(int surah, int verse) => _versesBefore[surah - 1] + verse;
