import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final int? statusCode;
  final String? statusReason;
  final bool isMocked;
  final bool isPending;
  final bool showReason;

  const StatusBadge({
    super.key,
    this.statusCode,
    this.statusReason,
    this.isMocked = false,
    this.isPending = false,
    this.showReason = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'PENDING',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (statusCode == null || statusCode == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.statusServerError.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.statusServerError.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'ERR',
          style: TextStyle(
            color: AppColors.statusServerError,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    Color color;
    if (statusCode! >= 200 && statusCode! < 300) {
      color = AppColors.statusSuccess;
    } else if (statusCode! >= 300 && statusCode! < 400) {
      color = AppColors.statusRedirect;
    } else if (statusCode! >= 400 && statusCode! < 500) {
      color = AppColors.statusClientError;
    } else {
      color = AppColors.statusServerError;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMocked) ...[
            const Icon(Icons.auto_awesome, size: 11, color: AppColors.statusMock),
            const SizedBox(width: 4),
          ],
          Text(
            showReason && statusReason != null && statusReason!.isNotEmpty
                ? '$statusCode $statusReason'
                : '$statusCode',
            style: TextStyle(
              color: isMocked ? AppColors.statusMock : color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
