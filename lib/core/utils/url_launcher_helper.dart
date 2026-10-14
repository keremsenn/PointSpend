import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> launchOrCopyUrl(BuildContext context, String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    bool launched = false;
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı panoya kopyalandı:\n$url'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  static String formatPrice(double price) {
    if (price % 1 == 0) {
      final str = price.toInt().toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (m) => '${m[1]}.');
    } else {
      final parts = price.toStringAsFixed(2).split('.');
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formattedInt = parts[0].replaceAllMapped(reg, (m) => '${m[1]}.');
      return '$formattedInt,${parts[1]}';
    }
  }
}

class RewardLinkTile extends StatelessWidget {
  final String url;
  final Color textColor;
  final bool isDark;

  const RewardLinkTile({
    super.key,
    required this.url,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => UrlLauncherHelper.launchOrCopyUrl(context, url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF16A34A).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link_rounded, color: Color(0xFF15803D), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ödül / Ürün Linki',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.85),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Bağlantıyı Aç',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(34, 34),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              onPressed: () => UrlLauncherHelper.launchOrCopyUrl(context, url),
            ),
          ],
        ),
      ),
    );
  }
}
