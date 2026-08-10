import 'dart:async';
import 'dart:io';

import 'package:digitalerp/utils/show_message.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Full-screen preview for a report PDF, with explicit Download and Share.
///
/// Before this existed every report went through `downloadAndSharePdfFile`,
/// which fetched the file and immediately opened the OS share sheet — the user
/// never saw the document and had to send it somewhere just to read it. This
/// renders the bytes in-app first and leaves saving/sharing as separate,
/// deliberate actions.
///
/// The bytes are fetched once and reused for preview, save and share, so
/// tapping Download after a preview costs no second round-trip.
///
/// Rendering is deliberately defensive. [SfPdfViewer] reports every load
/// problem through [SfPdfViewer.onDocumentLoadFailed] and otherwise just paints
/// a flat empty container, so an unhandled failure looks exactly like a working
/// screen with a blank page. On top of that its `isPdfLoaded` check also needs
/// page dimensions back from the native renderer, and that step can stall
/// without ever throwing. Both cases are caught here — see [_watchdog] — and
/// always leave the user a way to open the file.
class PdfPreviewScreen extends StatefulWidget {
  /// Absolute URL the report endpoint handed back (`data[0].url`).
  final String url;

  /// File name used when saving/sharing, without the `.pdf` extension.
  final String fileName;

  /// App-bar title, e.g. 'Party Ledger'.
  final String title;

  const PdfPreviewScreen({
    Key? key,
    required this.url,
    required this.fileName,
    this.title = 'Preview',
  }) : super(key: key);

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  static const Color _kBg = Color(0xFFF8F9FC);
  static const Color _kWhite = Colors.white;
  static const Color _kText = Color(0xFF111827);
  static const Color _kSub = Color(0xFF6B7280);
  static const Color _kBorder = Color(0xFFE4E7EF);
  static const Color _kAccent = Color(0xFF4F46E5);

  /// How long the renderer gets to produce a first page before we assume it
  /// has silently failed. Generous — a 10-page ledger rasterises in well under
  /// a second, but a cold start on a slow device can take a few.
  static const Duration _renderTimeout = Duration(seconds: 12);

  Uint8List? _bytes;

  /// The downloaded PDF written to the cache directory. Kept so Share and the
  /// "Open in another app" fallback never have to re-download.
  File? _cacheFile;

  String? _error;

  /// Extra line under [_error] carrying the technical detail, so the user sees
  /// a plain message and we still get something actionable to report.
  String? _errorDetail;

  double _progress = 0;
  bool _saving = false;
  bool _rendered = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  String get _safeName {
    // Report names are built from party names and dates, which routinely carry
    // '/' and ':' — both illegal in a file name on Android and iOS.
    final cleaned =
        widget.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'report' : cleaned;
  }

  void _fail(String message, [String? detail]) {
    if (!mounted) return;
    _watchdog?.cancel();
    setState(() {
      _error = message;
      _errorDetail = detail;
    });
  }

  Future<void> _load() async {
    _watchdog?.cancel();
    setState(() {
      _error = null;
      _errorDetail = null;
      _progress = 0;
      _bytes = null;
      _rendered = false;
    });
    try {
      final res = await Dio().get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          // The report host answers a bad selection with an HTML error page
          // rather than a PDF; accept it so we can show a real message
          // instead of a DioException.
          validateStatus: (s) => s != null && s < 500,
          headers: const {'Accept': 'application/pdf,*/*'},
        ),
        onReceiveProgress: (count, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = count / total);
          }
        },
      );

      final data = Uint8List.fromList(res.data ?? const []);

      // Validate both ends of the file. Checking only the '%PDF' header would
      // wave through a truncated download, which then fails inside the
      // renderer as an unexplained blank page.
      if (data.length < 1024 || String.fromCharCodes(data.take(4)) != '%PDF') {
        _fail('The server did not return a PDF for this selection.',
            'Received ${data.length} bytes.');
        return;
      }
      final tail = String.fromCharCodes(
          data.sublist(data.length - (data.length < 2048 ? data.length : 2048)));
      if (!tail.contains('%%EOF')) {
        _fail('The report file came through incomplete.',
            'Downloaded ${data.length} bytes with no end-of-file marker.');
        return;
      }

      // Write to cache up front so Share and the external-viewer fallback are
      // instant and work even if in-app rendering fails.
      File? file;
      try {
        final tmp = await getTemporaryDirectory();
        file = File('${tmp.path}/$_safeName.pdf');
        await file.writeAsBytes(data, flush: true);
      } catch (e) {
        debugPrint('PDF cache write failed: $e');
        file = null;
      }

      if (!mounted) return;
      setState(() {
        _bytes = data;
        _cacheFile = file;
      });

      // SfPdfViewer can stall without calling either callback (its readiness
      // check also depends on page sizes coming back from the native
      // renderer). Give up after a while rather than sit on a blank page.
      _watchdog = Timer(_renderTimeout, () {
        if (mounted && !_rendered && _error == null) {
          _fail('This report could not be displayed in the app.',
              'The viewer did not finish loading the document.');
        }
      });
    } catch (e) {
      _fail('Could not download the report.', e.toString());
    }
  }

  /// Writes the already-downloaded bytes to disk.
  ///
  /// Public Downloads is preferred so the file shows up in the user's file
  /// manager, but scoped storage blocks a direct write there on some Android
  /// builds, so this falls back to the app's own external directory rather
  /// than failing the save outright.
  Future<File?> _writeToDisk() async {
    final bytes = _bytes;
    if (bytes == null) return null;

    Directory? dir;
    if (Platform.isAndroid) {
      try {
        final path = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD);
        final candidate = Directory(path);
        if (await candidate.exists()) dir = candidate;
      } catch (_) {
        // Fall through to the app-private directory below.
      }
      dir ??= await getExternalStorageDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    if (dir == null) return null;

    var file = File('${dir.path}/$_safeName.pdf');
    // Don't silently overwrite a previous export of the same report.
    var n = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$_safeName ($n).pdf');
      n++;
    }

    try {
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } on FileSystemException {
      // Public Downloads refused the write — retry inside the app directory.
      final fallback = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      if (fallback == null) return null;
      final alt = File('${fallback.path}/$_safeName.pdf');
      await alt.writeAsBytes(bytes, flush: true);
      return alt;
    }
  }

  Future<void> _download() async {
    if (_bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final file = await _writeToDisk();
      if (file == null) {
        ShowMessage.showSnackBar('Download', 'Could not access storage');
        return;
      }
      ShowMessage.showSnackBar('Downloaded', 'Saved to ${file.path}');
      await OpenFilex.open(file.path);
    } catch (e) {
      ShowMessage.showSnackBar('Download failed', '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final file = _cacheFile;
    if (file == null) return;
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      ShowMessage.showSnackBar('Share failed', '$e');
    }
  }

  /// Hands the file to whatever PDF app the device has. The escape hatch for
  /// when the in-app renderer cannot display a particular report — the user
  /// still gets to read it.
  Future<void> _openExternally() async {
    final file = _cacheFile;
    if (file == null) {
      ShowMessage.showSnackBar('Open', 'The file is no longer available');
      return;
    }
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      ShowMessage.showSnackBar('Open', result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _cacheFile != null;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kWhite,
        elevation: 0,
        surfaceTintColor: _kWhite,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kText, size: 20),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        actions: [
          if (hasFile)
            IconButton(
              tooltip: 'Share',
              onPressed: _share,
              icon: const Icon(Icons.share_outlined, color: _kText, size: 21),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _kBorder, height: 1),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: hasFile ? _buildActionBar() : null,
    );
  }

  Widget _buildBody() {
    if (_error != null) return _buildError();
    if (_bytes == null) return _buildLoading();

    return SfPdfViewer.memory(
      _bytes!,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
      onDocumentLoaded: (details) {
        _watchdog?.cancel();
        if (mounted) setState(() => _rendered = true);
      },
      onDocumentLoadFailed: (details) {
        // Without this the viewer swallows the failure and paints an empty
        // container — the original "it showed nothing" report.
        //
        // SfPdfViewer collapses anything it does not recognise into a bare
        // 'Error', including a MissingPluginException from its own native
        // channel. That happens after the package is added to pubspec.yaml
        // but the app is only hot-restarted: hot restart reloads Dart and
        // leaves the old APK, so the Android half of the plugin is not
        // registered. It looks exactly like a broken PDF, so say so here.
        final hint = kDebugMode && details.error == 'Error'
            ? '\nIf the app was hot-restarted after adding a package, stop it '
                'and run a full build — hot restart does not install native '
                'plugin code.'
            : '';
        _fail('This report could not be displayed in the app.',
            '${details.error}: ${details.description}$hint');
      },
    );
  }

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _kAccent,
                // Indeterminate until the server sends a content length.
                value: _progress > 0 ? _progress : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _progress > 0
                  ? 'Loading report… ${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Loading report…',
              style: const TextStyle(fontSize: 13, color: _kSub),
            ),
          ],
        ),
      );

  Widget _buildError() {
    final canOpen = _cacheFile != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(canOpen ? Icons.picture_as_pdf_outlined : Icons.error_outline_rounded,
                size: 44, color: _kSub),
            const SizedBox(height: 14),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
            if (canOpen) ...[
              const SizedBox(height: 6),
              const Text(
                'The file downloaded correctly. Open it with your PDF app, or '
                'save it to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kSub, height: 1.4),
              ),
            ],
            if (_errorDetail != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorDetail!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _kSub, height: 1.35),
              ),
            ],
            const SizedBox(height: 20),
            if (canOpen)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open in another app'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAccent,
                side: const BorderSide(color: _kBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAccent,
                side: const BorderSide(color: _kBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _download,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_saving ? 'Saving…' : 'Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
