import 'package:flutter/widgets.dart';

/// Repaints the existing view after a browser tab becomes visible again.
/// Keeping the child mounted preserves navigation, searches and scroll offsets.
class ResumeRepaintBoundary extends StatefulWidget {
  const ResumeRepaintBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<ResumeRepaintBoundary> createState() => _ResumeRepaintBoundaryState();
}

class _ResumeRepaintBoundaryState extends State<ResumeRepaintBoundary>
    with WidgetsBindingObserver {
  final _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paintKey.currentContext?.findRenderObject()?.markNeedsPaint();
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _paintKey, child: widget.child);
}
