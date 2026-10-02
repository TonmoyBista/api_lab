import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../features/interceptor/view_models/interceptor_view_model.dart';

void showConnectionGuideDialog(BuildContext context, InterceptorViewModel vm) {
  final instructions = '''# 1. cURL / Terminal (macOS, Linux, Windows):
export HTTP_PROXY="http://${vm.lanIp}:${vm.proxyPort}"
export HTTPS_PROXY="http://${vm.lanIp}:${vm.proxyPort}"
curl -k -x http://${vm.lanIp}:${vm.proxyPort} https://api.example.com/data

# 2. Mobile Phones & Tablets (iOS & Android):
1. Connect phone to the same Wi-Fi network as this PC.
2. Go to Wi-Fi Settings -> Select connected Wi-Fi -> HTTP Proxy -> Manual.
3. Set Server to: ${vm.lanIp}
4. Set Port to:   ${vm.proxyPort}

# 3. Direct Gateway Mode (Works with any app/language without proxy settings):
Send your HTTP request to: http://${vm.lanIp}:${vm.proxyPort}/endpoint
Add header: "X-ApiLab-Target: https://real-api-server.com/endpoint"''';

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.devices, color: AppColors.primaryHover, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Device & App Setup Guide',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ApiLab listens on all network interfaces including your local Wi-Fi IP (${vm.lanIp}:${vm.proxyPort}).',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                instructions,
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: AppColors.textMain),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: instructions));
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration copied to clipboard!')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Guide'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
