import 'dart:async';

import 'package:flutter/widgets.dart';

/// Holds back a selection made while a finger is down until it lifts.
///
/// The glass tab bar and segmented control report a new selection the moment
/// they are touched. Here the control is shown the pressed index straight
/// away, so its bubble moves under the finger, but [onSelected] is called only
/// on release, so the screen behind does not change mid-press.
class ReleaseToSelect extends StatefulWidget {
  const ReleaseToSelect({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.builder,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Builds the control with the index to show and the callback to give it.
  final Widget Function(
    BuildContext context,
    int selectedIndex,
    ValueChanged<int> onSelected,
  ) builder;

  @override
  State<ReleaseToSelect> createState() => _ReleaseToSelectState();
}

class _ReleaseToSelectState extends State<ReleaseToSelect> {
  int _pointers = 0;
  int? _pending;

  void _select(int index) {
    if (_pointers > 0) {
      setState(() => _pending = index);
      return;
    }
    // A drag reports its target after the finger has lifted; that replaces
    // whatever the press chose.
    if (_pending != null) setState(() => _pending = null);
    widget.onSelected(index);
  }

  void _pointerUp() {
    _pointers = _pointers > 0 ? _pointers - 1 : 0;
    if (_pointers > 0) return;
    // The control's own gesture callbacks for this lift run after this one,
    // so wait for them before committing.
    scheduleMicrotask(() {
      final pending = _pending;
      if (!mounted || pending == null || _pointers > 0) return;
      setState(() => _pending = null);
      widget.onSelected(pending);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pointers++,
      onPointerUp: (_) => _pointerUp(),
      onPointerCancel: (_) => _pointerUp(),
      child: widget.builder(
        context,
        _pending ?? widget.selectedIndex,
        _select,
      ),
    );
  }
}
