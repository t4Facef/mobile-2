import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_result.dart';
import '../models/stop_model.dart';
import '../services/gemini_service.dart';
import '../services/route_service.dart';

class DeliveryView extends StatefulWidget {
  final void Function(RouteResult)? onRouteOptimized;

  const DeliveryView({super.key, this.onRouteOptimized});

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  bool _isListMode = true;
  bool _isLoading = false;
  bool _isOptimized = false;

  final TextEditingController _listController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();

  final List<Stop> _stops = [
    Stop(address: 'Rua Augusta, 1508', complement: 'Apto 42 · Bloco A'),
    Stop(address: 'Av. Brigadeiro Faria Lima, 3477', complement: 'Torre Sul · Recepção'),
    Stop(address: 'Alameda Santos, 2224', complement: 'Loja 05 · Portaria'),
  ];

  Future<LatLng?> _getUserLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) { return null; }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) { return null; }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void _addStop() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final number = _numberController.text.trim();
    final full = number.isEmpty ? address : '$address, $number';

    setState(() {
      _stops.add(Stop(address: full, complement: _complementController.text.trim()));
      _isOptimized = false;
      _addressController.clear();
      _numberController.clear();
      _complementController.clear();
    });
  }

  void _removeStop(int index) => setState(() {
        _stops.removeAt(index);
        _isOptimized = false;
      });

  Future<void> _optimizeFromList() async {
    final text = _listController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final userOrigin = await _getUserLocation();
      final parsed = await GeminiService().parseDeliveryList(
        text,
        now: DateTime.now(),
        userLocation: userOrigin,
      );
      if (parsed.isEmpty) throw Exception('Nenhum endereço encontrado no texto.');

      final result = await RouteService().optimizeRoute(parsed, userOrigin: userOrigin);

      setState(() {
        _stops
          ..clear()
          ..addAll(result.stops)
          ..addAll(result.infeasible); // inviáveis aparecem no final, em vermelho
        _isListMode = false;
        _isOptimized = true;
        _listController.clear();
      });

      widget.onRouteOptimized?.call(result);

      final msg = result.infeasible.isEmpty
          ? 'IA otimizou ${result.stops.length} paradas!'
          : 'IA otimizou ${result.stops.length} paradas · ${result.infeasible.length} atrasada(s) no topo';
      _showSnack(msg, isError: false);
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _optimizeManual() async {
    if (_stops.length < 2) return;

    setState(() => _isLoading = true);
    try {
      final userOrigin = await _getUserLocation();
      final result = await RouteService().optimizeRoute(_stops, userOrigin: userOrigin);

      setState(() {
        _stops
          ..clear()
          ..addAll(result.stops)
          ..addAll(result.infeasible);
        _isOptimized = true;
      });

      widget.onRouteOptimized?.call(result);
      _showSnack('Rota otimizada! Indo para o mapa...', isError: false);
    } catch (e) {
      _showSnack('Erro ao otimizar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _listController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isListMode ? 'Nova Jornada' : 'Cadastro Manual de Entregas',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _isListMode
                ? 'Organize suas paradas de hoje e deixe a IA otimizar seu tempo.'
                : 'Preencha os detalhes abaixo para adicionar novos destinos à sua rota.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildToggle(colors),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingIndicator(colors)
          else
            _isListMode ? _buildListMode(colors) : _buildManualMode(colors),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'IA processando sua rota...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _toggleTab('Colar Lista', _isListMode, colors, () => setState(() => _isListMode = true)),
          _toggleTab('Manual', !_isListMode, colors, () => setState(() => _isListMode = false)),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active, ColorScheme colors, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListMode(ColorScheme colors) {
    return Column(
      children: [
        TextField(
          controller: _listController,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Ex: Av. Doutor Hélio Palermo 1200 - Sorvete, para as 20:00\nRua General Osório 150 - Pizza entrega as 21:00...',
            hintStyle: TextStyle(color: Colors.grey[450] ?? Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _listController.text.trim().isEmpty ? null : _optimizeFromList,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text(
              'Otimizar com IA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A IA extrai os endereços e seleciona o trajeto mais rápido.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildManualMode(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Paradas (${_stops.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_isOptimized) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Otimizada pela IA',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_stops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Nenhuma parada adicionada.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
          )
        else
          ...List.generate(_stops.length, (i) => _buildStopItem(i, colors)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _stops.length >= 2 ? _optimizeManual : null,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text(
              'Otimizar Rota',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _fieldLabel('Endereço'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _addressController,
          hint: 'Ex: Av. Paulista, 1000',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        _fieldLabel('Número/Apto'),
        const SizedBox(height: 6),
        _buildTextField(controller: _numberController, hint: 'Ex: 102B'),
        const SizedBox(height: 12),
        _fieldLabel('Complemento'),
        const SizedBox(height: 6),
        _buildTextField(controller: _complementController, hint: 'Ex: Próximo ao parque'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addStop,
            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
            label: const Text(
              'Adicionar Parada',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _isLate(Stop stop) {
    if (stop.estimatedArrival == null || stop.time == null) return false;
    final parts = stop.time!.split(':');
    if (parts.length != 2) return false;
    final deadline = DateTime(
      stop.estimatedArrival!.year, stop.estimatedArrival!.month, stop.estimatedArrival!.day,
      int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0,
    );
    return stop.estimatedArrival!.isAfter(deadline);
  }

  Color _priorityColor(Stop stop, ColorScheme colors) {
    if (!stop.feasible) return Colors.red[700]!;
    switch (stop.priority) {
      case 1: return Colors.red[600]!;
      case 3: return Colors.green[600]!;
      default: return _isOptimized ? Colors.green : colors.primary;
    }
  }

  Widget _buildStopItem(int index, ColorScheme colors) {
    final stop = _stops[index];
    final barColor = _priorityColor(stop, colors);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!stop.feasible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text('Atrasado',
                  style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.w700)),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text('${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.address,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (stop.complement.isNotEmpty)
                    Text(stop.complement,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  if (stop.note != null || stop.time != null || stop.estimatedArrival != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (stop.note != null)
                          Flexible(
                            child: Text(stop.note!,
                                style: TextStyle(color: Colors.blue[400], fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                        if (stop.note != null && stop.time != null)
                          Text('  ·  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        if (stop.time != null)
                          Text(stop.time!,
                              style: TextStyle(
                                  color: _priorityColor(stop, Theme.of(context).colorScheme),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        if (stop.estimatedArrival != null) ...[
                          Text('  →  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                          Text(
                            '~${_fmtTime(stop.estimatedArrival!)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isLate(stop) ? Colors.red[700] : Colors.green[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
            onPressed: () => _removeStop(index),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700]));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[400], size: 20) : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
