import 'package:flutter/material.dart';
import 'package:passo_certo/core/theme/app_theme.dart';
import 'package:passo_certo/core/widgets/base_card.dart';

/// Legenda visual reutilizável sobre o nível de acessibilidade das rotas no mapa.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseCard(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: AppTheme.mintGreen, label: 'Boa'),
          _LegendItem(color: Colors.orange, label: 'Regular'),
          _LegendItem(color: AppTheme.emergencyRed, label: 'Atenção'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 6),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
