import 'package:flutter/material.dart';

class DeliveryView extends StatefulWidget {
  const DeliveryView({super.key});

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nova Rota",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12),
          Text("Organize as paradas e deixei a IA organizar seu tempo"),
          SizedBox(height: 12),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  "Ex: Av. Doutor Hélio Palermo 1200 - Sorvete, para as 20:00\nRua General Osório 150 - Pizza entrega as 21:00...",
              hintStyle: TextStyle(color: Colors.grey[450] ?? Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 0.5,
                  color: themeColors.primary,
                  style: BorderStyle.none,
                ),
              ),
              
            ),

          ),
        ],
      ),
    );
  }
}
