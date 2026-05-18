import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../config.dart';
import '../services/maps_route_bridge.dart';
import '../theme/app_theme.dart';

/// Embeds Google Maps JavaScript API with the walking route drawn on the map.
class HotelRouteMap extends StatefulWidget {
  const HotelRouteMap({
    super.key,
    required this.hotelName,
    required this.originAddress,
    this.destinationAddress = disneylandDestination,
    this.encodedPolyline = '',
    this.height = 280,
  });

  final String hotelName;
  final String originAddress;
  final String destinationAddress;
  final String encodedPolyline;
  final double height;

  @override
  State<HotelRouteMap> createState() => _HotelRouteMapState();
}

class _HotelRouteMapState extends State<HotelRouteMap> {
  static int _viewCounter = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'hotel-route-map-${_viewCounter++}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final div = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minHeight = '240px'
        ..style.display = 'block';

      final request = RouteMapRequest(
        apiKey: googleMapsApiKey,
        origin: widget.originAddress,
        destination: widget.destinationAddress,
        encodedPolyline: widget.encodedPolyline,
      );

      Future.microtask(() => invokeMapsRouteRender(div, request));

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: const Color(0xFFE5E7EB),
            ),
            child: HtmlElementView(viewType: _viewType),
          ),
        ),
      ],
    );
  }
}
