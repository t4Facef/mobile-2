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
  bool _showTip = false;
  int _loadingStep = 0; // 0 = lendo, 1 = localizando, 2 = otimizando

  final TextEditingController _listController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();

  final List<Stop> _stops = [];

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
    setState(() {
      _stops.add(Stop(address: address, complement: _complementController.text.trim()));
      _isOptimized = false;
      _addressController.clear();
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
    setState(() { _isLoading = true; _loadingStep = 0; });
    try {
      final userOrigin = await _getUserLocation();
      setState(() => _loadingStep = 1);

      final parsed = await GeminiService().parseDeliveryList(
        text, now: DateTime.now(), userLocation: userOrigin,
      );
      if (parsed.isEmpty) throw Exception('Nenhum endereço encontrado no texto.');

      setState(() => _loadingStep = 2);
      final result = await RouteService().optimizeRoute(parsed, userOrigin: userOrigin);

      setState(() {
        _stops..clear()..addAll(result.stops)..addAll(result.infeasible);
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
    setState(() { _isLoading = true; _loadingStep = 1; });
    try {
      final userOrigin = await _getUserLocation();
      setState(() => _loadingStep = 2);
      final result = await RouteService().optimizeRoute(_stops, userOrigin: userOrigin);
      setState(() {
        _stops..clear()..addAll(result.stops)..addAll(result.infeasible);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _listController.dispose();
    _addressController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _isLate(Stop stop) {
    if (stop.estimatedArrival == null || stop.time == null) return false;
    final parts = stop.time!.split(':');
    if (parts.length != 2) return false;
    final deadline = DateTime(
      stop.estimatedArrival!.year, stop.estimatedArrival!.month,
      stop.estimatedArrival!.day,
      int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0,
    );
    return stop.estimatedArrival!.isAfter(deadline);
  }

  Color _barColor(Stop stop, ColorScheme colors) {
    if (!stop.feasible) return Colors.red[700]!;
    switch (stop.priority) {
      case 0: return Colors.red[900]!;
      case 1: return Colors.red[600]!;
      case 3: return Colors.green[600]!;
      default: return _isOptimized ? Colors.green : colors.primary;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: 20),
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

  Widget _buildHeader(ColorScheme colors) {
    final count = _stops.where((s) => s.feasible).length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Entregas do Dia',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                _isOptimized
                    ? '$count ${count == 1 ? 'parada otimizada' : 'paradas otimizadas'} pela IA'
                    : 'Cole a lista ou adicione endereços manualmente.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        if (_isOptimized)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text('Otimizada',
                  style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w700)),
            ]),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colors) {
    final steps = ['Lendo endereços...', 'Localizando paradas...', 'Otimizando rota...'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        CircularProgressIndicator(color: colors.primary),
        const SizedBox(height: 20),
        ...List.generate(steps.length, (i) {
          final done = i < _loadingStep;
          final active = i == _loadingStep;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                done ? Icons.check_circle_rounded : (active ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                size: 16,
                color: done ? Colors.green : (active ? colors.primary : Colors.grey[400]),
              ),
              const SizedBox(width: 8),
              Text(steps[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: done ? Colors.green[700] : (active ? colors.primary : Colors.grey[400]),
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  )),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildToggle(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        _toggleTab(Icons.auto_awesome_rounded, 'Via IA', _isListMode, colors,
            () => setState(() => _isListMode = true)),
        _toggleTab(Icons.edit_location_alt_rounded, 'Manual', !_isListMode, colors,
            () => setState(() => _isListMode = false)),
      ]),
    );
  }

  Widget _toggleTab(IconData icon, String label, bool active, ColorScheme colors, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: active ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: active ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildListMode(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dica colapsável
        GestureDetector(
          onTap: () => setState(() => _showTip = !_showTip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Como usar este modo?',
                    style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600)),
              ),
              Icon(_showTip ? Icons.expand_less : Icons.expand_more, size: 18, color: colors.primary),
            ]),
          ),
        ),
        if (_showTip) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cole sua lista de entregas em texto livre. A IA identifica:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 8),
              _tipItem('📍', 'Endereço e número'),
              _tipItem('🍕', 'Produto ou observação'),
              _tipItem('🕐', 'Horário de entrega'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Rua Major Claudiano 1200 - Pizza, até 18:30\nAv. Champagnat 820 - Açaí 500ml, para 19:00',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'monospace'),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        // Área de texto
        Stack(children: [
          TextField(
            controller: _listController,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cole aqui a lista de entregas...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.fromLTRB(14, 14, 40, 14),
            ),
          ),
          if (_listController.text.isNotEmpty)
            Positioned(
              top: 6, right: 6,
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]),
                onPressed: () => setState(() => _listController.clear()),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _listController.text.trim().isEmpty ? null : _optimizeFromList,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            label: const Text('Otimizar com IA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('Usa sua localização atual como ponto de partida.',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _tipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ]),
    );
  }

  Widget _buildManualMode(ColorScheme colors) {
    final feasibleCount = _stops.where((s) => s.feasible).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da lista
        if (_stops.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text('Paradas (${_stops.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_stops.length >= 2)
                TextButton.icon(
                  onPressed: _optimizeManual,
                  icon: Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
                  label: Text('Otimizar', style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: colors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ]),
          ),

        // Lista vazia
        if (_stops.isEmpty)
          _buildEmptyState(colors)
        else
          ...List.generate(_stops.length, (i) => _buildStopItem(i, colors)),

        // Formulário de adição
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.add_location_alt_outlined, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text('Nova parada', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: colors.primary)),
            ]),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              hint: 'Ex: Rua Major Claudiano 1200',
              prefixIcon: Icons.location_on_outlined,
              label: 'Endereço e número',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _complementController,
              hint: 'Ex: Apto 12 · Produto · Horário',
              prefixIcon: Icons.notes_rounded,
              label: 'Complemento / Observação',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addressController.text.trim().isEmpty ? null : _addStop,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                label: const Text('Adicionar Parada',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),

        if (feasibleCount >= 2 && _isOptimized)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text('Toque em "Rota" na barra inferior para ver no mapa.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.local_shipping_outlined, size: 30, color: colors.primary),
        ),
        const SizedBox(height: 12),
        const Text('Nenhuma entrega ainda',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text('Adicione os endereços abaixo\nque a IA monta a melhor rota.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        Icon(Icons.arrow_downward_rounded, color: colors.primary.withValues(alpha: 0.4), size: 20),
      ]),
    );
  }

  Widget _buildStopItem(int index, ColorScheme colors) {
    final stop = _stops[index];
    final bar = _barColor(stop, colors);
    final late = _isLate(stop);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(children: [
        // Barra lateral colorida
        Container(
          width: 4,
          height: 76,
          decoration: BoxDecoration(
            color: bar,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10), bottomLeft: Radius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Número de ordem (sempre visível)
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text('${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        // Conteúdo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(stop.address,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                if (!stop.feasible) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text('Atrasado',
                        style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.w700)),
                  ),
                ] else if (stop.priority == 1 || stop.priority == 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text('Urgente',
                        style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              if (stop.complement.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(stop.complement,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
              if (stop.note != null || stop.time != null || stop.estimatedArrival != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  if (stop.note != null)
                    Flexible(
                      child: Text(stop.note!,
                          style: TextStyle(color: Colors.blue[400], fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  if (stop.note != null && stop.time != null)
                    Text(' · ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  if (stop.time != null)
                    Text(stop.time!,
                        style: TextStyle(color: bar, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (stop.estimatedArrival != null) ...[
                    Text('  →  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    Text('~${_fmtTime(stop.estimatedArrival!)}',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: late ? Colors.red[700] : Colors.green[600],
                        )),
                    if (late) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red[600]),
                    ],
                  ],
                ]),
              ],
            ]),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
          onPressed: () => _removeStop(index),
        ),
      ]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    IconData? prefixIcon,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[400], size: 18) : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    ]);
  }
}
