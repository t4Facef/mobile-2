import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_result.dart';
import '../models/stop_model.dart';

class MapView extends StatefulWidget {
  final RouteResult? routeResult;
  const MapView({super.key, this.routeResult});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeResult != oldWidget.routeResult && widget.routeResult != null) {
      _applyRoute(widget.routeResult!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() { _errorMessage = 'Serviço de localização desabilitado'; _isLoading = false; });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _isLoading = false; _errorMessage = 'Permissão de localização negada'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _isLoading = false; _errorMessage = 'Permissão negada permanentemente'; });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      final location = LatLng(position.latitude, position.longitude);
      setState(() { _currentLocation = location; _isLoading = false; });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 14));
      if (widget.routeResult != null) _applyRoute(widget.routeResult!);
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Erro ao obter localização: $e'; });
    }
  }

  Color _stopColor(Stop stop) {
    if (!stop.feasible) return Colors.purple;
    switch (stop.priority) {
      case 0: return Colors.red[900]!;
      case 1: return Colors.red[600]!;
      case 3: return Colors.green[600]!;
      default: return const Color(0xFFB71C1C);
    }
  }

  Future<BitmapDescriptor> _buildMarker(int number, Color color) async {
    const size = 88.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    canvas.drawCircle(
      const Offset(size / 2 + 1, size / 2 + 2),
      size / 2 - 6,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Círculo preenchido
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 6,
      Paint()..color = color,
    );
    // Borda branca
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Número
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<void> _applyRoute(RouteResult result) async {
    final markers = <Marker>{};

    for (var i = 0; i < result.stops.length; i++) {
      final stop = result.stops[i];
      final position = i < result.stopCoordinates.length ? result.stopCoordinates[i] : null;
      if (position == null) continue;

      final icon = await _buildMarker(i + 1, _stopColor(stop));

      final snippetParts = <String>[];
      if (stop.complement.isNotEmpty) snippetParts.add(stop.complement);
      if (stop.time != null) snippetParts.add('Pedido: ${stop.time}');
      if (stop.estimatedArrival != null) {
        snippetParts.add('Chegada: ${_fmt(stop.estimatedArrival!)}');
      }

      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(
          title: '${i + 1}. ${stop.address}',
          snippet: snippetParts.join(' · '),
        ),
      ));
    }

    final polylines = <Polyline>{
      if (result.polylinePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('route'),
          points: result.polylinePoints,
          color: const Color(0xFFB71C1C),
          width: 5,
          patterns: [],
        ),
    };

    if (!mounted) return;
    setState(() { _markers = markers; _polylines = polylines; });
    _fitBounds(result);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _fitBounds(RouteResult result) {
    if (_mapController == null) return;
    final points = [
      ...result.polylinePoints,
      ...result.stopCoordinates,
      if (result.userLocation != null) result.userLocation!,
    ];
    if (points.isEmpty) return;

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      72,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_errorMessage),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _getCurrentLocation, child: const Text('Tente Novamente')),
      ]));
    }

    return Stack(children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 14),
        onMapCreated: (controller) {
          _mapController = controller;
          if (widget.routeResult != null) _applyRoute(widget.routeResult!);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        markers: _markers,
        polylines: _polylines,
      ),
      if (widget.routeResult != null && widget.routeResult!.stops.isNotEmpty)
        _buildStopsList(widget.routeResult!, colors),
      Positioned(
        bottom: widget.routeResult != null ? 208 : 16,
        right: 16,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          foregroundColor: colors.primary,
          onPressed: () {
            if (_currentLocation != null) {
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14));
            }
          },
          child: const Icon(Icons.my_location),
        ),
      ),
    ]);
  }

  Widget _buildStopsList(RouteResult result, ColorScheme colors) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 210),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
              const SizedBox(width: 6),
              Text('Rota otimizada · ${result.stops.length} paradas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colors.primary)),
            ]),
          ),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shrinkWrap: true,
              itemCount: result.stops.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final stop = result.stops[i];
                final arrival = stop.estimatedArrival;
                final isLate = arrival != null && stop.time != null && _isAfterDeadline(arrival, stop.time!);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _stopColor(stop),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(stop.address,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (arrival != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLate ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '~${_fmt(arrival)}${isLate ? ' ⚠' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isLate ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  bool _isAfterDeadline(DateTime arrival, String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return false;
    final deadline = DateTime(
      arrival.year, arrival.month, arrival.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
    return arrival.isAfter(deadline);
  }
}
