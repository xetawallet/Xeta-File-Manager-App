import 'dart:io';

import 'package:xeta_file_manager/crypto_donation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.xeta.file_manager/storage');
bool _isDarkMode = true;
Color get _navy =>
    _isDarkMode ? const Color(0xFFE7ECF5) : const Color(0xFF14233D);
Color get _surface => _isDarkMode ? const Color(0xFF182235) : Colors.white;
Color get _selectionSurface =>
    _isDarkMode ? const Color(0xFF263B60) : const Color(0xFFEAF0FF);
Color get _secondaryText =>
    _isDarkMode ? const Color(0xFFADB9CC) : const Color(0xFF778398);
Color get _infoSurface =>
    _isDarkMode ? const Color(0xFF202D42) : const Color(0xFFEAF0FF);
const _blue = Color(0xFF356AE6);
const _mint = Color(0xFF28C6A4);
Color get _paper =>
    _isDarkMode ? const Color(0xFF101827) : const Color(0xFFF5F7FB);

Future<T?> _native<T>(String method, [Map<String, Object?> args = const {}]) =>
    _channel.invokeMethod<T>(method, args);

const _sourceRepository = 'https://github.com/xetawallet/Xeta-File-Manager-App';
const _donationWallets = [
  DonationWallet(
    currency: 'ETH',
    network: 'Ethereum Mainnet',
    address: '0xD648bdD81A5FF2b20C02E10b6ca0a7416Ab1351E',
  ),
  DonationWallet(
    currency: 'BTC',
    network: 'Bitcoin Mainnet',
    address: 'bc1qu8x5tqrtfe7y8cwlqx2khaf79yqq2qazmuuhvt',
  ),
  DonationWallet(
    currency: 'SOL',
    network: 'Solana Mainnet',
    address: '5gR2nzxVG5QHGkF8oWgrR5Jr27xy9CRNebh5tLPANy2S',
  ),
];

class StorageRoot {
  const StorageRoot({
    required this.path,
    required this.name,
    required this.kind,
    required this.mounted,
    required this.removable,
  });
  final String path;
  final String name;
  final String kind;
  final bool mounted;
  final bool removable;

  factory StorageRoot.fromMap(Map<Object?, Object?> map) => StorageRoot(
    path: map['path'] as String? ?? '',
    name: map['name'] as String? ?? 'Storage',
    kind: map['kind'] as String? ?? 'other',
    mounted: map['mounted'] as bool? ?? false,
    removable: map['removable'] as bool? ?? false,
  );
}

class FsItem {
  const FsItem({
    required this.name,
    required this.path,
    required this.directory,
    required this.mime,
    required this.size,
    required this.modified,
    required this.created,
  });
  final String name;
  final String path;
  final bool directory;
  final String mime;
  final int size;
  final int modified;
  final int created;

  factory FsItem.fromMap(Map<Object?, Object?> map) => FsItem(
    name: map['name'] as String? ?? 'Untitled',
    path: map['path'] as String? ?? '',
    directory: map['directory'] as bool? ?? false,
    mime: map['mime'] as String? ?? 'application/octet-stream',
    size: (map['size'] as num?)?.toInt() ?? 0,
    modified: (map['modified'] as num?)?.toInt() ?? 0,
    created: (map['created'] as num?)?.toInt() ?? 0,
  );

  String get kind {
    if (directory) return 'Folder';
    if (mime.startsWith('image/')) return 'Image';
    if (mime.startsWith('video/')) return 'Video';
    if (mime.startsWith('audio/')) return 'Audio';
    if (mime.contains('pdf')) return 'PDF document';
    final ext = _extension(name);
    return ext.isEmpty ? 'File' : '${ext.toUpperCase()} file';
  }

  bool get isImage =>
      mime.startsWith('image/') ||
      const {
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'heic',
        'heif',
      }.contains(_extension(name).toLowerCase());
  bool get isVideo =>
      mime.startsWith('video/') ||
      const {
        'mp4',
        'm4v',
        'mov',
        'mkv',
        'webm',
        '3gp',
        'avi',
      }.contains(_extension(name).toLowerCase());
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
}

void main() => runApp(const XetaFileManagerApp());

class XetaFileManagerApp extends StatefulWidget {
  const XetaFileManagerApp({super.key});
  @override
  State<XetaFileManagerApp> createState() => _XetaFileManagerAppState();
}

class _XetaFileManagerAppState extends State<XetaFileManagerApp> {
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final dark = await _native<bool>('darkMode');
    if (dark != null && mounted) setState(() => _darkMode = dark);
  }

  Future<void> _setDarkMode(bool value) async {
    await _native<bool>('setDarkMode', {'value': value});
    if (!mounted) return;
    setState(() => _darkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = _darkMode;
    return MaterialApp(
      title: 'Xeta File Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
        appBarTheme: AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _navy,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.dark,
          surface: const Color(0xFF182235),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _navy,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF182235),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
      ),
      home: HomePage(darkMode: _darkMode, onThemeChanged: _setDarkMode),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF14233D),
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.folder_rounded, color: Colors.white, size: size * .62),
        Positioned(
          right: size * .10,
          bottom: size * .12,
          child: Container(
            width: size * .25,
            height: size * .25,
            decoration: BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF14233D), width: 2),
            ),
            child: Icon(
              Icons.check_rounded,
              size: size * .17,
              color: const Color(0xFF14233D),
            ),
          ),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _booting = true;
  bool _checkingOnboarding = true;
  bool _onboardingDone = false;
  bool _hasAccess = false;
  bool _removableWritable = false;
  List<StorageRoot> _roots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAccess();
  }

  Future<void> _loadState() async {
    try {
      final values = await Future.wait<Object?>([
        _native<bool>('onboardingDone'),
        _native<bool>('storageAccess'),
        _native<List<Object?>>('volumes'),
        _native<bool>('removableWritable'),
      ]);
      if (!mounted) return;
      setState(() {
        _onboardingDone = values[0] as bool? ?? false;
        _hasAccess = values[1] as bool? ?? false;
        _roots = (values[2] as List<Object?>? ?? [])
            .map(
              (value) =>
                  StorageRoot.fromMap(Map<Object?, Object?>.from(value as Map)),
            )
            .toList();
        _removableWritable = values[3] as bool? ?? false;
        _booting = false;
        _checkingOnboarding = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _checkingOnboarding = false;
      });
      _toast(error.message ?? 'Could not load storage');
    }
  }

  Future<void> _refreshAccess() async {
    try {
      final access = await _native<bool>('storageAccess') ?? false;
      final values = await _native<List<Object?>>('volumes') ?? [];
      final write = await _native<bool>('removableWritable') ?? false;
      if (mounted) {
        setState(() {
          _hasAccess = access;
          _roots = values
              .map(
                (value) => StorageRoot.fromMap(
                  Map<Object?, Object?>.from(value as Map),
                ),
              )
              .toList();
          _removableWritable = write;
        });
      }
    } on PlatformException catch (error) {
      _toast(error.message ?? 'Could not refresh storage');
    }
  }

  Future<void> _finishOnboarding() async {
    await _native<bool>('finishOnboarding');
    if (!mounted) return;
    setState(() => _onboardingDone = true);
    await _refreshAccess();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          initialAccess: _hasAccess,
          initialWritable: _removableWritable,
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
    _refreshAccess();
  }

  void _connect(String kind) {
    if (!_hasAccess) {
      _toast('Allow storage access in Settings to browse files.');
      _openSettings();
      return;
    }
    final matches = _roots.where((root) => root.kind == kind && root.mounted);
    if (matches.isEmpty) {
      _toast(
        kind == 'otg'
            ? 'OTG drive not connected'
            : kind == 'sd'
            ? 'SD card not connected'
            : 'Internal storage is unavailable',
      );
      _refreshAccess();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrowserPage(
          root: matches.first,
          availableRoots: _roots,
          removableWritable: _removableWritable,
        ),
      ),
    );
  }

  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting || _checkingOnboarding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone) {
      return OnboardingPage(
        onDone: _finishOnboarding,
        hasAccess: _hasAccess,
        onAccessChanged: _refreshAccess,
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      );
    }
    final sources = [
      (
        'internal',
        'Internal Storage',
        Icons.phone_android_rounded,
        _blue,
        'Browse files on this device',
      ),
      (
        'sd',
        'SD Card',
        Icons.sd_card_rounded,
        const Color(0xFF875BE5),
        'Browse your removable memory card',
      ),
      (
        'otg',
        'OTG Drive',
        Icons.usb_rounded,
        const Color(0xFF0A9C7B),
        _removableWritable
            ? 'Connected · Writing enabled'
            : 'Connected · Read-only',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 23, 22, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const BrandMark(size: 50),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xeta File Manager',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your storage, clearly organized',
                            style: TextStyle(
                              color: _secondaryText,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh storage',
                      onPressed: _refreshAccess,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Storage locations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                    ),
                    if (!_hasAccess)
                      Text(
                        'Access needed',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode
                              ? const Color(0xFFFFC36D)
                              : const Color(0xFFB66B17),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 3, 16, 22),
              sliver: SliverList.builder(
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final (kind, title, icon, color, subtitle) = sources[index];
                  final volume = _roots
                      .where((root) => root.kind == kind && root.mounted)
                      .firstOrNull;
                  final connected = kind == 'internal'
                      ? _hasAccess
                      : volume != null;
                  final status = !_hasAccess
                      ? 'Grant access to browse'
                      : connected
                      ? kind == 'otg'
                            ? subtitle
                            : 'Connected · Tap to browse'
                      : 'Not connected';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => _connect(kind),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 49,
                              height: 49,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .11),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(icon, color: color),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: _navy,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: connected
                                          ? _isDarkMode
                                                ? const Color(0xFF6AD9B7)
                                                : const Color(0xFF07896D)
                                          : _secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              connected
                                  ? Icons.chevron_right_rounded
                                  : Icons.lock_outline_rounded,
                              color: connected
                                  ? _secondaryText
                                  : _isDarkMode
                                  ? const Color(0xFF718098)
                                  : const Color(0xFF9AA5B6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(21, 0, 21, 28),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _infoSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: _blue, size: 21),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'OTG drives open read-only. Enable writing in Settings when you need to change files. Existing files are never overwritten, and this app cannot format drives.',
                          style: TextStyle(
                            color: _navy,
                            height: 1.45,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onDone,
    required this.hasAccess,
    required this.onAccessChanged,
    required this.darkMode,
    required this.onThemeChanged,
  });
  final Future<void> Function() onDone;
  final bool hasAccess;
  final Future<void> Function() onAccessChanged;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _granting = false;
  bool _hasAccess = false;
  @override
  void initState() {
    super.initState();
    _hasAccess = widget.hasAccess;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _grantAccess() async {
    setState(() => _granting = true);
    try {
      _hasAccess = await _native<bool>('requestStorageAccess') ?? false;
      await widget.onAccessChanged();
      if (mounted) setState(() {});
      if (!_hasAccess && mounted) {
        _message(
          'Storage access was not enabled. You can try again in Settings.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _message(error.message ?? 'Could not open storage access settings');
      }
    }
    if (mounted) setState(() => _granting = false);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _next() async {
    if (_page < 3) {
      setState(() => _page++);
      _controller.animateToPage(
        _page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      await widget.onDone();
    }
  }

  Future<void> _openSourceRepository() async {
    try {
      await _native<bool>('openUrl', {'url': _sourceRepository});
    } on PlatformException catch (error) {
      _message(error.message ?? 'Could not open the source code link');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          if (_page == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 20, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    widget.darkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 18,
                    color: _blue,
                  ),
                  const SizedBox(width: 8),
                  const Text('Dark mode'),
                  const SizedBox(width: 5),
                  Switch(
                    value: widget.darkMode,
                    onChanged: widget.onThemeChanged,
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (value) => setState(() => _page = value),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _OnboardingSlide(
                  icon: const BrandMark(size: 86),
                  eyebrow: 'WELCOME',
                  title: 'Xeta File Manager',
                  text:
                      'Browse your phone, SD card, and USB drive from one calm, organized place.',
                  bullets: const [
                    ('folder_copy_rounded', 'Browse by folder or file type'),
                    ('image_rounded', 'Preview photos and video thumbnails'),
                    (
                      'drive_file_move_outline',
                      'Organize, copy, move, and rename files',
                    ),
                    ('sort_rounded', 'Sort files and view their properties'),
                  ],
                ),
                _OnboardingSlide(
                  icon: _permissionIllustration(),
                  eyebrow: 'STORAGE ACCESS',
                  title: 'One approval. Your storage.',
                  text:
                      'Grant access to browse files across your device and connected storage.',
                  bullets: const [
                    ('lock_open_rounded', 'Internal Storage'),
                    ('sd_card_rounded', 'SD Cards'),
                    ('usb_rounded', 'OTG drives'),
                  ],
                  action: FilledButton.icon(
                    onPressed: _granting ? null : _grantAccess,
                    icon: _granting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _hasAccess
                                ? Icons.check_rounded
                                : Icons.security_rounded,
                          ),
                    label: Text(
                      _hasAccess
                          ? 'Storage access granted'
                          : 'Allow storage access',
                    ),
                  ),
                ),
                _OnboardingSlide(
                  icon: const BrandMark(size: 86),
                  eyebrow: 'USB / OTG SAFETY',
                  title: 'Your OTG starts read-only',
                  text:
                      'OTG drives open read-only until you choose to allow changes in Settings. If a file or folder with the same name already exists at the destination, copy, move, or rename stops. The existing item stays untouched, and a moved item stays in its original location.',
                  bullets: const [
                    (
                      'visibility_rounded',
                      'Enable OTG writing only when you want to edit files',
                    ),
                    (
                      'do_not_disturb_on_rounded',
                      'Name conflicts never replace or delete existing files',
                    ),
                  ],
                ),
                _OnboardingSlide(
                  icon: const Icon(
                    Icons.shield_outlined,
                    size: 86,
                    color: _blue,
                  ),
                  eyebrow: 'OPEN SOURCE & PRIVACY',
                  title: 'Your data stays yours',
                  text:
                      'While other apps may collect your data, we don’t. All our source code is open source.',
                  bullets: const [],
                  footer: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openSourceRepository,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Find our source code here'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    4,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 23 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? _blue : const Color(0xFFD4DAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 11,
                    ),
                    child: Text(_page == 3 ? 'Start browsing' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _permissionIllustration() => Container(
    width: 86,
    height: 86,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0FF),
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Icon(Icons.folder_shared_rounded, color: _blue, size: 44),
  );
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.text,
    required this.bullets,
    this.action,
    this.footer,
  });
  final Widget icon;
  final String eyebrow;
  final String title;
  final String text;
  final List<(String, String)> bullets;
  final Widget? action;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(27, 25, 27, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: icon),
        const SizedBox(height: 31),
        Text(
          eyebrow,
          style: TextStyle(
            color: _blue,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 27,
            height: 1.16,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(color: _secondaryText, height: 1.52, fontSize: 14),
        ),
        const SizedBox(height: 20),
        for (final (iconName, label) in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_iconByName(iconName), color: _blue, size: 18),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (action != null) ...[
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: action!),
        ],
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ],
    ),
  );
}

IconData _iconByName(String name) => switch (name) {
  'folder_copy_rounded' => Icons.folder_copy_rounded,
  'code_rounded' => Icons.code_rounded,
  'image_rounded' => Icons.image_rounded,
  'lock_open_rounded' => Icons.lock_open_rounded,
  'sd_card_rounded' => Icons.sd_card_rounded,
  'usb_rounded' => Icons.usb_rounded,
  'visibility_rounded' => Icons.visibility_rounded,
  'do_not_disturb_on_rounded' => Icons.do_not_disturb_on_rounded,
  _ => Icons.folder_rounded,
};

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialAccess,
    required this.initialWritable,
    required this.darkMode,
    required this.onThemeChanged,
  });
  final bool initialAccess;
  final bool initialWritable;
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _hasAccess = widget.initialAccess;
  late bool _removableWritable = widget.initialWritable;
  late bool _darkMode = widget.darkMode;
  bool _busy = false;
  Future<void> _grant() async {
    setState(() => _busy = true);
    try {
      _hasAccess = await _native<bool>('openStorageSettings') ?? false;
    } on PlatformException catch (error) {
      _message(error.message ?? 'Could not open storage access settings');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setWritable(bool value) async {
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable OTG writing?'),
          content: const Text(
            'This enables rename, delete, copy-to, and move operations on connected OTG drives. Existing files are never overwritten. Xeta File Manager has no drive-formatting feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep read-only'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable writing'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _native<bool>('setRemovableWritable', {'value': value});
    if (mounted) setState(() => _removableWritable = value);
  }

  void _setTheme(bool value) {
    widget.onThemeChanged(value);
    setState(() => _darkMode = value);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings · Xeta File Manager')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        const _SectionLabel('STORAGE ACCESS'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _hasAccess,
                onChanged: _busy ? null : (_) => _grant(),
                secondary: const Icon(Icons.security_rounded, color: _blue),
                title: const Text('Manage all files'),
                subtitle: Text(
                  _hasAccess
                      ? 'Allowed · storage opens directly'
                      : 'Required to browse internal and removable storage',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const _SectionLabel('APPEARANCE'),
        Card(
          child: SwitchListTile(
            value: _darkMode,
            onChanged: _setTheme,
            secondary: Icon(
              _darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: _blue,
            ),
            title: const Text('Dark mode'),
            subtitle: Text(_darkMode ? 'On' : 'Off'),
          ),
        ),
        const SizedBox(height: 15),
        const _SectionLabel('OTG DRIVE SAFETY'),
        Card(
          child: SwitchListTile(
            value: _removableWritable,
            onChanged: _setWritable,
            secondary: const Icon(Icons.usb_rounded, color: _blue),
            title: const Text(
              'Allow writing to OTG drives',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _removableWritable
                  ? 'Writing is enabled for connected OTG drives'
                  : 'Read-only · changes are blocked',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: _blue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The app never formats drives. Copy and rename stop if the destination name already exists; existing files are not replaced.',
                    style: TextStyle(
                      color: _navy,
                      height: 1.45,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        const _SectionLabel('OPEN SOURCE & PRIVACY'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.code_rounded, color: _blue),
                title: const Text('Find our source code here'),
                subtitle: const Text('All our source code is open source.'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () =>
                    _native<bool>('openUrl', {'url': _sourceRepository}),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.insights_outlined, color: _blue),
                title: Text('No metrics collected'),
                subtitle: Text(
                  'This app does not collect analytics or usage metrics.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const _SectionLabel('SUPPORT DEVELOPMENT'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.volunteer_activism_rounded, color: _blue),
            title: const Text('Help us! / Donate'),
            subtitle: const Text('Support development with cryptocurrency'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const CryptoDonationPage(wallets: _donationWallets),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(5, 9, 5, 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: Color(0xFF778398),
      ),
    ),
  );
}

enum BrowseMode { path, type }

enum LayoutMode { list, grid }

enum _SortField { name, created, updated, size }

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.root,
    required this.availableRoots,
    required this.removableWritable,
  });
  final StorageRoot root;
  final List<StorageRoot> availableRoots;
  final bool removableWritable;
  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final List<String> _paths = [];
  final List<String> _names = [];
  final Set<String> _selected = {};
  final _search = TextEditingController();
  List<FsItem> _items = [];
  BrowseMode _mode = BrowseMode.path;
  LayoutMode _layout = LayoutMode.list;
  bool _busy = true;
  bool _removableWritable = false;
  String _query = '';
  String? _selectedType;
  _SortField _sortField = _SortField.name;
  bool _ascending = true;
  String get _currentPath => _paths.isEmpty ? widget.root.path : _paths.last;

  @override
  void initState() {
    super.initState();
    _removableWritable = widget.removableWritable;
    _loadFolder();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFolder() async {
    setState(() {
      _busy = true;
      _selected.clear();
    });
    try {
      final values =
          await _native<List<Object?>>('list', {'path': _currentPath}) ?? [];
      if (mounted) {
        setState(() {
          _items = values
              .map((v) => FsItem.fromMap(Map<Object?, Object?>.from(v as Map)))
              .toList();
          _busy = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _busy = false);
      _toast(error.message ?? 'Could not read this folder');
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _busy = true;
      _selected.clear();
    });
    try {
      final values =
          await _native<List<Object?>>('scan', {'path': widget.root.path}) ??
          [];
      if (mounted) {
        setState(() {
          _items = values
              .map((v) => FsItem.fromMap(Map<Object?, Object?>.from(v as Map)))
              .toList();
          _busy = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _busy = false);
      _toast(error.message ?? 'Could not index this storage');
    }
  }

  void _changeMode(BrowseMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _query = '';
      _selectedType = null;
      _search.clear();
    });
    if (mode == BrowseMode.path) {
      _loadFolder();
    } else {
      _loadAll();
    }
  }

  Future<void> _open(FsItem item) async {
    if (_selected.isNotEmpty) {
      _toggle(item);
      return;
    }
    if (item.directory) {
      setState(() {
        _paths.add(item.path);
        _names.add(item.name);
      });
      await _loadFolder();
    } else if (item.isImage) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => ImagePreview(item: item)));
    } else {
      try {
        final opened =
            await _native<bool>('open', {'path': item.path}) ?? false;
        if (!opened) _toast('${item.kind} · ${item.name}');
      } on PlatformException catch (error) {
        _toast(error.message ?? 'Could not open this file');
      }
    }
  }

  void _toggle(FsItem item) => setState(() {
    if (!_selected.add(item.path)) _selected.remove(item.path);
  });
  void _selectAll(List<FsItem> items) => setState(() {
    if (items.isNotEmpty &&
        items.every((item) => _selected.contains(item.path))) {
      _selected.removeAll(items.map((item) => item.path));
    } else {
      _selected.addAll(items.map((item) => item.path));
    }
  });

  void _longPress(FsItem item) => _itemActions(item);

  Future<void> _itemActions(FsItem item) async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Properties'),
              onTap: () {
                Navigator.pop(sheetContext);
                _properties(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('Select'),
              onTap: () {
                Navigator.pop(sheetContext);
                _toggle(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(sheetContext);
                _rename(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy to…'),
              onTap: () {
                Navigator.pop(sheetContext);
                _transfer([item], false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Move to…'),
              onTap: () {
                Navigator.pop(sheetContext);
                _transfer([item], true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _delete([item]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _properties(FsItem item) async {
    String date(int value) => value <= 0
        ? 'Unavailable'
        : DateTime.fromMillisecondsSinceEpoch(
            value,
          ).toLocal().toString().substring(0, 16);
    final values = <(String, String)>[
      ('File name', item.name),
      ('Path', item.path),
      ('Type', item.directory ? 'Folder' : item.kind),
      ('Size', item.directory ? '—' : _formatSize(item.size)),
      ('Created', date(item.created)),
      ('Updated on', date(item.modified)),
      (
        'Location',
        item.path.split('/').length > 1
            ? item.path.split('/').skip(1).first
            : 'Storage',
      ),
      ('Status', item.directory ? 'Folder' : 'File'),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Properties'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (key, value) in values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: '$key: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: value),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(FsItem item) async {
    final extension = _extension(item.name);
    final lockedExtension = extension.isEmpty
        ? ''
        : '.${item.name.substring(item.name.lastIndexOf('.') + 1)}';
    final stem = lockedExtension.isEmpty
        ? item.name
        : item.name.substring(0, item.name.length - lockedExtension.length);
    final controller = TextEditingController(text: stem);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename file'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  isDense: true,
                ),
              ),
            ),
            if (lockedExtension.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 17, left: 2),
                child: Text(
                  lockedExtension,
                  style: const TextStyle(
                    color: Color(0xFF929BAA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || result == stem) return;
    try {
      await _native<String>('rename', {
        'source': item.path,
        'name': '$result$lockedExtension',
      });
      await _reload();
    } on PlatformException catch (error) {
      _toast(error.message ?? 'Rename failed');
    }
  }

  Future<void> _delete(List<FsItem> items) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected items?'),
        content: Text(
          '${items.length} item${items.length == 1 ? '' : 's'} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm permanent deletion'),
        content: const Text('This cannot be undone. Delete these items now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep files'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (second != true) return;
    setState(() => _busy = true);
    try {
      for (final item in items) {
        await _native<bool>('delete', {'path': item.path});
      }
      await _reload();
    } on PlatformException catch (error) {
      _toast(error.message ?? 'Delete failed');
      await _reload();
    }
  }

  Future<void> _transfer(List<FsItem> items, bool move) async {
    final target = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DestinationPage(
          initialRoot: widget.root,
          roots: widget.availableRoots.where((root) => root.mounted).toList(),
        ),
      ),
    );
    if (target == null) return;
    setState(() => _busy = true);
    try {
      for (final item in items) {
        await _native<bool>(move ? 'move' : 'copy', {
          'source': item.path,
          'target': target,
        });
      }
      await _reload();
      _toast(move ? 'Items moved' : 'Items copied');
    } on PlatformException catch (error) {
      _toast(error.message ?? 'Transfer failed');
      await _reload();
    }
  }

  Future<void> _selectionAction(String action) async {
    final selected = _items
        .where((item) => _selected.contains(item.path))
        .toList();
    if (selected.isEmpty) return;
    if (action == 'delete') {
      await _delete(selected);
      return;
    }
    if (action == 'copy' || action == 'move') {
      await _transfer(selected, action == 'move');
      return;
    }
    if (action == 'rename' && selected.length == 1) {
      await _rename(selected.single);
    }
  }

  Future<void> _reload() =>
      _mode == BrowseMode.path ? _loadFolder() : _loadAll();
  Future<void> _goBack() async {
    if (_selected.isNotEmpty) {
      setState(_selected.clear);
      return;
    }
    if (_mode == BrowseMode.type) {
      if (_selectedType != null) {
        setState(() {
          _selectedType = null;
          _selected.clear();
          _query = '';
          _search.clear();
        });
        return;
      }
      setState(() {
        _mode = BrowseMode.path;
        _query = '';
        _search.clear();
      });
      await _loadFolder();
      return;
    }
    if (_names.isNotEmpty) {
      setState(() {
        _names.removeLast();
        _paths.removeLast();
      });
      await _loadFolder();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _toast(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _setRemovableWritable() async {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow OTG changes?'),
        content: const Text(
          'This enables changes on USB drives. The app will never format a drive or replace an existing file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay read-only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable writing'),
          ),
        ],
      ),
    );
    if (allow != true) return;
    await _native<bool>('setRemovableWritable', {'value': true});
    if (mounted) setState(() => _removableWritable = true);
  }

  @override
  Widget build(BuildContext context) {
    final typeFiles = _items.where((item) => !item.directory).toList();
    final typeGroups = <String, List<FsItem>>{};
    for (final item in typeFiles) {
      final ext = _extension(item.name).toUpperCase();
      final key = ext.isEmpty
          ? 'Other files'
          : ext == 'JPEG'
          ? 'JPG'
          : ext;
      typeGroups.putIfAbsent(key, () => []).add(item);
    }
    final filtered = _items
        .where(
          (item) =>
              _mode != BrowseMode.type ||
              _selectedType == null ||
              _extension(item.name).toUpperCase() == _selectedType ||
              (_selectedType == 'JPG' &&
                  const {
                    'JPG',
                    'JPEG',
                  }.contains(_extension(item.name).toUpperCase())) ||
              (_selectedType == 'Other files' && _extension(item.name).isEmpty),
        )
        .where(
          (item) => '${item.name} ${item.path}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    int compareItems(FsItem a, FsItem b) {
      final result = switch (_sortField) {
        _SortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _SortField.created => a.created.compareTo(b.created),
        _SortField.updated => a.modified.compareTo(b.modified),
        _SortField.size => a.size.compareTo(b.size),
      };
      return _ascending ? result : -result;
    }

    filtered.sort((a, b) {
      if (_mode == BrowseMode.path && a.directory != b.directory) {
        return a.directory ? -1 : 1;
      }
      return compareItems(a, b);
    });
    final sortedGroups =
        typeGroups.entries
            .where(
              (entry) => entry.key.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) {
            int result;
            if (_sortField == _SortField.size) {
              result = a.value
                  .fold<int>(0, (sum, item) => sum + item.size)
                  .compareTo(
                    b.value.fold<int>(0, (sum, item) => sum + item.size),
                  );
            } else if (_sortField == _SortField.created) {
              result = a.value
                  .map((item) => item.created)
                  .fold<int>(0, (x, y) => x > y ? x : y)
                  .compareTo(
                    b.value
                        .map((item) => item.created)
                        .fold<int>(0, (x, y) => x > y ? x : y),
                  );
            } else if (_sortField == _SortField.updated) {
              result = a.value
                  .map((item) => item.modified)
                  .fold<int>(0, (x, y) => x > y ? x : y)
                  .compareTo(
                    b.value
                        .map((item) => item.modified)
                        .fold<int>(0, (x, y) => x > y ? x : y),
                  );
            } else {
              result = a.key.toLowerCase().compareTo(b.key.toLowerCase());
            }
            return _ascending ? result : -result;
          });
    final showingTypes = _mode == BrowseMode.type && _selectedType == null;
    final displayCount = showingTypes ? sortedGroups.length : filtered.length;
    final allSelected =
        filtered.isNotEmpty &&
        filtered.every((item) => _selected.contains(item.path));
    return PopScope(
      canPop: _names.isEmpty && _mode == BrowseMode.path && _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: _names.isEmpty ? 'Back' : 'Previous folder',
            onPressed: _selected.isNotEmpty
                ? () => setState(_selected.clear)
                : _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            _selected.isEmpty
                ? widget.root.kind == 'otg'
                      ? 'OTG Drive'
                      : widget.root.kind == 'sd'
                      ? 'SD Card'
                      : 'Internal Storage'
                : '${_selected.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (widget.root.kind == 'otg' && !_removableWritable)
              IconButton(
                tooltip: 'Enable OTG writing',
                onPressed: _setRemovableWritable,
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            if (_selected.isNotEmpty) ...[
              if (_selected.length == 1)
                IconButton(
                  tooltip: 'Rename',
                  onPressed: () => _selectionAction('rename'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: 'Copy to',
                onPressed: () => _selectionAction('copy'),
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                tooltip: 'Move to',
                onPressed: () => _selectionAction('move'),
                icon: const Icon(Icons.drive_file_move_outline),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _selectionAction('delete'),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              IconButton(
                tooltip: 'Select all',
                onPressed: () => _selectAll(filtered),
                icon: Icon(
                  allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
              ),
            ] else if (!showingTypes)
              IconButton(
                tooltip: 'Select all',
                onPressed: filtered.isEmpty ? null : () => _selectAll(filtered),
                icon: const Icon(Icons.select_all_rounded),
              ),
          ],
        ),
        body: Column(
          children: [
            if (widget.root.kind == 'otg') _otgBanner(),
            if (_mode == BrowseMode.path) _breadcrumbs(),
            if (_mode == BrowseMode.type && _selectedType != null)
              SizedBox(
                height: 38,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedType = null),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text('All types  /  $_selectedType'),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF26344B)
                          : const Color(0xFFE8ECF4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _modeButton(
                          'Path wise',
                          _mode == BrowseMode.path,
                          () => _changeMode(BrowseMode.path),
                        ),
                        _modeButton(
                          'Type wise',
                          _mode == BrowseMode.type,
                          () => _changeMode(BrowseMode.type),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: _surface,
                            hintText: 'Search files',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'List view',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _layout = LayoutMode.list),
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: _layout == LayoutMode.list
                                    ? _blue
                                    : _secondaryText,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Grid view',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _layout = LayoutMode.grid),
                              icon: Icon(
                                Icons.grid_view_rounded,
                                color: _layout == LayoutMode.grid
                                    ? _blue
                                    : _secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Sort by',
                        style: TextStyle(color: _secondaryText, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<_SortField>(
                        value: _sortField,
                        style: TextStyle(color: _navy, fontSize: 12),
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: _SortField.name,
                            child: Text('Name wise'),
                          ),
                          DropdownMenuItem(
                            value: _SortField.created,
                            child: Text('Created date'),
                          ),
                          DropdownMenuItem(
                            value: _SortField.updated,
                            child: Text('Updated date'),
                          ),
                          DropdownMenuItem(
                            value: _SortField.size,
                            child: Text('Size'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          if (value != null) _sortField = value;
                        }),
                      ),
                      IconButton(
                        tooltip: _ascending ? 'Ascending' : 'Descending',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setState(() => _ascending = !_ascending),
                        icon: Icon(
                          _ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_mode == BrowseMode.type && _selectedType != null && !_busy)
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 0, 16, 5),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} files',
                      style: const TextStyle(
                        color: Color(0xFF7B879A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: filtered.isEmpty
                          ? null
                          : () => _selectAll(filtered),
                      icon: Icon(
                        allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18,
                      ),
                      label: Text(allSelected ? 'Clear all' : 'Select all'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : displayCount == 0
                  ? _EmptyFiles(searching: _query.isNotEmpty)
                  : showingTypes
                  ? _layout == LayoutMode.grid
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: sortedGroups.length,
                            itemBuilder: (_, index) => _typeCard(
                              sortedGroups[index].key,
                              sortedGroups[index].value.length,
                              true,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(11, 3, 11, 24),
                            itemCount: sortedGroups.length,
                            itemBuilder: (_, index) => _typeCard(
                              sortedGroups[index].key,
                              sortedGroups[index].value.length,
                              false,
                            ),
                          )
                  : _layout == LayoutMode.grid
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(13, 4, 13, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => _gridItem(filtered[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(11, 3, 11, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => _listItem(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otgBanner() => Container(
    margin: const EdgeInsets.fromLTRB(15, 2, 15, 5),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _removableWritable
          ? _isDarkMode
                ? const Color(0xFF1D3938)
                : const Color(0xFFE6F7F2)
          : _isDarkMode
          ? const Color(0xFF202D42)
          : const Color(0xFFEAF0FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          _removableWritable ? Icons.edit_rounded : Icons.visibility_rounded,
          size: 17,
          color: _removableWritable
              ? _isDarkMode
                    ? const Color(0xFF6AD9B7)
                    : const Color(0xFF07896D)
              : _blue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _removableWritable
                ? 'Removable-drive writing is enabled'
                : 'Read-only · files are protected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _navy,
            ),
          ),
        ),
        if (!_removableWritable)
          TextButton(
            onPressed: _setRemovableWritable,
            child: const Text('Enable'),
          ),
      ],
    ),
  );

  Widget _breadcrumbs() => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        _crumb(
          widget.root.kind == 'otg'
              ? 'OTG Drive'
              : widget.root.kind == 'sd'
              ? 'SD Card'
              : 'Internal Storage',
          () {
            setState(() {
              _paths.clear();
              _names.clear();
            });
            _loadFolder();
          },
        ),
        for (var i = 0; i < _names.length; i++) ...[
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9AA5B6),
            size: 18,
          ),
          _crumb(_names[i], () {
            setState(() {
              final keep = i + 1;
              _paths.removeRange(keep, _paths.length);
              _names.removeRange(keep, _names.length);
            });
            _loadFolder();
          }),
        ],
      ],
    ),
  );

  Widget _crumb(String text, VoidCallback action) => InkWell(
    onTap: action,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    ),
  );

  Widget _typeCard(String type, int count, bool grid) {
    final icon = switch (type.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'jpg' || 'png' || 'jpeg' || 'gif' || 'webp' => Icons.image_rounded,
      'mp4' || 'mkv' || 'mov' || 'avi' => Icons.movie_rounded,
      'mp3' || 'wav' || 'm4a' => Icons.music_note_rounded,
      'other files' => Icons.insert_drive_file_outlined,
      _ => Icons.description_outlined,
    };
    return Card(
      margin: grid ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () => setState(() => _selectedType = type),
        leading: CircleAvatar(
          backgroundColor: _isDarkMode
              ? const Color(0xFF26344B)
              : const Color(0xFFEAF0FF),
          foregroundColor: _blue,
          child: Icon(icon),
        ),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$count ${count == 1 ? 'file' : 'files'}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback action) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: action,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? _surface : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? _navy : _secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _listItem(FsItem item) {
    final selected = _selected.contains(item.path);
    return Card(
      color: selected ? _selectionSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? _blue : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(item),
        onLongPress: () => _longPress(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              if (_selected.isNotEmpty)
                SizedBox(
                  width: 37,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => _toggle(item),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                )
              else
                const SizedBox(width: 3),
              _ItemPreview(item: item, size: 45),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mode == BrowseMode.type
                          ? _shortPath(item.path)
                          : item.directory
                          ? 'Folder'
                          : '${item.kind} · ${_formatSize(item.size)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _secondaryText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'More options',
                onPressed: () => _itemActions(item),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.more_vert_rounded, color: _secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridItem(FsItem item) {
    final selected = _selected.contains(item.path);
    return Card(
      color: selected ? _selectionSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(
          color: selected ? _blue : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => _open(item),
        onLongPress: () => _longPress(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ItemPreview(item: item, size: 55),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    SizedBox(
                      width: 36,
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) => _toggle(item),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              if (_mode == BrowseMode.type)
                Text(
                  _shortPath(item.path),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _secondaryText, fontSize: 9.5),
                ),
              Text(
                item.directory
                    ? 'Folder'
                    : '${item.kind} · ${_formatSize(item.size)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _secondaryText, fontSize: 10.5),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 23,
                  child: IconButton(
                    tooltip: 'More options',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _itemActions(item),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 19,
                      color: _secondaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortPath(String path) =>
      path.length <= 50 ? path : '...${path.substring(path.length - 47)}';
}

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({required this.item, required this.size});
  final FsItem item;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = item.directory
        ? const Color(0xFFF0AB34)
        : item.isImage
        ? const Color(0xFF9A62DB)
        : item.isVideo
        ? const Color(0xFFDF5D73)
        : _blue;
    final icon = item.directory
        ? Icons.folder_rounded
        : item.isImage
        ? Icons.image_rounded
        : item.isVideo
        ? Icons.movie_rounded
        : item.mime.startsWith('audio/')
        ? Icons.music_note_rounded
        : item.mime.contains('pdf')
        ? Icons.picture_as_pdf_rounded
        : Icons.insert_drive_file_rounded;
    Widget image = const SizedBox.shrink();
    if (!item.directory && item.isImage) {
      image = Image.file(
        File(item.path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 144,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    if (!item.directory && item.isVideo) {
      image = _VideoThumb(path: item.path, size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: color.withValues(alpha: .10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Icon(icon, color: color, size: size * .53),
            image,
            if (item.isVideo)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumb extends StatefulWidget {
  const _VideoThumb({required this.path, required this.size});
  final String path;
  final double size;
  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late Future<Uint8List?> _future;
  @override
  void initState() {
    super.initState();
    _future = _native<Uint8List>('thumbnail', {'path': widget.path});
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _future,
    builder: (context, snapshot) => snapshot.data == null
        ? const SizedBox.shrink()
        : Image.memory(
            snapshot.data!,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
          ),
  );
}

class ImagePreview extends StatelessWidget {
  const ImagePreview({super.key, required this.item});
  final FsItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF111827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      foregroundColor: Colors.white,
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.file(
          File(item.path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text(
            'This image cannot be previewed',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

class DestinationPage extends StatefulWidget {
  const DestinationPage({
    super.key,
    required this.initialRoot,
    required this.roots,
  });
  final StorageRoot initialRoot;
  final List<StorageRoot> roots;
  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  late StorageRoot _root = widget.initialRoot;
  final List<String> _paths = [];
  final List<String> _names = [];
  List<FsItem> _folders = [];
  bool _busy = true;
  String get _parent => _paths.isEmpty ? _root.path : _paths.last;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final values =
          await _native<List<Object?>>('list', {'path': _parent}) ?? [];
      if (mounted) {
        setState(() {
          _folders = values
              .map(
                (value) =>
                    FsItem.fromMap(Map<Object?, Object?>.from(value as Map)),
              )
              .where((item) => item.directory)
              .toList();
          _busy = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _message(error.message ?? 'Could not read this folder');
      }
    }
  }

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _native<String>('createFolder', {'parent': _parent, 'name': name});
      await _load();
    } on PlatformException catch (error) {
      _message(error.message ?? 'Could not create folder');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Choose destination'),
      actions: [
        if (widget.roots.length > 1)
          PopupMenuButton<StorageRoot>(
            tooltip: 'Change destination storage',
            onSelected: (root) {
              setState(() {
                _root = root;
                _paths.clear();
                _names.clear();
              });
              _load();
            },
            itemBuilder: (context) => widget.roots
                .map(
                  (root) => PopupMenuItem(
                    value: root,
                    child: Text(_sourceName(root.kind)),
                  ),
                )
                .toList(),
            icon: const Icon(Icons.storage_rounded),
          ),
        IconButton(
          tooltip: 'New folder',
          onPressed: _busy ? null : _newFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                ActionChip(
                  label: Text(_sourceName(_root.kind)),
                  onPressed: () {
                    setState(() {
                      _paths.clear();
                      _names.clear();
                    });
                    _load();
                  },
                ),
                for (var i = 0; i < _names.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: ActionChip(
                      label: Text(_names[i]),
                      onPressed: () {
                        setState(() {
                          final keep = i + 1;
                          _paths.removeRange(keep, _paths.length);
                          _names.removeRange(keep, _names.length);
                        });
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : _folders.isEmpty
              ? const Center(child: Text('No folders in this location'))
              : ListView(
                  children: [
                    for (final folder in _folders)
                      ListTile(
                        leading: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFFF0AB34),
                        ),
                        title: Text(folder.name),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          setState(() {
                            _paths.add(folder.path);
                            _names.add(folder.name);
                          });
                          _load();
                        },
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _parent),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  'Use this folder${_names.isEmpty ? '' : ': ${_names.last}'}',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyFiles extends StatelessWidget {
  const _EmptyFiles({required this.searching});
  final bool searching;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          searching ? Icons.search_off_rounded : Icons.folder_open_rounded,
          size: 51,
          color: const Color(0xFFADB7C7),
        ),
        const SizedBox(height: 11),
        Text(
          searching ? 'No matching files' : 'This folder is empty',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

String _sourceName(String kind) => switch (kind) {
  'otg' => 'OTG Drive',
  'sd' => 'SD Card',
  _ => 'Internal Storage',
};
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
