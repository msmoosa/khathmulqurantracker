import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/quran.dart';

/// Fonts of the classic Madani mushaf (QPC V1, 1405 AH print) by the King
/// Fahd Glorious Quran Printing Complex. Each of the 604 pages has its own
/// font, about 110 KB, so they are downloaded as pages are read and kept
/// on the device for offline reading, rather than bundled with the app.
class MushafFonts extends ChangeNotifier {
  MushafFonts({this.enabled = true});

  /// Shared instance. Tests replace it with a disabled one, which makes
  /// the reader use its fallback script without touching the network.
  static MushafFonts instance = MushafFonts();

  /// When false, nothing is downloaded and every page uses the fallback.
  final bool enabled;

  static const _base = 'https://static-cdn.tarteel.ai/qul/fonts';
  static String _pageUrl(int page) =>
      '$_base/quran_fonts/v1-optimized/ttf/p$page.ttf';

  /// Font family registered for [page].
  static String pageFamily(int page) => 'QPC_V1_P$page';

  /// Bundled font holding the Bismillah as a single glyph (U+FDFD).
  static const bismillahFamily = 'QPCBismillah';

  /// Bundled font that draws "سورة" and the surah name from the text
  /// `surahNNN`.
  static const surahNameFamily = 'QPCSurahNames';

  final _loaded = <String>{};
  final _loading = <String, Future<bool>>{};

  bool isPageReady(int page) => _loaded.contains(pageFamily(page));

  /// Makes the font for [page] available, downloading it if needed.
  /// Completes with false if it could not be loaded (e.g. offline).
  Future<bool> ensurePage(int page) =>
      _ensure(pageFamily(page), 'p$page.ttf', _pageUrl(page));

  Future<bool> _ensure(String family, String file, String url) {
    if (!enabled) return SynchronousFuture(false);
    if (_loaded.contains(family)) return SynchronousFuture(true);
    return _loading[family] ??= () async {
      try {
        final bytes = await _bytes(file, url);
        final loader = FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        _loaded.add(family);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Could not load $family: $e');
        return false;
      } finally {
        // Allow a retry later if this attempt failed.
        unawaited(Future.microtask(() => _loading.remove(family)));
      }
    }();
  }

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final support = await getApplicationSupportDirectory();
    return _dir = await Directory(
      '${support.path}/mushaf_qpc_v1',
    ).create(recursive: true);
  }

  Future<Uint8List> _download(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    return response.bodyBytes;
  }

  /// Reads a font from the device, downloading and saving it first if it
  /// is not there yet. On the web the browser's cache plays that role.
  Future<Uint8List> _bytes(String file, String url) async {
    if (kIsWeb) return _download(url);
    final f = File('${(await _cacheDir()).path}/$file');
    if (await f.exists()) return f.readAsBytes();
    final bytes = await _download(url);
    // Write to a temporary name first so a partial file is never used.
    final tmp = File('${f.path}.part');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(f.path);
    return bytes;
  }

  /// Whether pages can be saved for offline reading on this platform.
  static bool get canSaveOffline => !kIsWeb;

  /// Number of page fonts saved on the device.
  Future<int> savedPageCount() async {
    if (!enabled || !canSaveOffline) return 0;
    try {
      final dir = await _cacheDir();
      return dir
          .listSync()
          .where((e) => RegExp(r'/p\d+\.ttf$').hasMatch(e.path))
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Pages saved so far while [downloadAll] runs, or null when idle.
  int? downloadProgress;

  /// Saves every page font for offline reading.
  /// Returns true if all of them were saved.
  Future<bool> downloadAll() async {
    if (downloadProgress != null || !canSaveOffline) return false;
    downloadProgress = await savedPageCount();
    notifyListeners();
    var ok = true;
    try {
      final dir = await _cacheDir();
      Future<void> save(String file, String url) async {
        final f = File('${dir.path}/$file');
        if (await f.exists()) return;
        final bytes = await _download(url);
        final tmp = File('${f.path}.part');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(f.path);
      }

      // A few downloads at a time keeps this quick without hogging the
      // connection.
      final queue = [for (var p = 1; p <= mushafPageCount; p++) p];
      Future<void> worker() async {
        while (queue.isNotEmpty) {
          final page = queue.removeLast();
          final existed = await File('${dir.path}/p$page.ttf').exists();
          try {
            await save('p$page.ttf', _pageUrl(page));
            if (!existed) {
              downloadProgress = downloadProgress! + 1;
              notifyListeners();
            }
          } catch (e) {
            ok = false;
          }
        }
      }

      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    } catch (e) {
      debugPrint('Mushaf download failed: $e');
      ok = false;
    } finally {
      downloadProgress = null;
      notifyListeners();
    }
    return ok;
  }
}
