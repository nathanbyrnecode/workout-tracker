import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/models/location_type.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/theme/app_typography.dart';
import 'package:gym_tracker_app/util/number_format.dart';
import 'package:gym_tracker_app/widgets/dashed_border.dart';
import 'package:gym_tracker_app/widgets/field_label.dart';
import 'package:gym_tracker_app/widgets/location_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Where a workout happened: a required type (Gym, Home, Park, Other) and an
/// optional place found by search. Used by the End, Log and Edit workout
/// sheets. Choosing a place never changes the type.
///
/// The Place part is shown only when a place search is available.
class LocationSection extends ConsumerStatefulWidget {
  const LocationSection({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.place,
    required this.onPlaceChanged,
  });

  final LocationType type;
  final ValueChanged<LocationType> onTypeChanged;
  final Place? place;
  final ValueChanged<Place?> onPlaceChanged;

  /// How many results the panel lists.
  static const maxResults = 5;

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _generation = 0;

  bool _searching = false;
  bool _loading = false;
  List<PlaceResult> _results = const [];

  /// The query the results on screen belong to.
  String _resultsQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _open() {
    _query.clear();
    setState(() {
      _searching = true;
      _results = const [];
      _resultsQuery = '';
    });
    _load('');
  }

  void _close() {
    _debounce?.cancel();
    _generation++;
    setState(() => _searching = false);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    // Wait for a pause in typing before asking the service.
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _load(value.trim()),
    );
  }

  Future<void> _load(String query) async {
    final service = ref.read(placeSearchServiceProvider);
    final generation = ++_generation;
    setState(() => _loading = true);
    List<PlaceResult> results;
    try {
      results =
          query.isEmpty ? await service.nearby() : await service.search(query);
    } catch (_) {
      // A search that fails reads as one that found nothing.
      results = const [];
    }
    // A newer search, or closing the panel, makes this one stale.
    if (!mounted || generation != _generation) {
      return;
    }
    setState(() {
      _loading = false;
      _results = results.take(LocationSection.maxResults).toList();
      _resultsQuery = query;
    });
  }

  Future<void> _useCurrentLocation() async {
    final generation = _generation;
    final result = await ref.read(placeSearchServiceProvider).currentLocation();
    if (!mounted || generation != _generation || result == null) {
      return;
    }
    _pick(result.place);
  }

  void _pick(Place place) {
    widget.onPlaceChanged(place);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final placeSearch = ref.watch(placeSearchServiceProvider);
    final place = widget.place;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spacing.gap18,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: t.spacing.gap8,
          children: [
            const FieldLabel('LOCATION'),
            Row(
              spacing: t.spacing.gap6,
              children: [
                for (final type in LocationType.values)
                  Expanded(
                    child: _TypeTile(
                      type: type,
                      selected: type == widget.type,
                      onTap: () => widget.onTypeChanged(type),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (placeSearch.isAvailable)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: t.spacing.gap8,
            children: [
              const FieldLabel('PLACE', note: 'OPTIONAL'),
              if (_searching)
                _SearchPanel(
                  controller: _query,
                  onChanged: _onQueryChanged,
                  onCancel: _close,
                  onUseCurrentLocation: _useCurrentLocation,
                  onPick: _pick,
                  results: _results,
                  query: _resultsQuery,
                  loading: _loading,
                )
              else if (place != null)
                _SelectedPlace(
                  place: place,
                  onChange: _open,
                  onClear: () => widget.onPlaceChanged(null),
                )
              else
                _SearchButton(onTap: _open),
            ],
          ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final LocationType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final foreground = selected ? t.accentInk : t.fg;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? t.accent : t.card2,
          borderRadius: BorderRadius.circular(t.radii.setRow),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(t.radii.setRow),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: [
                Icon(locationIcon(type), size: 20, color: foreground),
                Text(
                  type.label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DashedBorder(
      color: t.line,
      borderRadius: t.radii.setRow,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(t.radii.setRow),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              spacing: t.spacing.gap10,
              children: [
                Icon(LucideIcons.search, size: 18, color: t.muted),
                Text(
                  'Search for a location',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: t.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlace extends StatelessWidget {
  const _SelectedPlace({
    required this.place,
    required this.onChange,
    required this.onClear,
  });

  final Place place;
  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final address = place.address;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.setRow),
      ),
      child: Row(
        spacing: t.spacing.gap12,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(t.radii.tile),
            ),
            child: Icon(LucideIcons.mapPin, size: 18, color: t.accentInk),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.setValueSmall,
                ),
                if (address != null && address.isNotEmpty)
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      color: t.muted,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: t.card,
                borderRadius: BorderRadius.circular(t.radii.tileMedium),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onChange,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Change',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Remove place',
                child: InkResponse(
                  onTap: onClear,
                  radius: 18,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(LucideIcons.x, size: 16, color: t.muted),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.onChanged,
    required this.onCancel,
    required this.onUseCurrentLocation,
    required this.onPick,
    required this.results,
    required this.query,
    required this.loading,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<Place> onPick;
  final List<PlaceResult> results;
  final String query;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final line = BorderSide(color: t.line);
    return Container(
      decoration: BoxDecoration(
        color: t.card2,
        borderRadius: BorderRadius.circular(t.radii.button),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 4),
                child: Row(
                  spacing: t.spacing.gap10,
                  children: [
                    Icon(LucideIcons.search, size: 18, color: t.muted),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.search,
                        cursorColor: t.accentText,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: t.fg,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Name, address or postcode…',
                          hintStyle: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: t.muted,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onCancel,
                      borderRadius: BorderRadius.circular(t.radii.tileSmall),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Cancel',
                          style: AppTypography.toggle
                              .copyWith(color: t.accentText),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(border: Border(top: line)),
                      child: InkWell(
                        onTap: onUseCurrentLocation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            spacing: t.spacing.gap12,
                            children: [
                              _ResultTile(
                                icon: LucideIcons.locateFixed,
                                color: t.accentText,
                              ),
                              const Text(
                                'Use current location',
                                style: AppTypography.toggle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (results.isNotEmpty)
                      DecoratedBox(
                        decoration: BoxDecoration(border: Border(top: line)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Text(
                            query.isEmpty ? 'NEARBY' : 'RESULTS',
                            style: AppTypography.labelSmall
                                .copyWith(color: t.muted),
                          ),
                        ),
                      ),
                    for (final result in results)
                      _ResultRow(
                          result: result, onTap: () => onPick(result.place)),
                    // Nothing typed and nothing nearby is not worth a message.
                    if (results.isEmpty && query.isNotEmpty && !loading)
                      DecoratedBox(
                        decoration: BoxDecoration(border: Border(top: line)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'No places match “$query”',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: t.muted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radii.tileSmall),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.onTap});

  final PlaceResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final address = result.place.address;
    final distance = result.distanceMeters;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          spacing: t.spacing.gap12,
          children: [
            _ResultTile(icon: LucideIcons.mapPin, color: t.muted),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    result.place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.toggle,
                  ),
                  if (address != null && address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: t.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (distance != null)
              Text(
                formatDistance(distance),
                style: AppTypography.footnote.copyWith(
                  letterSpacing: 0,
                  color: t.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
