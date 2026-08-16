import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:faranka/app/core/providers/tutorial_provider.dart';

class TutorialWrapper extends StatefulWidget {
  final String pageName;
  final List<TargetFocus> targets;
  final Widget child;
  final Future<void> Function()? onReady;

  const TutorialWrapper({
    super.key,
    required this.pageName,
    required this.targets,
    required this.child,
    this.onReady,
  });

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await isTutorialSeen(widget.pageName);
    if (mounted) {
      setState(() {});
      if (!seen) {
        if (widget.onReady != null) {
          await widget.onReady!();
        }
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showTutorial();
        });
      }
    }
  }

  void _showTutorial() {
    final screenHeight = MediaQuery.of(context).size.height;
    const maxEffectiveH = 200.0;
    final patched = widget.targets.map((t) {
      if (t.keyTarget == null) return t;
      final box = t.keyTarget!.currentContext?.findRenderObject() as RenderBox?;
      double? overridePadding;
      if (box != null && box.attached) {
        final effectiveH = box.size.height * 0.6 + (t.paddingFocus ?? 6);
        if (effectiveH > maxEffectiveH) {
          overridePadding = math.max(0.0, -(box.size.height * 0.6) + maxEffectiveH);
        }
      }
      final ContentAlign align;
      if (box != null && box.attached) {
        final pos = box.localToGlobal(Offset.zero);
        final h = box.size.height + (overridePadding ?? t.paddingFocus ?? 6);
        final center = pos.dy + h / 2;
        align = center > screenHeight - center ? ContentAlign.top : ContentAlign.bottom;
      } else {
        align = ContentAlign.top;
      }
      final newContents = t.contents?.map((c) => TargetContent(
        align: align,
        padding: c.padding,
        child: c.child,
        customPosition: c.customPosition,
        builder: c.builder,
      )).toList();
      return TargetFocus(
        identify: t.identify,
        keyTarget: t.keyTarget,
        targetPosition: t.targetPosition,
        contents: newContents,
        shape: t.shape,
        radius: t.radius,
        borderSide: t.borderSide,
        color: t.color,
        enableOverlayTab: t.enableOverlayTab,
        enableTargetTab: t.enableTargetTab,
        alignSkip: t.alignSkip,
        paddingFocus: overridePadding ?? t.paddingFocus,
        focusAnimationDuration: t.focusAnimationDuration,
        unFocusAnimationDuration: t.unFocusAnimationDuration,
        pulseVariation: t.pulseVariation,
      );
    }).toList();

    TutorialCoachMark(
      targets: patched,
      beforeFocus: (target) async {
        final ctx = target.keyTarget?.currentContext;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            alignment: 0.5,
          );
        }
      },
      colorShadow: Colors.black54,
      paddingFocus: 6,
      hideSkip: true,
      onFinish: _dismiss,
      onSkip: () { _dismiss(); return true; },
      imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
      focusAnimationDuration: const Duration(milliseconds: 300),
    ).show(context: context);
  }

  Future<void> _dismiss() async {
    await markTutorialSeen(widget.pageName);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
