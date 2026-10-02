import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DesktopSplitPane extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final double initialRatio;
  final double minFirstRatio;
  final double maxFirstRatio;
  final double minFirstWidth;
  final double minSecondWidth;

  const DesktopSplitPane({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.initialRatio = 0.42,
    this.minFirstRatio = 0.20,
    this.maxFirstRatio = 0.80,
    this.minFirstWidth = 260.0,
    this.minSecondWidth = 320.0,
  });

  @override
  State<DesktopSplitPane> createState() => _DesktopSplitPaneState();
}

class _DesktopSplitPaneState extends State<DesktopSplitPane> {
  late double _ratio;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final minW = widget.minFirstWidth.clamp(0.0, totalWidth > 0 ? totalWidth * 0.45 : 0.0);
        final maxW = (totalWidth - widget.minSecondWidth).clamp(minW, totalWidth);
        final firstWidth = (totalWidth * _ratio).clamp(minW, maxW);

        return Row(
          children: [
            SizedBox(
              width: firstWidth,
              height: constraints.maxHeight,
              child: widget.firstChild,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  final newW = (firstWidth + details.delta.dx).clamp(minW, maxW);
                  _ratio = totalWidth > 0 ? newW / totalWidth : widget.initialRatio;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 6,
                  height: constraints.maxHeight,
                  color: AppColors.background,
                  child: Center(
                    child: Container(
                      width: 1,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: constraints.maxHeight,
                child: widget.secondChild,
              ),
            ),
          ],
        );
      },
    );
  }
}
