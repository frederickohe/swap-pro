import 'package:swappro/barrel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

String? _ragDocSourceUrl(Map<String, dynamic> doc) {
  final url = doc['source_url'] ?? doc['sourceUrl'];
  if (url == null) return null;
  final s = url.toString().trim();
  return s.isEmpty ? null : s;
}

bool _ragDocIsWebsite(Map<String, dynamic> doc) {
  final type = (doc['source_type'] ?? doc['sourceType'] ?? '')
      .toString()
      .toLowerCase();
  if (type == 'website') return true;
  return _ragDocSourceUrl(doc) != null;
}

/// Returns a full http(s) URL for the RAG indexer, or null if invalid.
String? _normalizeWebsiteUrlForApi(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  final lower = s.toLowerCase();
  if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
    s = 'https://$s';
  }
  final uri = Uri.tryParse(s);
  if (uri == null || !uri.hasScheme) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!uri.hasAuthority || uri.host.isEmpty) return null;
  return uri.toString();
}

class ManageIntelligence extends StatefulWidget {
  const ManageIntelligence({super.key});

  @override
  State<ManageIntelligence> createState() => _ManageIntelligenceState();
}

class _ManageIntelligenceState extends State<ManageIntelligence> {
  bool _presenceRequested = false;
  bool _presenceLoading = true;
  bool _hasRagDocuments = false;
  List<Map<String, dynamic>> _ragFiles = const [];
  String? _presenceError;

  Future<void> _loadRagPresence() async {
    if (!mounted) return;
    setState(() {
      _presenceLoading = true;
      _presenceError = null;
    });
    try {
      final api = context.read<ApiService>();
      final files = await api.listMyStorageFiles(
        folder: ApiService.profileImagesStorageFolder,
      );
      if (!mounted) return;
      setState(() {
        _ragFiles = files;
        _hasRagDocuments = files.isNotEmpty;
        _presenceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _presenceLoading = false;
        _hasRagDocuments = false;
        _ragFiles = const [];
      });
      await ApiErrorHandler.handle(
        context,
        e,
        onRetry: _loadRagPresence,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_presenceRequested) return;
    _presenceRequested = true;
    _loadRagPresence();
  }

  Future<void> _handleUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'pdf', 'docx', 'csv', 'xlsx'],
      allowMultiple: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final api = context.read<ApiService>();
    var successCount = 0;

    try {
      for (final picked in result.files) {
        final name = picked.name.trim().isEmpty ? 'upload' : picked.name;
        final path = picked.path?.trim();

        Future<Map<String, dynamic>> startJob() async {
          if (path != null && path.isNotEmpty) {
            return api.uploadRagDocument(
              filename: name,
              filePath: path,
              asyncMode: true,
            );
          }
          if (picked.bytes != null && picked.bytes!.isNotEmpty) {
            return api.uploadRagDocument(
              filename: name,
              fileBytes: picked.bytes!.toList(),
              asyncMode: true,
            );
          }
          throw Exception(
            'Could not read "$name". On this device, try choosing the file again.',
          );
        }

        await _runRagIndexWithProgress(
          title: result.files.length > 1
              ? 'Indexing ($name)'
              : 'Indexing document',
          startJob: startJob,
        );
        successCount++;
      }

      if (!mounted) return;
      await _loadRagPresence();
      if (!mounted) return;
      context.showAppSnackBar(
        successCount == 1
            ? 'Document uploaded and indexed.'
            : '$successCount documents uploaded and indexed.',
        variant: AppSnackBarVariant.success,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(_uploadErrorMessage(e));
    }
  }

  Future<void> _handleIndexWebsite() async {
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _WebsiteUrlDialog(),
    );

    if (!mounted || url == null || url.trim().isEmpty) return;

    final api = context.read<ApiService>();
    try {
      await _runRagIndexWithProgress(
        title: 'Indexing website',
        startJob: () => api.uploadRagUrl(url: url.trim()),
      );
      if (!mounted) return;
      await _loadRagPresence();
      if (!mounted) return;
      context.showAppSnackBar(
        'Website content scraped and indexed.',
        variant: AppSnackBarVariant.success,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(_uploadErrorMessage(e));
    }
  }

  Future<void> _runRagIndexWithProgress({
    required String title,
    required Future<Map<String, dynamic>> Function() startJob,
  }) async {
    final api = context.read<ApiService>();
    final error = await showDialog<Object?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _RagIndexProgressDialog(
          api: api,
          title: title,
          startJob: startJob,
        );
      },
    );
    if (error != null) throw error;
  }

  String _shortPresenceError(String raw, {int max = 160}) {
    final t = raw.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  String _uploadErrorMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('403')) {
      return 'Upload blocked: you do not have permission to upload RAG documents.';
    }
    if (raw.contains('Session expired') || raw.contains('401')) {
      return 'Session expired. Please sign in again.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  Future<void> _openIndexedWebsite(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      context.showAppSnackBar('Invalid URL');
      return;
    }
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      context.showAppSnackBar('Could not open website');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Widget> _websitesSection(BuildContext context) {
    final sites = _ragFiles.where(_ragDocIsWebsite).toList();
    if (sites.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3F1163), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.language_outlined,
                color: Colors.white.withValues(alpha: 0.65),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No websites indexed yet. Use Index Website to add a URL — you can paste https://, http://, or www. addresses.',
                  style: AppTypography.style(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    const maxShown = 8;
    final shown = sites.length > maxShown ? sites.sublist(0, maxShown) : sites;
    final tiles = <Widget>[
      for (final doc in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final u = _ragDocSourceUrl(doc);
                if (u != null) _openIndexedWebsite(u);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3F1163), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _ragDocSourceUrl(doc) ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];

    if (sites.length > maxShown) {
      tiles.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const IntelligenceHistoryPage(),
                ),
              );
              if (mounted) await _loadRagPresence();
            },
            child: Text(
              'View all ${sites.length} websites',
              style: AppTypography.style(
                color: const Color(0xFFA855F7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: ManageScreenStyle.homeDashboardBodyDecoration,
          ),
          SafeArea(
            child: Column(
              children: [
                const ManageScreenHeader(title: 'Manage Intelligence'),
                // Welcome Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            'Welcome to Business Chat Intelligence',
                            textAlign: TextAlign.center,
                            style: AppTypography.style(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Upload business information documents to train your AI assistant on your company\'s information. The AI can instantly answer customer questions, provide support, and deliver accurate responses based on your files — helping businesses automate communication and improve customer experience.',
                            textAlign: TextAlign.center,
                            style: AppTypography.style(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_presenceLoading) ...[
                            const SizedBox(height: 8),
                            const Center(
                              child: const SwapproLoadingIndicator(size: 28),
                            ),
                            const SizedBox(height: 24),
                          ] else if (_presenceError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    color: Colors.amber.shade300,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Could not verify your documents. Pull to refresh after opening the screen again, or check your connection.\n${_shortPresenceError(_presenceError!)}',
                                      style: AppTypography.style(
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _loadRagPresence,
                                    icon: Icon(
                                      Icons.refresh,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      size: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ] else if (!_hasRagDocuments) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF581C87,
                                ).withValues(alpha: 0.1),
                                border: Border.all(
                                  color: const Color(
                                    0xFF9333EA,
                                  ).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.red.shade400,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You have not uploaded any business data',
                                      style: AppTypography.style(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            const SizedBox(height: 8),
                          if (!_presenceLoading && _presenceError == null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Websites',
                                style: AppTypography.style(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._websitesSection(context),
                          ],
                          const SizedBox(height: 40),
                          // Action Cards Grid
                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.0,
                            children: [
                              _IntelligenceCard(
                                icon: Icons.description_outlined,
                                title: 'Upload Files',
                                onTap: _handleUploadFiles,
                              ),
                              _IntelligenceCard(
                                icon: Icons.language_outlined,
                                title: 'Index Website',
                                onTap: _handleIndexWebsite,
                              ),
                              _IntelligenceCard(
                                icon: Icons.folder_open_outlined,
                                title: 'View Sources',
                                onTap: () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const IntelligenceHistoryPage(),
                                    ),
                                  );
                                  if (mounted) await _loadRagPresence();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteUrlDialog extends StatefulWidget {
  const _WebsiteUrlDialog();

  @override
  State<_WebsiteUrlDialog> createState() => _WebsiteUrlDialogState();
}

class _WebsiteUrlDialogState extends State<_WebsiteUrlDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final normalized = _normalizeWebsiteUrlForApi(value);
    if (normalized == null) {
      setState(() {
        _error =
            'Enter a valid website URL (e.g. https://example.com or www.example.com)';
      });
      return;
    }
    Navigator.of(context).pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Index website',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will scrape the public page and add its text to your business knowledge base.',
              style: AppTypography.style(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: AppTypography.style(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://example.com or www.example.com',
                hintStyle: AppTypography.style(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                errorText: _error,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF9333EA)),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.style(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                  ),
                  child: Text(
                    'Index',
                    style: AppTypography.style(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RagIndexProgressDialog extends StatefulWidget {
  final ApiService api;
  final String title;
  final Future<Map<String, dynamic>> Function() startJob;

  const _RagIndexProgressDialog({
    required this.api,
    required this.title,
    required this.startJob,
  });

  @override
  State<_RagIndexProgressDialog> createState() =>
      _RagIndexProgressDialogState();
}

class _RagIndexProgressDialogState extends State<_RagIndexProgressDialog> {
  int _progress = 0;
  String _message = 'Starting…';
  String? _sourceLabel;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final started = await widget.startJob();
      final jobId = ApiService.ragIndexJobId(started);
      if (jobId == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      while (mounted) {
        final status = await widget.api.getRagIndexJobStatus(jobId);
        if (!mounted) return;

        final progress = status['progress'];
        final message = (status['message'] ?? '').toString();
        final label = (status['source_label'] ?? '').toString();

        setState(() {
          if (progress is int) {
            _progress = progress.clamp(0, 100);
          } else if (progress is num) {
            _progress = progress.round().clamp(0, 100);
          }
          if (message.isNotEmpty) _message = message;
          if (label.isNotEmpty) _sourceLabel = label;
        });

        if (ApiService.ragIndexJobTerminal(status)) {
          if (!ApiService.ragIndexJobSucceeded(status)) {
            final err =
                (status['error'] ?? status['message'] ?? 'Indexing failed')
                    .toString();
            throw Exception(err);
          }
          if (!mounted) return;
          Navigator.of(context).pop();
          return;
        }

        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = e.toString().replaceFirst('Exception: ', '');
        _progress = 100;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop(e);
    }
  }

  String _statusHeadline() {
    final lower = _message.toLowerCase();
    if (lower.contains('scrap')) return 'Fetching website';
    if (lower.contains('upload')) return 'Uploading';
    if (lower.contains('extract')) return 'Extracting text';
    if (lower.contains('chunk')) return 'Preparing content';
    if (lower.contains('index')) return 'Indexing';
    if (lower.contains('validat')) return 'Validating';
    if (_failed) return 'Failed';
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _statusHeadline(),
              textAlign: TextAlign.center,
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_sourceLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                _sourceLabel!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100 : null,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                color: _failed ? Colors.red.shade400 : const Color(0xFF9333EA),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_progress% · $_message',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntelligenceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _IntelligenceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3F1163), width: 1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.style(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntelligenceHistoryPage extends StatefulWidget {
  const IntelligenceHistoryPage({super.key});

  @override
  State<IntelligenceHistoryPage> createState() =>
      _IntelligenceHistoryPageState();
}

class _IntelligenceHistoryPageState extends State<IntelligenceHistoryPage> {
  List<Map<String, dynamic>> _documents = const [];
  bool _loading = true;
  String? _loadError;
  int? _expandedIndex;

  String _fileName(Map<String, dynamic> doc) =>
      (doc['file_name'] ?? '').toString();

  String? _objectKey(Map<String, dynamic> doc) {
    final k = doc['object_key'];
    if (k == null) return null;
    final s = k.toString();
    return s.isEmpty ? null : s;
  }

  String _displayTitle(Map<String, dynamic> doc) {
    final url = _ragDocSourceUrl(doc);
    if (url != null) return url;
    return _fileName(doc);
  }

  String _subtitle(Map<String, dynamic> doc) {
    if (_ragDocIsWebsite(doc)) {
      final name = _fileName(doc);
      return name.isEmpty ? 'Indexed website' : 'Saved as $name';
    }
    final key = _objectKey(doc);
    return key ?? '';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Invalid URL');
      return;
    }
    if (!await canLaunchUrl(uri)) {
      _showSnack('Could not open website');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFileUrl(Map<String, dynamic> doc) async {
    final raw = (doc['file_url'] ?? '').toString().trim();
    if (raw.isEmpty) {
      _showSnack('No download link for this file');
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      _showSnack('Invalid file link');
      return;
    }
    if (!await canLaunchUrl(uri)) {
      _showSnack('Could not open file');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _viewScrapedContent(Map<String, dynamic> doc) async {
    final raw = (doc['file_url'] ?? '').toString().trim();
    if (raw.isEmpty) {
      _showSnack('No content link available');
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A0A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF3F1163)),
          ),
          title: Text(
            _ragDocIsWebsite(doc) ? 'Indexed content' : 'File preview',
            style: AppTypography.style(color: Colors.white, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: FutureBuilder<String>(
              future: _fetchTextPreview(raw),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: const SwapproLoadingIndicator(size: 28),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: AppTypography.style(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  );
                }
                final text = snapshot.data ?? '';
                if (text.trim().isEmpty) {
                  return Text(
                    'No preview available.',
                    style: AppTypography.style(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  );
                }
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: AppTypography.style(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: AppTypography.style(color: const Color(0xFFA855F7)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchTextPreview(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load content (${response.statusCode})');
    }
    final body = response.body.trim();
    const maxChars = 12000;
    if (body.length <= maxChars) return body;
    return '${body.substring(0, maxChars)}\n\n…';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    context.showAppSnackBar(message);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final api = context.read<ApiService>();
      final list = await api.listMyStorageFiles(
        folder: ApiService.profileImagesStorageFolder,
      );
      if (!mounted) return;
      setState(() {
        _documents = list;
        _loading = false;
        _expandedIndex = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await ApiErrorHandler.handle(
        context,
        e,
        onRetry: _loadDocuments,
      );
    }
  }

  Future<void> _deleteAt(int index) async {
    final doc = _documents[index];
    final name = _fileName(doc);
    if (name.isEmpty) return;
    try {
      final api = context.read<ApiService>();
      await api.deleteMyStorageFile(
        folder: ApiService.profileImagesStorageFolder,
        fileName: name,
      );
      if (!mounted) return;
      setState(() {
        _documents = List<Map<String, dynamic>>.from(_documents)
          ..removeAt(index);
        _expandedIndex = null;
      });
      context.showAppSnackBar(
        'Deleted "$name"',
        variant: AppSnackBarVariant.success,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: ManageScreenStyle.homeDashboardBodyDecoration,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ManageScreenHeader(
                    title: 'Manage Intelligence',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: const SwapproLoadingIndicator(size: 32),
                          )
                        : _loadError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    _loadError!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.style(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _loadDocuments,
                                  child: Text(
                                    'Retry',
                                    style: AppTypography.style(
                                      color: const Color(0xFFA855F7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _documents.isEmpty
                        ? Center(
                            child: Text(
                              'No documents or websites indexed yet',
                              style: AppTypography.style(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFA855F7),
                            onRefresh: _loadDocuments,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _documents.length,
                              itemBuilder: (context, index) {
                                final doc = _documents[index];
                                final isWebsite = _ragDocIsWebsite(doc);
                                final title = _displayTitle(doc);
                                final subtitle = _subtitle(doc);
                                final sourceUrl = _ragDocSourceUrl(doc);
                                final isExpanded = _expandedIndex == index;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _expandedIndex = isExpanded
                                            ? null
                                            : index;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: EdgeInsets.all(
                                        isExpanded ? 32 : 24,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF3F1163),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          isExpanded ? 38 : 30,
                                        ),
                                      ),
                                      child: isExpanded
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isWebsite
                                                          ? Icons.language
                                                          : Icons
                                                                .description_outlined,
                                                      color: const Color(
                                                        0xFFA855F7,
                                                      ),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        isWebsite
                                                            ? 'Website'
                                                            : 'Document',
                                                        style:
                                                            AppTypography.style(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.7,
                                                                  ),
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  title,
                                                  style: AppTypography.style(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                if (subtitle.isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    subtitle,
                                                    style: AppTypography.style(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 16),
                                                if (isWebsite &&
                                                    sourceUrl != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            _openUrl(sourceUrl),
                                                        child: Text(
                                                          'Open website',
                                                          style:
                                                              AppTypography.style(
                                                                color:
                                                                    const Color(
                                                                      0xFFA855F7,
                                                                    ),
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        _viewScrapedContent(
                                                          doc,
                                                        ),
                                                    child: Text(
                                                      isWebsite
                                                          ? 'View indexed content'
                                                          : 'View file',
                                                      style: AppTypography.style(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!isWebsite)
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: TextButton(
                                                      onPressed: () =>
                                                          _openFileUrl(doc),
                                                      child: Text(
                                                        'Open in browser',
                                                        style:
                                                            AppTypography.style(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.75,
                                                                  ),
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Center(
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        _deleteAt(index),
                                                    child: Text(
                                                      isWebsite
                                                          ? 'Remove website'
                                                          : 'Delete file',
                                                      style: AppTypography.style(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isWebsite
                                                          ? Icons.language
                                                          : Icons
                                                                .description_outlined,
                                                      color: const Color(
                                                        0xFFA855F7,
                                                      ),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            AppTypography.style(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (subtitle.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    subtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTypography.style(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
