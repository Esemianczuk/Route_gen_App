import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const RouteGenApp());
}

/// Top-level widget that hosts the simple single-page experience for now.
const _sherpaBg = Color(0xFF101218);
const _bikeAccent = Color(0xFF2BD88D);
const _runAccent = Color(0xFF5D8EFF);
const _bikeLabelGlow = Color(0xFFE0FFF4);
const _runLabelGlow = Color(0xFFDFE6FF);
const _neonButtonFg = Color(0xFF041C11);
const _clearButtonBase = Color(0xFF8C1D3A);
const _clearButtonIcon = Color(0xFFFFC3D2);
const _historyButtonBase = Color(0xFF143555);
const _historyButtonIcon = Color(0xFFC3D8FF);
const _demoElevationProfile = <double>[
  0.2,
  0.32,
  0.18,
  0.58,
  0.44,
  0.75,
  0.62,
  0.86,
  0.51,
  0.68,
  0.42,
  0.3,
];
const BorderRadius _chromeBorderRadius = BorderRadius.all(Radius.circular(18));
const _chromePanelBg = Color(0xFF0E1726);
const _chromePanelGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xC40A101C),
    Color(0xC40D3450),
    Color(0xC40A101C),
  ],
  stops: [0.0, 0.5, 1.0],
);
const _navEdgeFadeGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Colors.transparent,
    Colors.white,
    Colors.white,
    Colors.transparent,
  ],
  stops: [0.0, 0.07, 0.93, 1.0],
);
const _elevatedShadow = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 40,
    spreadRadius: 2,
    offset: Offset(0, 24),
  ),
  BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 12,
    offset: Offset(0, 8),
  ),
];
const _navEdgeBase = Color(0xFF0A101C);
const _navCenterBase = Color(0xFF0D3450);

class RouteGenApp extends StatelessWidget {
  const RouteGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Gen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _bikeAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: _sherpaBg,
        canvasColor: _sherpaBg,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _bikeAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _sherpaBg,
        canvasColor: _sherpaBg,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const HelloScreen(),
    );
  }
}

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen>
    with TickerProviderStateMixin {
  int _selectedToolIndex = 2;
  bool _isBikeMode = true;
  double _preferredMiles = 20;
  int _routeMode = 0;
  final MenuController _layerMenuController = MenuController();
  final List<String> _layerOptions = const [
    'Leaflet Streets',
    'Satellite View',
    'Iso Lines',
    'Minimal Light',
  ];
  final SearchController _searchController = SearchController();
  final List<String> _searchSuggestions = const [
    'Golden Gate Bridge',
    'Presidio Ride',
    'Mission Coffee Loop',
    'Beach Boardwalk',
  ];
  late final AnimationController _navPulseController;
  double _navPulseValue = 0.5;

  @override
  void initState() {
    super.initState();
    _navPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() {
        setState(() {
          final wave = math.sin(_navPulseController.value * 2 * math.pi);
          _navPulseValue = (wave + 1) / 2;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _navPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final statusScrimHeight = topInset + 10;
    final baseTheme = Theme.of(context);
    final accentColor = _isBikeMode ? _bikeAccent : _runAccent;
    final isGenerateSelected = _selectedToolIndex == 2;
    final navGradient = _navGradientForPulse(_navPulseValue);
    final modeColorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
    );
    final themedData = baseTheme.copyWith(
      colorScheme: modeColorScheme,
      scaffoldBackgroundColor: _sherpaBg,
      canvasColor: _sherpaBg,
    );
    final compactButtonStyle = IconButton.styleFrom(
      padding: const EdgeInsets.all(6),
      minimumSize: const Size(30, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      iconSize: 18,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
    final neonIconStyle = compactButtonStyle.copyWith(
      backgroundColor: WidgetStatePropertyAll(accentColor),
      foregroundColor: const WidgetStatePropertyAll(_neonButtonFg),
    );

    return Theme(
      data: themedData,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(37.7749, -122.4194), // San Francisco for now
                initialZoom: 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.route_gen_app',
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: statusScrimHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(18, 26, 42, 0.95),
                        Color.fromRGBO(20, 28, 44, 0.75),
                        Color.fromRGBO(18, 32, 34, 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                  child: ConstrainedBox(
                    key: const ValueKey('actions-toolbar'),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      maxWidth: 60,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Preferred distance',
                            child: _ToolbarButtonFrame(
                              child: _DistanceBadge(
                                miles: _preferredMiles,
                                accentColor: accentColor,
                                onTap: () => _openDistanceSheet(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Tooltip(
                            message: _isBikeMode ? 'Switch to running' : 'Switch to biking',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      _isBikeMode = !_isBikeMode;
                                    });
                                  },
                                  child: Container(
                                    key: const ValueKey('mode-toggle-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isBikeMode ? Icons.directions_bike : Icons.directions_run,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Tooltip(
                            message: 'Search routes or places',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _openSearchSheet,
                                  child: Container(
                                    key: const ValueKey('open-search-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.4),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          MenuAnchor(
                            controller: _layerMenuController,
                            alignmentOffset: const Offset(-12, 8),
                            menuChildren: _layerOptions
                                .map(
                                  (layer) => MenuItemButton(
                                    onPressed: () => _layerMenuController.close(),
                                    child: Text(layer),
                                  ),
                                )
                                .toList(),
                            builder: (context, controller, child) {
                              return Tooltip(
                                message: 'Layer controls',
                                child: _ToolbarButtonFrame(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        controller.isOpen ? controller.close() : controller.open();
                                      },
                                      child: Container(
                                        key: const ValueKey('layer-menu-button'),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: accentColor.withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentColor.withValues(alpha: 0.18),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.layers_outlined, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Tooltip(
                            message: 'Undo last change',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // TODO: hook up undo stack
                                  },
                                  child: Container(
                                    key: const ValueKey('undo-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _historyButtonBase.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _historyButtonBase.withValues(alpha: 0.38),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _historyButtonBase.withValues(alpha: 0.24),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.undo,
                                      size: 18,
                                      color: _historyButtonIcon,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Tooltip(
                            message: 'Redo change',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // TODO: hook up redo stack
                                  },
                                  child: Container(
                                    key: const ValueKey('redo-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _historyButtonBase.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _historyButtonBase.withValues(alpha: 0.38),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _historyButtonBase.withValues(alpha: 0.24),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.redo,
                                      size: 18,
                                      color: _historyButtonIcon,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Tooltip(
                            message: 'Clear current route',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // TODO: implement clear route
                                  },
                                  child: Container(
                                    key: const ValueKey('clear-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _clearButtonBase.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _clearButtonBase.withValues(alpha: 0.38),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _clearButtonBase.withValues(alpha: 0.22),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: _clearButtonIcon,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Tooltip(
                            message: 'Toolbar settings',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // TODO: open toolbar settings
                                  },
                                  child: Container(
                                    key: const ValueKey('settings-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.settings, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Tooltip(
                            message: 'View analytics',
                            child: _ToolbarButtonFrame(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _openAnalyticsSheet,
                                  child: Container(
                                    key: const ValueKey('stats-button'),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.query_stats, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: navGradient,
                borderRadius: _chromeBorderRadius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                boxShadow: _elevatedShadow,
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) =>
                    _navEdgeFadeGradient.createShader(bounds),
                blendMode: ui.BlendMode.dstIn,
                child: ClipRRect(
                  borderRadius: _chromeBorderRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: navGradient,
                        borderRadius: _chromeBorderRadius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: _elevatedShadow,
                      ),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          height: 66,
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          indicatorColor: Colors.transparent,
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.pressed)
                                ? accentColor.withValues(alpha: 0.18)
                                : Colors.transparent,
                          ),
                          labelTextStyle:
                              WidgetStateProperty.resolveWith((states) {
                            final selected = states.contains(WidgetState.selected);
                            return TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: selected
                                  ? (isGenerateSelected ? Colors.white : accentColor)
                                  : Colors.white.withValues(alpha: 0.8),
                            );
                          }),
                          iconTheme: WidgetStateProperty.resolveWith(
                            (states) => IconThemeData(
                              color: states.contains(WidgetState.selected)
                                  ? (isGenerateSelected ? Colors.white : accentColor)
                                  : Colors.white.withValues(alpha: 0.78),
                              size: 22,
                            ),
                          ),
                        ),
                        child: NavigationBar(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        selectedIndex: _selectedToolIndex,
                        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                        onDestinationSelected: (index) {
                          if (index == 0) {
                            _openProfileSheet();
                            return;
                          }
                          if (index <= 2) {
                            setState(() => _selectedToolIndex = index);
                            return;
                          }
                          if (index == 3) {
                            setState(() => _selectedToolIndex = index);
                            return;
                          }
                          if (index == 4) {
                            // TODO: Download action
                          }
                        },
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.tune_outlined),
                            selectedIcon: Icon(Icons.tune),
                            label: 'Profile',
                          ),
                          const NavigationDestination(
                            icon: _ToolbarAccentIcon(
                              iconData: Icons.block_outlined,
                              accentColor: _clearButtonBase,
                              iconColor: _clearButtonIcon,
                            ),
                            selectedIcon: _ToolbarAccentIcon(
                              iconData: Icons.block,
                              accentColor: _clearButtonBase,
                              iconColor: _clearButtonIcon,
                            ),
                            label: 'Avoid area',
                          ),
                          NavigationDestination(
                            icon: _ToolbarAccentIcon(
                              iconData: Icons.play_arrow_outlined,
                              accentColor: accentColor,
                            ),
                            selectedIcon: _ToolbarAccentIcon(
                              iconData: Icons.play_arrow,
                              accentColor: accentColor,
                            ),
                            label: 'Generate',
                          ),
                          const NavigationDestination(
                            icon: _ToolbarAccentIcon(
                              iconData: Icons.crop_free,
                              accentColor: Color(0xFF5C2C92),
                              iconColor: Color(0xFFE9D7FF),
                            ),
                            selectedIcon: _ToolbarAccentIcon(
                              iconData: Icons.crop_square,
                              accentColor: Color(0xFF5C2C92),
                              iconColor: Color(0xFFE9D7FF),
                            ),
                            label: 'Route Zone',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.download_outlined),
                            selectedIcon: Icon(Icons.download),
                            label: 'Download',
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on _HelloScreenState {
  Future<void> _openDistanceSheet() async {
    final controller =
        TextEditingController(text: _preferredMiles.toStringAsFixed(1));
    double tentativeMiles = _preferredMiles;
    String? errorText;
    final accentColor = _isBikeMode ? _bikeAccent : _runAccent;
    double? resultMiles;

    resultMiles = await showModalBottomSheet<double>(
      context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          final presets = <String, double>{
            '5 mi': 5,
            '10 mi': 10,
            '13.1 mi': 13.1,
            '26.2 mi': 26.2,
          };

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(Icons.straighten, color: accentColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Preferred distance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tell us how long you want the route to be.',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.flag_rounded),
                        suffixText: 'mi',
                        labelText: 'Distance in miles',
                        filled: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        errorText: errorText,
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        setSheetState(() {
                          if (parsed == null || parsed <= 0) {
                            errorText = 'Enter a positive distance';
                          } else {
                            errorText = null;
                            tentativeMiles = parsed;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: presets.entries
                          .map(
                            (entry) => ChoiceChip(
                              label: Text(entry.key),
                              selected: tentativeMiles == entry.value,
                              onSelected: (_) {
                                setSheetState(() {
                                  tentativeMiles = entry.value;
                                  controller.text = entry.value % 1 == 0
                                      ? entry.value.toStringAsFixed(0)
                                      : entry.value.toStringAsFixed(1);
                                  errorText = null;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            final parsed =
                                double.tryParse(controller.text.trim());
                            if (parsed == null || parsed <= 0) {
                              setSheetState(
                                () => errorText = 'Enter a positive distance',
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop(parsed);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    if (!mounted || resultMiles == null) return;
    setState(() => _preferredMiles = resultMiles!);
  }

  void _openSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchBar(
                key: const ValueKey('map-search-bar'),
                controller: _searchController,
                hintText: 'Search routes or places',
                onSubmitted: (_) => Navigator.of(sheetContext).pop(),
                leading: const Icon(Icons.search),
                trailing: const [Icon(Icons.mic_none)],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  children: _searchSuggestions
                      .map(
                        (suggestion) => ListTile(
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openProfileSheet() {
    final accentColor = _isBikeMode ? _bikeAccent : _runAccent;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        double lengthWeight = 1.50;
        double overlapPenalty = 1.20;
        double backtrackPenalty = 1.08;
        double elevationBias = 0.0;
        bool closeLoop = true;
        bool mapAddsStops = true;
        final int stopsCount = 0;
        double steepBias = 0.0;
        double routeCurvyBias = 0.0;
        double surfaceBias = 0.0;
        double roadPathBias = 0.0;
        double turnBias = 0.05;
        double flowWeight = 1.91;
        double trafficWeight = 0.0;
        final baseTheme = Theme.of(sheetContext);
        final sheetTheme = baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: accentColor,
            primaryContainer: accentColor.withValues(alpha: 0.2),
            secondary: accentColor,
          ),
          sliderTheme: SliderTheme.of(sheetContext).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.3),
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.12),
          ),
        );

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Theme(
                  data: sheetTheme,
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetTheme.colorScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: sheetTheme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                  value: 0,
                                  label: Text('Loop mode'),
                                  icon: Icon(Icons.loop),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text('Multi-point mode'),
                                  icon: Icon(Icons.route),
                                ),
                              ],
                              selected: {_routeMode},
                              onSelectionChanged: (value) {
                                final newMode = value.first;
                                setSheetState(() => _routeMode = newMode);
                                setState(() => _routeMode = newMode);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_routeMode == 1) ...[
                            _MultiRoutePanel(
                              closeLoop: closeLoop,
                              mapAddsStops: mapAddsStops,
                              stopsCount: stopsCount,
                              onCloseLoopChanged: (value) =>
                                  setSheetState(() => closeLoop = value),
                              onMapAddsStopsChanged: (value) =>
                                  setSheetState(() => mapAddsStops = value),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    sheetTheme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.tune,
                                  color: sheetTheme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Route tuning',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Core weights, tune how the route feels. Hover info icons for tips.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: sheetTheme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    // TODO: persist profile
                                  },
                                  icon: const Icon(Icons.star_outline),
                                  label: const Text('Save profile'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => showModalBottomSheet<void>(
                                    context: sheetContext,
                                    useSafeArea: true,
                                    builder: (ctx) => SizedBox(
                                      height: 320,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            title: const Text('Profiles'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                'No saved profiles yet.',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.folder_shared_outlined),
                                  label: const Text('Profiles'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _DualBiasCard(
                            title: 'Elevation preference',
                            description:
                                'Slide toward hills or flats. Neutral keeps elevation optional.',
                            negativeLabel: 'Prefer flat',
                            positiveLabel: 'Prefer climb',
                            value: elevationBias,
                            min: -3,
                            max: 3,
                            onChanged: (value) =>
                                setSheetState(() => elevationBias = value),
                            onReset: () =>
                                setSheetState(() => elevationBias = 0.0),
                          ),
                          const SizedBox(height: 20),
                          _DualBiasCard(
                            title: 'Steepness preference',
                            description:
                                'Stay flatter or chase steeper grades.',
                            negativeLabel: 'Flatter',
                            positiveLabel: 'Steeper',
                            value: steepBias,
                            min: -3,
                            max: 3,
                            onChanged: (value) =>
                                setSheetState(() => steepBias = value),
                            onReset: () =>
                                setSheetState(() => steepBias = 0.0),
                          ),
                          const SizedBox(height: 20),
                          _DualBiasCard(
                            title: 'Route straight vs curvy',
                            description:
                                'Steer the path between intersections toward direct lines or flowing turns.',
                            negativeLabel: 'Straighter',
                            positiveLabel: 'Curvier',
                            value: routeCurvyBias,
                            min: -3,
                            max: 3,
                            onChanged: (value) => setSheetState(
                              () => routeCurvyBias = value,
                            ),
                            onReset: () =>
                                setSheetState(() => routeCurvyBias = 0.0),
                          ),
                          const SizedBox(height: 20),
                          _DualBiasCard(
                            title: 'Surface preference',
                            description:
                                'Favor smoother pavement or explore unpaved adventures.',
                            negativeLabel: 'Paved',
                            positiveLabel: 'Unpaved',
                            value: surfaceBias,
                            min: -3,
                            max: 3,
                            onChanged: (value) =>
                                setSheetState(() => surfaceBias = value),
                            onReset: () =>
                                setSheetState(() => surfaceBias = 0.0),
                          ),
                          const SizedBox(height: 20),
                          _DualBiasCard(
                            title: 'Road vs path preference',
                            description:
                                'Favor dedicated paths or stay with roads.',
                            negativeLabel: 'Road focus',
                            positiveLabel: 'Path focus',
                            value: roadPathBias,
                            min: -3,
                            max: 3,
                            onChanged: (value) =>
                                setSheetState(() => roadPathBias = value),
                            onReset: () =>
                                setSheetState(() => roadPathBias = 0.0),
                          ),
                          const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color.fromRGBO(134, 176, 255, 0.26),
                                width: 1,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromRGBO(18, 26, 42, 0.92),
                                Color.fromRGBO(20, 28, 44, 0.92),
                                Color.fromRGBO(18, 32, 34, 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.42),
                                blurRadius: 40,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Overlap penalty',
                                    description:
                                        'Discourages reusing the same segments.',
                                    value: overlapPenalty,
                                    min: 0,
                                    max: 3,
                                    onReset: () => setSheetState(
                                      () => overlapPenalty = 1.20,
                                    ),
                                    onChanged: (value) => setSheetState(
                                      () => overlapPenalty = value,
                                    ),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Backtrack penalty',
                                    description:
                                        'Avoids U-turns and retracing steps.',
                                    value: backtrackPenalty,
                                    min: 0,
                                    max: 3,
                                    onReset: () => setSheetState(
                                      () => backtrackPenalty = 1.08,
                                    ),
                                    onChanged: (value) => setSheetState(
                                      () => backtrackPenalty = value,
                                    ),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color.fromRGBO(134, 176, 255, 0.26),
                                width: 1,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromRGBO(18, 26, 42, 0.92),
                                Color.fromRGBO(20, 28, 44, 0.92),
                                Color.fromRGBO(18, 32, 34, 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.42),
                                blurRadius: 40,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Right-turn bias',
                                    description:
                                        'Encourages or ignores right-hand bias. 0 = ignore.',
                                    value: turnBias,
                                    min: 0,
                                    max: 3,
                                    onReset: () =>
                                        setSheetState(() => turnBias = 0.05),
                                    onChanged: (value) =>
                                        setSheetState(() => turnBias = value),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Flow',
                                    description:
                                        'Runs a 3D flow sim to keep curvy, rolling momentum.',
                                    value: flowWeight,
                                    min: 0,
                                    max: 3,
                                    onReset: () =>
                                        setSheetState(() => flowWeight = 1.91),
                                    onChanged: (value) =>
                                        setSheetState(() => flowWeight = value),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color.fromRGBO(134, 176, 255, 0.26),
                                width: 1,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromRGBO(18, 26, 42, 0.92),
                                Color.fromRGBO(20, 28, 44, 0.92),
                                Color.fromRGBO(18, 32, 34, 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.42),
                                blurRadius: 40,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Length weight',
                                    description:
                                        'Keeps the route close to your preferred distance.',
                                    value: lengthWeight,
                                    min: 1.0,
                                    max: 3.0,
                                    onReset: () =>
                                        setSheetState(() => lengthWeight = 1.50),
                                    onChanged: (value) =>
                                        setSheetState(() => lengthWeight = value),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TonalSliderCard(
                                    title: 'Traffic calm weight',
                                    description:
                                        'Prefers quieter roads and calmer streets.',
                                    value: trafficWeight,
                                    min: 0,
                                    max: 3,
                                    onReset: () =>
                                        setSheetState(() => trafficWeight = 0.0),
                                    onChanged: (value) =>
                                        setSheetState(() => trafficWeight = value),
                                    showDescription: false,
                                    titleFontSize: 14,
                                    valueFontSize: 13,
                                    wrapInCard: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openAnalyticsSheet() {
    final accentColor = _isBikeMode ? _bikeAccent : _runAccent;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Container(
            decoration: BoxDecoration(
              color: _sherpaBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accentColor.withValues(alpha: 0.16),
                        child: Icon(Icons.query_stats, color: accentColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Elevation graph',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Preview gradients, peaks, and descents for this route.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 24),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _chromePanelBg,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Elevation graph placeholder',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _navGradientForPulse(double pulse) {
    final edgeStart =
        Color.lerp(_navEdgeBase.withOpacity(0.75), _navEdgeBase.withOpacity(0.4), pulse)!;
    final center =
        Color.lerp(_navCenterBase.withOpacity(0.95), _navCenterBase.withOpacity(0.6), pulse)!;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [edgeStart, center, edgeStart],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}

class _TonalSliderCard extends StatefulWidget {
  const _TonalSliderCard({
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.onReset,
    required this.onChanged,
    this.showDescription = true,
    this.titleFontSize,
    this.valueFontSize,
    this.wrapInCard = true,
  });

  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final VoidCallback onReset;
  final ValueChanged<double> onChanged;
  final bool showDescription;
  final double? titleFontSize;
  final double? valueFontSize;
  final bool wrapInCard;

  @override
  State<_TonalSliderCard> createState() => _TonalSliderCardState();
}

class _TonalSliderCardState extends State<_TonalSliderCard> {
  late double _currentValue = widget.value;

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: widget.titleFontSize ?? 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _currentValue.toStringAsFixed(2),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      fontSize: widget.valueFontSize ?? 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Reset to default',
                    onPressed: () {
                      widget.onReset();
                      setState(() => _currentValue = widget.value);
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            if (widget.showDescription && widget.description.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (context) {
                  final sliderExtraWidth = widget.wrapInCard ? 0.0 : 12.0;
                  Widget slider = SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 4,
                      activeTrackColor:
                          Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.95,
                      ),
                      inactiveTrackColor:
                          Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                      thumbColor: Theme.of(context).colorScheme.primary,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 18,
                      ),
                      overlayColor:
                          Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      tickMarkShape: const RoundSliderTickMarkShape(),
                      valueIndicatorShape:
                          const PaddleSliderValueIndicatorShape(),
                      valueIndicatorColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth + sliderExtraWidth,
                      child: Slider(
                        value: _currentValue,
                        min: widget.min,
                        max: widget.max,
                        divisions: ((widget.max - widget.min) * 100).round(),
                        label: _currentValue.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() => _currentValue = value);
                          widget.onChanged(value);
                        },
                      ),
                    ),
                  );
                  if (!widget.wrapInCard) {
                    slider = Transform.translate(
                      offset: Offset(-sliderExtraWidth / 2, 0),
                      child: slider,
                    );
                  }
                  return slider;
                },
              ),
              if (!widget.showDescription && widget.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (!widget.wrapInCard) {
      return content;
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: content,
    );
  }
}

class _DualBiasCard extends StatelessWidget {
  const _DualBiasCard({
    required this.title,
    required this.description,
    required this.negativeLabel,
    required this.positiveLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onReset,
  });

  final String title;
  final String description;
  final String negativeLabel;
  final String positiveLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final subtle = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final label = _formatBiasLabel(value, negativeLabel, positiveLabel);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        border: Border.fromBorderSide(
          BorderSide(
            color: Color.fromRGBO(134, 176, 255, 0.26),
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(18, 26, 42, 0.92),
            Color.fromRGBO(20, 28, 44, 0.92),
            Color.fromRGBO(18, 32, 34, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.42),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reset to neutral',
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    SizedBox(
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DualTrackPainter(
                                value: value,
                                min: min,
                                max: max,
                                baseColor: Colors.white.withValues(alpha: 0.12),
                                positiveColor: accent,
                                negativeColor: Color.lerp(
                                      accent,
                                      Colors.blueAccent,
                                      0.55,
                                    ) ??
                                    accent,
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackShape: const RectangularSliderTrackShape(),
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 11,
                              ),
                              thumbColor: accent,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20,
                              ),
                              overlayColor: accent.withValues(alpha: 0.14),
                              showValueIndicator: ShowValueIndicator.never,
                            ),
                            child: Slider(
                              value: value,
                              min: min,
                              max: max,
                              divisions: ((max - min) / 0.05).round(),
                              onChanged: onChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          negativeLabel,
                          style: TextStyle(color: subtle, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          'Neutral',
                          style: TextStyle(color: subtle, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          positiveLabel,
                          style: TextStyle(color: subtle, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBiasLabel(
    double value,
    String negative,
    String positive,
  ) {
    if (value.abs() < 0.01) {
      return 'Neutral';
    }
    final formatted = value.abs().toStringAsFixed(2);
    return value > 0 ? '$positive $formatted' : '$negative $formatted';
  }
}

class _DualTrackPainter extends CustomPainter {
  const _DualTrackPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.baseColor,
    required this.positiveColor,
    required this.negativeColor,
  });

  final double value;
  final double min;
  final double max;
  final Color baseColor;
  final Color positiveColor;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, centerY),
        width: size.width,
        height: 6,
      ),
      const Radius.circular(12),
    );
    final basePaint = Paint()..color = baseColor;
    canvas.drawRRect(baseRect, basePaint);

    final zeroX = ((0 - min) / (max - min)) * size.width;
    final valueX = ((value - min) / (max - min)) * size.width;
    final height = 6.0;

    if (value > 0) {
      final rect = Rect.fromLTWH(
        zeroX,
        centerY - height / 2,
        (valueX - zeroX).clamp(0, size.width),
        height,
      );
      if (rect.width > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          Paint()..color = positiveColor,
        );
      }
    } else if (value < 0) {
      final rect = Rect.fromLTWH(
        valueX,
        centerY - height / 2,
        (zeroX - valueX).clamp(0, size.width),
        height,
      );
      if (rect.width > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          Paint()..color = negativeColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DualTrackPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.positiveColor != positiveColor ||
        oldDelegate.negativeColor != negativeColor;
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({
    required this.miles,
    required this.accentColor,
    required this.onTap,
  });

  final double miles;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.onSurfaceVariant;
    final formattedMiles =
        miles % 1 == 0 ? miles.toStringAsFixed(0) : miles.toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedMiles,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'mi',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiRoutePanel extends StatelessWidget {
  const _MultiRoutePanel({
    required this.closeLoop,
    required this.mapAddsStops,
    required this.stopsCount,
    required this.onCloseLoopChanged,
    required this.onMapAddsStopsChanged,
  });

  final bool closeLoop;
  final bool mapAddsStops;
  final int stopsCount;
  final ValueChanged<bool> onCloseLoopChanged;
  final ValueChanged<bool> onMapAddsStopsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(18, 26, 42, 0.92),
            Color.fromRGBO(20, 28, 44, 0.92),
            Color.fromRGBO(18, 32, 34, 0.9),
          ],
        ),
        border: Border.all(
          color: const Color.fromRGBO(134, 176, 255, 0.26),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.42),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-stop routing',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build checkpoint tours',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toggle map clicks, auto-closing loops, and manage saved stops without leaving the planner.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('View guide'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {},
                child: const Text('Add stop at center'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                ),
                onPressed: () {},
                child: const Text('Clear stops'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _MultiToggleTile(
                title: 'Close loop automatically',
                subtitle: 'Finish where you started',
                value: closeLoop,
                onChanged: onCloseLoopChanged,
              ),
              const SizedBox(height: 12),
              _MultiToggleTile(
                title: 'Map click adds stops',
                subtitle: 'Drop checkpoints directly on the map',
                value: mapAddsStops,
                onChanged: onMapAddsStopsChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () {},
                child: Text(stopsCount > 0
                    ? 'Manage stops ($stopsCount)'
                    : 'Manage stops'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stopsCount == 0
                      ? 'No stops yet. Enable “map click adds stops” or use “Add stop at center.”'
                      : '',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarAccentIcon extends StatelessWidget {
  const _ToolbarAccentIcon({
    required this.iconData,
    required this.accentColor,
    this.iconColor,
  });

  final IconData iconData;
  final Color accentColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? IconTheme.of(context).color;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 18,
        color: effectiveIconColor,
      ),
    );
  }
}

class _ToolbarButtonFrame extends StatelessWidget {
  const _ToolbarButtonFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(12));
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _chromePanelGradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: _elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElevationSparklinePainter extends CustomPainter {
  const _ElevationSparklinePainter(this.points, this.color);

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final linePath = ui.Path();
    final dx = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final clamped = points[i].clamp(0.0, 1.0);
      final x = i * dx;
      final y = size.height - (clamped * (size.height * 0.85));
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    final fillPath = ui.Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = ui.Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = ui.Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ElevationSparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _MultiToggleTile extends StatelessWidget {
  const _MultiToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
