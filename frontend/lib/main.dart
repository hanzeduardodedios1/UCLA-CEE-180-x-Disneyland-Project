import 'package:flutter/material.dart';

import 'config.dart';
import 'models/hotel.dart';
import 'models/route.dart';
import 'services/api.dart';
import 'theme/app_theme.dart';
import 'widgets/hotel_route_map.dart';
import 'widgets/hotel_search_field.dart';

void main() {
  runApp(const DisneylandHotelsApp());
}

class DisneylandHotelsApp extends StatelessWidget {
  const DisneylandHotelsApp({super.key, this.api});

  /// Optional override for widget tests.
  final HotelApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disneyland Hotel Compare',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HotelSearchPage(api: api),
    );
  }
}

class HotelSearchPage extends StatefulWidget {
  const HotelSearchPage({super.key, this.api});

  /// Optional override for widget tests.
  final HotelApi? api;

  @override
  State<HotelSearchPage> createState() => _HotelSearchPageState();
}

class _HotelSearchPageState extends State<HotelSearchPage> {
  static const _maxCompare = 2;

  static const _quickPicks = [
    _QuickPick('Disneyland Hotel', 'Disneyland Hotel', 'Disney', Icons.castle, Color(0xFF7C3AED)),
    _QuickPick('Park Vue Inn', 'Park Vue Inn', 'Park Vue', Icons.nightlight_round, Color(0xFF2563EB)),
    _QuickPick('Clarion Hotel Anaheim', 'Clarion Hotel', 'Clarion', Icons.savings, Color(0xFFD97706)),
    _QuickPick("Disney's Grand Californian Hotel", 'Grand Californian', 'Grand Cal', Icons.star, Color(0xFF059669)),
  ];

  static const _sidebarCategories = [
    _SidebarItem('All hotels', Icons.grid_view_rounded),
    _SidebarItem('Disney properties', Icons.castle_outlined),
    _SidebarItem('Budget picks', Icons.savings_outlined),
    _SidebarItem('Walk-friendly', Icons.directions_walk_outlined),
  ];

  late final HotelApi _api = widget.api ?? HotelApi();
  int _navIndex = 0;
  int _categoryIndex = 0;

  List<String> _hotelNames = [];
  final List<HotelRow> _comparison = [];
  final Set<String> _routeVisibleHotels = {};
  final Map<String, HotelRoute> _routes = {};
  final Map<String, bool> _routeLoading = {};
  final Map<String, String> _routeErrors = {};
  String? _error;
  bool _loadingNames = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final names = await _api.fetchHotelNames();
      if (!mounted) return;
      setState(() {
        _hotelNames = names;
        _loadingNames = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Backend offline. Start: uvicorn main:app --reload';
        _loadingNames = false;
      });
    }
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    if (_comparison.length >= _maxCompare &&
        !_comparison.any((r) => r.hotel == q)) {
      setState(() {
        _error = 'Remove a hotel to add another (max $_maxCompare).';
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final exact = _hotelNames.any((n) => n == q);
      final row = await _api.searchHotel(q, exact: exact);
      if (!mounted) return;
      setState(() {
        _comparison.removeWhere((r) => r.hotel == row.hotel);
        _comparison.add(row);
        if (_comparison.length > _maxCompare) {
          _comparison.removeAt(0);
        }
        _searching = false;
        _error = null;
        if (_comparison.length == _maxCompare) _navIndex = 1;
      });
    } on HotelApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach API at $apiBaseUrl ($e)';
        _searching = false;
      });
    }
  }

  void _removeHotel(String hotelName) {
    setState(() {
      _comparison.removeWhere((r) => r.hotel == hotelName);
      _routeVisibleHotels.remove(hotelName);
      _routes.remove(hotelName);
      _routeLoading.remove(hotelName);
      _routeErrors.remove(hotelName);
      if (_comparison.length < _maxCompare) _error = null;
      if (_comparison.isEmpty) _navIndex = 0;
    });
  }

  Future<void> _displayRoute(String hotelName) async {
    setState(() {
      _routeLoading[hotelName] = true;
      _routeErrors.remove(hotelName);
    });

    try {
      final route = await _api.fetchRoute(hotelName);
      if (!mounted) return;
      setState(() {
        _routes[hotelName] = route;
        _routeVisibleHotels.add(hotelName);
        _routeLoading[hotelName] = false;
      });
    } on HotelApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading[hotelName] = false;
        _routeErrors[hotelName] = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading[hotelName] = false;
        _routeErrors[hotelName] = 'Could not reach API at $apiBaseUrl ($e)';
      });
    }
  }

  bool _isDisneyProperty(String name) =>
      name.toLowerCase().contains('disney');

  List<_QuickPick> get _filteredPicks {
    switch (_categoryIndex) {
      case 1:
        return _quickPicks.where((p) => _isDisneyProperty(p.hotelName)).toList();
      case 2:
        return [_quickPicks[2]];
      case 3:
        return [_quickPicks[1], _quickPicks[2]];
      default:
        return _quickPicks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide) _buildSidebar(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopNav(wide: wide),
                  Expanded(
                    child: _navIndex == 0 ? _buildBrowseTab(wide) : _buildCompareTab(wide),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _comparison.length == _maxCompare
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _navIndex = 1),
              backgroundColor: AppColors.accent,
              elevation: 4,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter hotels…',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          _SidebarNavTile(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            selected: _navIndex == 0,
            onTap: () => setState(() => _navIndex = 0),
          ),
          _SidebarNavTile(
            icon: Icons.compare_arrows_outlined,
            label: 'Compare',
            badge: _comparison.isEmpty ? null : '${_comparison.length}',
            selected: _navIndex == 1,
            onTap: () => setState(() => _navIndex = 1),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ...List.generate(_sidebarCategories.length, (i) {
            final item = _sidebarCategories[i];
            return _SidebarNavTile(
              icon: item.icon,
              label: item.label,
              selected: _categoryIndex == i && _navIndex == 0,
              onTap: () => setState(() {
                _categoryIndex = i;
                _navIndex = 0;
              }),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecor.surfaceCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compare up to 2 hotels',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rates, walk time, and transit savings side by side.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _navIndex = 1),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Open compare', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav({required bool wide}) {
    return Container(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!wide) ...[
                const _LogoMark(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Center(
                  child: _PillNavBar(
                    selectedIndex: _navIndex,
                    compareCount: _comparison.length,
                    onSelected: (i) => setState(() => _navIndex = i),
                  ),
                ),
              ),
              if (_comparison.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_comparison.length}/$_maxCompare',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.help_outline, size: 22, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    if (_loadingNames) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );
    }

    if (_hotelNames.isEmpty) {
      return Text(
        _error ?? 'Could not load hotels',
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HotelSearchField(
          allHotels: _hotelNames,
          searching: _searching,
          onSearch: _search,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          _ErrorBanner(message: _error!),
        ],
      ],
    );
  }

  Widget _buildBrowseTab(bool wide) {
    final padding = EdgeInsets.fromLTRB(wide ? 32 : 20, 20, wide ? 32 : 20, 32);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured hotels',
                      style: TextStyle(
                        fontSize: wide ? 22 : 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick a property below or use search to compare walk & transit.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: wide ? 14 : 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (_filteredPicks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Text(
                    '${_filteredPicks.length} shown',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
            ],
          ),
          SizedBox(height: wide ? 24 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = wide
                  ? (constraints.maxWidth - 32) / 4
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _filteredPicks.map((pick) {
                  final inCompare = _comparison.any((r) => r.hotel == pick.hotelName);
                  return SizedBox(
                    width: cardWidth.clamp(140, 280),
                    child: _FeaturedHotelCard(
                      pick: pick,
                      inCompare: inCompare,
                      onTap: () => _search(pick.hotelName),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_comparison.isNotEmpty) ...[
            SizedBox(height: wide ? 36 : 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: () => setState(() => _navIndex = 1),
                  child: const Text('Full compare →'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._comparison.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompactCompareTile(
                  row: row,
                  onRemove: () => _removeHotel(row.hotel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompareTab(bool wide) {
    final padding = EdgeInsets.fromLTRB(wide ? 32 : 20, 24, wide ? 32 : 20, 32);

    if (_comparison.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.compare_arrows, size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              const Text(
                'No hotels to compare yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add up to 2 hotels from search or featured picks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() => _navIndex = 0),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse hotels'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Compare hotels', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '${_comparison.length}/$_maxCompare selected · ${_comparison.length == _maxCompare ? 'Full comparison ready' : 'Add one more for side-by-side'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (_comparison.length == 2) ...[
            ComparisonSummaryCard(a: _comparison[0], b: _comparison[1]),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 640;
                final cards = [
                  _ComparePlanCard(
                    row: _comparison[0],
                    other: _comparison[1],
                    isPremium: _scoreHotel(_comparison[0], _comparison[1]) >=
                        _scoreHotel(_comparison[1], _comparison[0]),
                    routeVisible: _routeVisibleHotels.contains(_comparison[0].hotel),
                    routeLoading: _routeLoading[_comparison[0].hotel] ?? false,
                    routeError: _routeErrors[_comparison[0].hotel],
                    route: _routes[_comparison[0].hotel],
                    onDisplayRoute: () => _displayRoute(_comparison[0].hotel),
                    onRemove: () => _removeHotel(_comparison[0].hotel),
                  ),
                  _ComparePlanCard(
                    row: _comparison[1],
                    other: _comparison[0],
                    isPremium: _scoreHotel(_comparison[1], _comparison[0]) >
                        _scoreHotel(_comparison[0], _comparison[1]),
                    routeVisible: _routeVisibleHotels.contains(_comparison[1].hotel),
                    routeLoading: _routeLoading[_comparison[1].hotel] ?? false,
                    routeError: _routeErrors[_comparison[1].hotel],
                    route: _routes[_comparison[1].hotel],
                    onDisplayRoute: () => _displayRoute(_comparison[1].hotel),
                    onRemove: () => _removeHotel(_comparison[1].hotel),
                  ),
                ];
                if (sideBySide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[1]),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 16),
                    cards[1],
                  ],
                );
              },
            ),
          ] else
            _ComparePlanCard(
              row: _comparison[0],
              isPremium: false,
              routeVisible: _routeVisibleHotels.contains(_comparison[0].hotel),
              routeLoading: _routeLoading[_comparison[0].hotel] ?? false,
              routeError: _routeErrors[_comparison[0].hotel],
              route: _routes[_comparison[0].hotel],
              onDisplayRoute: () => _displayRoute(_comparison[0].hotel),
              onRemove: () => _removeHotel(_comparison[0].hotel),
            ),
          const SizedBox(height: 16),
          if (_comparison.length < _maxCompare)
            OutlinedButton.icon(
              onPressed: () => setState(() => _navIndex = 0),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add second hotel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  int _scoreHotel(HotelRow a, HotelRow b) {
    var score = 0;
    if (a.nightlyRate <= b.nightlyRate) score++;
    if (a.drivingCost <= b.drivingCost) score++;
    if (a.walkMins <= b.walkMins) score++;
    if (a.transitSavedMins >= b.transitSavedMins) score++;
    return score;
  }
}

class _SidebarItem {
  const _SidebarItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sidebarHover : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.sidebarHover : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'd',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
      ),
    );
  }
}

class _PillNavBar extends StatelessWidget {
  const _PillNavBar({
    required this.selectedIndex,
    required this.compareCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int compareCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillNavItem(
            label: 'Browse',
            icon: Icons.home_outlined,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _PillNavItem(
            label: 'Compare',
            icon: Icons.compare_arrows_outlined,
            selected: selectedIndex == 1,
            badge: compareCount > 0 ? '$compareCount' : null,
            onTap: () => onSelected(1),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => onSelected(1),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Compare now', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPick {
  const _QuickPick(this.hotelName, this.title, this.shortLabel, this.icon, this.brandColor);
  final String hotelName;
  final String title;
  final String shortLabel;
  final IconData icon;
  final Color brandColor;
}

class _FeaturedHotelCard extends StatelessWidget {
  const _FeaturedHotelCard({
    required this.pick,
    required this.inCompare,
    required this.onTap,
  });

  final _QuickPick pick;
  final bool inCompare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecor.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecor.radiusMd),
        child: Ink(
          decoration: AppDecor.surfaceCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 88,
                decoration: BoxDecoration(
                  color: pick.brandColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDecor.radiusMd - 1)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(pick.icon, color: pick.brandColor, size: 26),
                    ),
                    if (inCompare)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('In compare', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOTEL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pick.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add to comparison',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactCompareTile extends StatelessWidget {
  const _CompactCompareTile({required this.row, required this.onRemove});

  final HotelRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.surfaceCard(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.hotel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '\$${row.nightlyRate}/night · ${row.walkMins.toStringAsFixed(1)} min walk',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppDecor.radiusSm),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }
}

class ComparisonSummaryCard extends StatelessWidget {
  const ComparisonSummaryCard({super.key, required this.a, required this.b});
  final HotelRow a;
  final HotelRow b;

  @override
  Widget build(BuildContext context) {
    String winner(bool Function(HotelRow x, HotelRow y) cmp, HotelRow x, HotelRow y) =>
        cmp(x, y) ? _shortName(x.hotel) : _shortName(y.hotel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDecor.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 8,
        children: [
          _trustChip(Icons.savings_outlined, 'Best rate: ${winner((x, y) => x.nightlyRate <= y.nightlyRate, a, b)}'),
          _trustChip(Icons.directions_walk, 'Shortest walk: ${winner((x, y) => x.walkMins <= y.walkMins, a, b)}'),
          _trustChip(Icons.schedule, 'Most transit saved: ${winner((x, y) => x.transitSavedMins >= y.transitSavedMins, a, b)}'),
        ],
      ),
    );
  }

  static String _shortName(String name) {
    if (name.length <= 22) return name;
    return '${name.substring(0, 20)}…';
  }

  Widget _trustChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.mint),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ComparePlanCard extends StatelessWidget {
  const _ComparePlanCard({
    required this.row,
    this.other,
    required this.isPremium,
    required this.onRemove,
    required this.onDisplayRoute,
    this.routeVisible = false,
    this.routeLoading = false,
    this.routeError,
    this.route,
  });

  final HotelRow row;
  final HotelRow? other;
  final bool isPremium;
  final VoidCallback onRemove;
  final VoidCallback onDisplayRoute;
  final bool routeVisible;
  final bool routeLoading;
  final String? routeError;
  final HotelRoute? route;

  @override
  Widget build(BuildContext context) {
    final dark = isPremium && other != null;
    final fg = dark ? Colors.white : AppColors.textPrimary;
    final fgMuted = dark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
    final borderColor = dark ? const Color(0xFF374151) : AppColors.border;

    final features = [
      _FeatureRow(
        '\$${row.nightlyRate} / night',
        wins: other != null && row.nightlyRate < other!.nightlyRate,
        ties: other != null && row.nightlyRate == other!.nightlyRate,
      ),
      _FeatureRow(
        'Driving Cost: \$${row.drivingCost} total (incl. parking)',
        wins: other != null && row.drivingCost < other!.drivingCost,
        ties: other != null && row.drivingCost == other!.drivingCost,
      ),
      _FeatureRow(
        '${row.walkMins.toStringAsFixed(1)} min walk to park',
        wins: other != null && row.walkMins < other!.walkMins,
        ties: other != null && row.walkMins == other!.walkMins,
      ),
      _FeatureRow(
        row.transitMins != null
            ? '${row.transitMins!.toStringAsFixed(1)} min transit'
            : 'Transit time unavailable',
        wins: other != null &&
            row.transitMins != null &&
            other!.transitMins != null &&
            row.transitMins! < other!.transitMins!,
        ties: other != null && row.transitMins == other!.transitMins,
      ),
      _FeatureRow(
        '${row.transitSavedMins.toStringAsFixed(1)} min saved vs walking',
        wins: other != null && row.transitSavedMins > other!.transitSavedMins,
        ties: other != null && row.transitSavedMins == other!.transitSavedMins,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.premium : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDecor.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: AppDecor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dark)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Better value',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      Text(
                        _shortHotelName(row.hotel),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        row.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: fgMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 18, color: fgMuted),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: features.map((f) => _CompareFeatureLine(feature: f, dark: dark)).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: routeLoading ? null : onDisplayRoute,
              style: TextButton.styleFrom(
                foregroundColor: dark ? Colors.white : AppColors.accent,
              ),
              child: routeLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: dark ? Colors.white : AppColors.accent),
                    )
                  : const Text('Display walking route'),
            ),
          ),
          if (routeError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(routeError!, style: TextStyle(color: dark ? const Color(0xFFFCA5A5) : AppColors.error, fontSize: 12)),
            ),
          if (routeVisible && route != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '${route!.durationText} walk · ${route!.distanceText}',
                style: TextStyle(color: dark ? AppColors.heroPurpleDeep : AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HotelRouteMap(
                  key: ValueKey('${row.address}-${route!.polyline}'),
                  hotelName: row.hotel,
                  originAddress: route!.origin,
                  destinationAddress: route!.destination,
                  encodedPolyline: route!.polyline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _shortHotelName(String name) {
    if (name.length <= 28) return name;
    return '${name.substring(0, 26)}…';
  }
}

class _FeatureRow {
  const _FeatureRow(this.label, {required this.wins, this.ties = false});
  final String label;
  final bool wins;
  final bool ties;
}

class _CompareFeatureLine extends StatelessWidget {
  const _CompareFeatureLine({required this.feature, required this.dark});

  final _FeatureRow feature;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.textPrimary;
    IconData icon;
    Color iconColor;
    if (feature.wins) {
      icon = Icons.check_circle;
      iconColor = AppColors.mint;
    } else if (feature.ties) {
      icon = Icons.remove_circle_outline;
      iconColor = AppColors.textMuted;
    } else {
      icon = Icons.circle_outlined;
      iconColor = dark ? const Color(0xFF4B5563) : AppColors.border;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(feature.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg)),
          ),
        ],
      ),
    );
  }
}
