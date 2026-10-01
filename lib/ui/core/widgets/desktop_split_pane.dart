import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DesktopSplitPane extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final double initialRatio;
  final double minFirstRatio;
  final double maxFirstRatio;

  const DesktopSplitPane({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.initialRatio = 0.42,
    this.minFirstRatio = 0.25,
    this.maxFirstRatio = 0.75,
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
        final firstWidth = (totalWidth * _ratio).clamp(
          totalWidth * widget.minFirstRatio,
          totalWidth * widget.maxFirstRatio,
        );

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
                  _ratio = ((firstWidth + details.delta.dx) / totalWidth).clamp(
                    widget.minFirstRatio,
                    widget.maxFirstRatio,
                  );
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
