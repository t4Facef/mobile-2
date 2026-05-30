import 'package:flutter/material.dart';

class _Stop {
  final String address;
  final String complement;
  _Stop({required this.address, required this.complement});
}

class DeliveryView extends StatefulWidget {
  const DeliveryView({super.key});

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  bool _isListMode = true;

  final TextEditingController _listController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();

  final List<_Stop> _stops = [
    _Stop(address: 'Rua Augusta, 1508', complement: 'Apto 42 · Bloco A'),
    _Stop(address: 'Av. Brigadeiro Faria Lima, 3477', complement: 'Torre Sul · Recepção'),
    _Stop(address: 'Alameda Santos, 2224', complement: 'Loja 05 · Portaria'),
  ];

  void _addStop() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final number = _numberController.text.trim();
    final full = number.isEmpty ? address : '$address, $number';

    setState(() {
      _stops.add(_Stop(
        address: full,
        complement: _complementController.text.trim(),
      ));
      _addressController.clear();
      _numberController.clear();
      _complementController.clear();
    });
  }

  void _removeStop(int index) => setState(() => _stops.removeAt(index));

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
          _isListMode ? _buildListMode(colors) : _buildManualMode(colors),
        ],
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
        Stack(
          children: [
            TextField(
              controller: _listController,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'Ex: Av. Doutor Hélio Palermo 1200 - Sorvete, para as 20:00\nRua General Osório 150 - Pizza entrega as 21:00...',
                hintStyle: TextStyle(color: Colors.grey[450] ?? Colors.grey, fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    width: 0.5,
                    color: colors.primary,
                    style: BorderStyle.none,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
              ),
            ),

          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.navigation_rounded, color: Colors.white),
            label: const Text(
              'Otimizar Rota',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A IA selecionará o trajeto mais rápido para suas entregas.',
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
        Text(
          'Paradas (${_stops.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_stops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Nenhuma parada adicionada.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(_stops.length, (i) => _buildStopItem(i, colors)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _stops.isEmpty ? null : () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Otimizar Rota', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildStopItem(int index, ColorScheme colors) {
    final stop = _stops[index];
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
            height: 60,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.address,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (stop.complement.isNotEmpty)
                  Text(
                    stop.complement,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
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
    return Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700]),
    );
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
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[400], size: 20)
            : null,
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
