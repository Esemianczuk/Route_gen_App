import 'dart:ui';

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
const _bikeAccent = Color(0xFF4CDCA4);
const _runAccent = Color(0xFFC6A0FF);
const _bikeLabelGlow = Color(0xF2E0FCF0);
const _runLabelGlow = Color(0xFFF4EBFF);

class RouteGenApp extends StatelessWidget {
  const RouteGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Gen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: _sherpaBg,
        canvasColor: _sherpaBg,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
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

class _HelloScreenState extends State<HelloScreen> {
  int _selectedToolIndex = 3;
  int _focusedActionIndex = -1;
  bool _isBikeMode = true;
  double _preferredMiles = 20;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final statusScrimHeight = topInset + 10;
    final baseTheme = Theme.of(context);
    final accentColor = _isBikeMode ? _bikeAccent : _runAccent;
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
                  padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                  child: Container(
                    key: const ValueKey('actions-toolbar'),
                    constraints: const BoxConstraints(minWidth: 36, maxWidth: 40),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _sherpaBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Tooltip(
                        message: _isBikeMode ? 'Switch to running' : 'Switch to biking',
                        child: IconButton.filled(
                          key: const ValueKey('mode-toggle-button'),
                          style: compactButtonStyle,
                          onPressed: () {
                            setState(() {
                              _isBikeMode = !_isBikeMode;
                            });
                          },
                          icon: Icon(
                            _isBikeMode
                                ? Icons.directions_bike
                                : Icons.directions_run,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Search routes or places',
                        child: IconButton.filledTonal(
                          key: const ValueKey('open-search-button'),
                          style: compactButtonStyle,
                          onPressed: _openSearchSheet,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Preferred distance',
                        child: _DistanceBadge(
                          miles: _preferredMiles,
                          accentColor: accentColor,
                          onTap: () => _openDistanceSheet(),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            child: IconButton.filledTonal(
                              key: const ValueKey('layer-menu-button'),
                              style: compactButtonStyle,
                              onPressed: () {
                                controller.isOpen
                                    ? controller.close()
                                    : controller.open();
                              },
                              icon: const Icon(Icons.layers_outlined),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: themedData.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Undo last change',
                        child: IconButton.filled(
                          key: const ValueKey('undo-button'),
                          style: compactButtonStyle,
                          onPressed: () {
                            // TODO: hook up undo stack
                          },
                          icon: const Icon(Icons.undo),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Redo change',
                        child: IconButton.filled(
                          key: const ValueKey('redo-button'),
                          style: compactButtonStyle,
                          onPressed: () {
                            // TODO: hook up redo stack
                          },
                          icon: const Icon(Icons.redo),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Clear current route',
                        child: IconButton.filledTonal(
                          key: const ValueKey('clear-button'),
                          style: compactButtonStyle,
                          onPressed: () {
                            // TODO: implement clear route
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message: 'Download route data',
                        child: IconButton.filledTonal(
                          key: const ValueKey('download-button'),
                          style: compactButtonStyle,
                          onPressed: () {
                            // TODO: implement download
                          },
                          icon: const Icon(Icons.download),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 52,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: states.contains(WidgetState.selected)
                    ? ( _isBikeMode ? _bikeLabelGlow : _runLabelGlow )
                    : themedData.colorScheme.onSurfaceVariant,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? ( _isBikeMode ? _bikeLabelGlow : _runLabelGlow )
                    : themedData.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              color: _sherpaBg,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 2 + mediaQuery.padding.bottom,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
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
                      blurRadius: 60,
                      offset: Offset(0, 28),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    indicatorShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    selectedIndex: _selectedToolIndex,
                    onDestinationSelected: (index) {
                      if (index == 3) {
                        setState(() => _focusedActionIndex = 3);
                        _openProfileSheet();
                      } else {
                        setState(() => _focusedActionIndex = index);
                        if (index == 4) {
                          // TODO: Download action
                        }
                      }
                    },
                    destinations: [
                      NavigationDestination(
                        icon: _ZoneNavChip(active: _focusedActionIndex == 0),
                        selectedIcon: _ZoneNavChip(active: true),
                        label: 'Zone',
                      ),
                      NavigationDestination(
                        icon: _AvoidNavChip(active: _focusedActionIndex == 1),
                        selectedIcon: _AvoidNavChip(active: true),
                        label: 'Avoid',
                      ),
                      NavigationDestination(
                        icon: _GenerateNavChip(active: _focusedActionIndex == 2),
                        selectedIcon: _GenerateNavChip(active: true),
                        label: 'Generate',
                      ),
                      NavigationDestination(
                        icon: _DownloadNavChip(
                          active: _focusedActionIndex == 3,
                          icon: Icons.tune,
                        ),
                        selectedIcon: _DownloadNavChip(
                          active: true,
                          icon: Icons.tune,
                        ),
                        label: 'Profile',
                      ),
                      NavigationDestination(
                        icon: _DownloadNavChip(active: _focusedActionIndex == 4),
                        selectedIcon: _DownloadNavChip(active: true),
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
    final accentColor = _isBikeMode
        ? const Color(0xFF70E0A0)
        : Theme.of(context).colorScheme.primary;
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
                              selected: {routeMode},
                              onSelectionChanged: (value) =>
                                  setSheetState(() => routeMode = value.first),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (routeMode == 1) ...[
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
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

class _AvoidNavChip extends StatelessWidget {
  const _AvoidNavChip({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = active
        ? const [
            Color.fromRGBO(240, 108, 136, 0.98),
            Color.fromRGBO(160, 24, 48, 0.96),
          ]
        : const [
            Color.fromRGBO(214, 58, 88, 0.96),
            Color.fromRGBO(124, 12, 32, 0.92),
          ];
    return SizedBox(
      width: 64,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors
                        .map(
                          (c) => c.withValues(alpha: active ? 0.38 : 0.3),
                        )
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.block,
                color: Colors.white.withValues(alpha: 0.92),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneNavChip extends StatelessWidget {
  const _ZoneNavChip({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = active
        ? const [
            Color.fromRGBO(136, 178, 255, 0.95),
            Color.fromRGBO(62, 102, 215, 0.92),
          ]
        : const [
            Color.fromRGBO(112, 154, 255, 0.9),
            Color.fromRGBO(52, 82, 200, 0.88),
          ];
    return SizedBox(
      width: 64,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors
                        .map(
                          (c) => c.withValues(alpha: active ? 0.4 : 0.28),
                        )
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.9,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),
            const Center(
              child: _ActivityZoneIcon(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateNavChip extends StatelessWidget {
  const _GenerateNavChip({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = active
        ? const [
            Color.fromRGBO(96, 235, 180, 0.95),
            Color.fromRGBO(60, 200, 150, 0.92),
          ]
        : const [
            Color.fromRGBO(76, 220, 164, 0.9),
            Color.fromRGBO(28, 140, 102, 0.85),
          ];
    return SizedBox(
      width: 64,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors
                        .map(
                          (c) => c.withValues(alpha: active ? 0.4 : 0.28),
                        )
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.0,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.17),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.auto_mode,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadNavChip extends StatelessWidget {
  const _DownloadNavChip({
    this.active = false,
    this.icon = Icons.download,
  });

  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = active
        ? const [
            Color.fromRGBO(136, 178, 255, 0.95),
            Color.fromRGBO(62, 102, 215, 0.92),
          ]
        : const [
            Color.fromRGBO(112, 154, 255, 0.9),
            Color.fromRGBO(52, 82, 200, 0.88),
          ];
    return SizedBox(
      width: 64,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors
                        .map(
                          (c) => c.withValues(alpha: active ? 0.4 : 0.28),
                        )
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.9,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.92),
                size: 18,
              ),
            ),
          ],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.9),
            theme.colorScheme.surfaceVariant.withValues(alpha: 0.7),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 12),
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

class _ActivityZoneIcon extends StatelessWidget {
  const _ActivityZoneIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _ActivityZonePainter(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _ActivityZonePainter extends CustomPainter {
  const _ActivityZonePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(stroke, stroke, size.width - 2 * stroke,
          size.height - 2 * stroke),
      Radius.circular(size.width * 0.18),
    );
    canvas.drawRRect(outer, paint);

    paint.style = PaintingStyle.fill;
    final circleRadius = size.width * 0.09;
    final positions = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.8),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, circleRadius, paint);
    }

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.32, size.height * 0.32,
          size.width * 0.36, size.height * 0.36),
      Radius.circular(size.width * 0.12),
    );
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawRRect(inner, paint);
  }

  @override
  bool shouldRepaint(_ActivityZonePainter oldDelegate) =>
      oldDelegate.color != color;
}
        int routeMode = 0;
