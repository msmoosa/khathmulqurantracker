import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _current;

/// Shows [message] briefly just below the app bar, so it doesn't cover the
/// buttons at the bottom of the screen the way a snackbar does.
void showTopToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Color? iconColor,
}) {
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopToast(
      message: message,
      icon: icon,
      iconColor: iconColor,
      onDone: () {
        entry.remove();
        if (_current == entry) _current = null;
      },
    ),
  );
  _current = entry;
  Overlay.of(context).insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDone,
  });

  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onDone;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _anim.forward();
    _timer = Timer(const Duration(seconds: 2), () async {
      await _anim.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(curve),
            child: Material(
              color: colors.inverseSurface,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.iconColor ?? colors.inversePrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onInverseSurface,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
