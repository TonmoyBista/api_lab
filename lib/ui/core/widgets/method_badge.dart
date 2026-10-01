import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MethodBadge extends StatelessWidget {
  final String method;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MethodBadge({
    super.key,
    required this.method,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  });

  Color _getMethodColor(String m) {
    switch (m.toUpperCase()) {
      case 'GET': return AppColors.methodGet;
      case 'POST': return AppColors.methodPost;
      case 'PUT': return AppColors.methodPut;
      case 'DELETE': return AppColors.methodDelete;
      case 'PATCH': return AppColors.methodPatch;
      case 'HEAD': return AppColors.methodHead;
      case 'OPTIONS': return AppColors.methodOptions;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMethodColor(method);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
