import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

class EmergencyDialogSheet extends StatelessWidget {
  const EmergencyDialogSheet({super.key});

  static const _samu = _EmergencyOption(
    name: 'SAMU',
    description: 'Serviço de Atendimento Móvel de Urgência',
    number: '192',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFD32F2F),
  );

  static const _diase = _EmergencyOption(
    name: 'DIASE',
    description: 'Divisão de Apoio ao Servidor — UFS',
    number: '7931947161',
    displayNumber: '(79) 3194-7161',
    icon: Icons.accessible_forward_rounded,
    color: Color(0xFF1565C0),
  );

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EmergencyDialogSheet(),
    );
  }

  Future<void> _dial(BuildContext context, _EmergencyOption option) async {
    final uri = Uri(scheme: 'tel', path: option.number);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o discador. Verifique as permissões do app.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Ícone de alerta
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: AppColors.emergencyRed,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),

          // Título
          Semantics(
            header: true,
            child: Text(
              'Central de Emergência',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.spaceBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecione para quem deseja ligar.\nA chamada será iniciada imediatamente.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Opção SAMU
          _EmergencyOptionCard(
            option: _samu,
            onTap: () => _dial(context, _samu),
          ),
          const SizedBox(height: 12),

          // Opção DIASE
          _EmergencyOptionCard(
            option: _diase,
            onTap: () => _dial(context, _diase),
          ),
          const SizedBox(height: 20),

          // Botão cancelar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyOptionCard extends StatelessWidget {
  final _EmergencyOption option;
  final VoidCallback onTap;

  const _EmergencyOptionCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Ligar para ${option.name}, ${option.displayNumber ?? option.number}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: option.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: option.color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(option.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: option.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              // Número + ícone de telefone
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.phone_rounded, color: option.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    option.displayNumber ?? option.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: option.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyOption {
  final String name;
  final String description;
  final String number;
  final String? displayNumber;
  final IconData icon;
  final Color color;

  const _EmergencyOption({
    required this.name,
    required this.description,
    required this.number,
    this.displayNumber,
    required this.icon,
    required this.color,
  });
}
