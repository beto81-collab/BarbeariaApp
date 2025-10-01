import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../services/firebase_service.dart';
import 'produtos_screen.dart';
import 'servicos_screen.dart';
import 'agendamento_screen.dart';
import 'admin_agendamentos_screen.dart';
import 'horarios_screen.dart';
import 'atualizacoes_screen.dart';
import 'backup_screen.dart';
import 'clientes_screen.dart';
import 'aniversariantes_screen.dart';
import 'vitrine_screen.dart';
import 'promocoes_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LogoCorteRealHorizontal(height: 32),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          children: [
            _AdminTile(
              icon: Icons.photo_library,
              label: 'Vitrine',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VitrineScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.shopping_bag,
              label: 'Produtos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProdutosScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.design_services,
              label: 'Serviços',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServicosScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.local_offer,
              label: 'Promoções',
              // Alterado para abrir a tela de Promoções em vez do diálogo "Em breve".
              // Agora redireciona para `PromocoesScreen` que já está implementada.
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromocoesScreen()),
              ),
            ),
            _AdminTileComBadge(
              icon: Icons.cake,
              label: 'Aniversariantes',
              contadorStream:
                  FirebaseService.streamContadorAniversariantesHoje(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AniversariantesScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.event,
              label: 'Agendamentos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAgendamentosScreen(),
                ),
              ),
            ),
            _AdminTile(
              icon: Icons.access_time,
              label: 'Horários',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HorariosScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.system_update,
              label: 'Atualizações',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AtualizacoesScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.people,
              label: 'Clientes',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientesScreen()),
              ),
            ),
            _AdminTile(
              icon: Icons.backup,
              label: 'Backup',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BackupScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTileComBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Stream<int> contadorStream;

  const _AdminTileComBadge({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.contadorStream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(icon, size: 48, color: AppTheme.primaryColor),
                  StreamBuilder<int>(
                    stream: contadorStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
