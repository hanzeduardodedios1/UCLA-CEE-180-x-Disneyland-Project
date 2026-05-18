import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/static_map.dart';

/// Shows route as a Google Static Map image (works on desktop/mobile builds).
class HotelRouteMap extends StatelessWidget {
  const HotelRouteMap({
    super.key,
    required this.hotelName,
    required this.originAddress,
    this.destinationAddress = '',
    this.encodedPolyline = '',
    this.height = 280,
  });

  final String hotelName;
  final String originAddress;
  final String destinationAddress;
  final String encodedPolyline;
  final double height;

  @override
  Widget build(BuildContext context) {
    final mapUrl = staticRouteMapUrl(encodedPolyline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Walking route to Disneyland',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDecor.radiusMd),
          child: Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFFE5E7EB),
            child: mapUrl == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Map unavailable. Run on web with GOOGLE_MAPS_JS_API_KEY, '
                        'or pass --dart-define=GOOGLE_MAPS_JS_API_KEY=your_key',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  )
                : Image.network(
                    mapUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Could not load map image. Check your Maps API key '
                          '(Maps Static API must be enabled).',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
