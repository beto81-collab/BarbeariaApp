import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _lembretes24h = true;
  bool _lembretes2h = true;
  bool _lembretes30min = true;
  bool _promocoesSemanas = true;
  bool _statusAlterados = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Notificações'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor.withAlpha((0.8 * 255).round()),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Notificações',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure quando e como deseja receber notificações da CORTE REAL',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Seção de Lembretes de Agendamento
            const Text(
              'Lembretes de Agendamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildNotificationTile(
              title: 'Lembrete 24 horas antes',
              subtitle: 'Receba um lembrete um dia antes do seu agendamento',
              icon: Icons.schedule,
              value: _lembretes24h,
              onChanged: (value) {
                setState(() {
                  _lembretes24h = value;
                });
              },
            ),

            _buildNotificationTile(
              title: 'Lembrete 2 horas antes',
              subtitle: 'Receba um lembrete 2 horas antes do horário',
              icon: Icons.access_time,
              value: _lembretes2h,
              onChanged: (value) {
                setState(() {
                  _lembretes2h = value;
                });
              },
            ),

            _buildNotificationTile(
              title: 'Lembrete 30 minutos antes',
              subtitle: 'Receba um lembrete para se preparar para sair',
              icon: Icons.timer,
              value: _lembretes30min,
              onChanged: (value) {
                setState(() {
                  _lembretes30min = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Seção de Status e Confirmações
            const Text(
              'Status e Confirmações',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildNotificationTile(
              title: 'Mudanças de status',
              subtitle:
                  'Receba notificações quando o status do agendamento mudar',
              icon: Icons.update,
              value: _statusAlterados,
              onChanged: (value) {
                setState(() {
                  _statusAlterados = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Seção de Promoções
            const Text(
              'Promoções e Ofertas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildNotificationTile(
              title: 'Promoções semanais',
              subtitle: 'Receba ofertas especiais toda sexta-feira',
              icon: Icons.local_offer,
              value: _promocoesSemanas,
              onChanged: (value) {
                setState(() {
                  _promocoesSemanas = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testarNotificacao,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Testar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvarConfiguracoes,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção de Informações
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor.withAlpha((0.1 * 255).round()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• As notificações funcionam mesmo com o app fechado\n'
                    '• Você pode desativar tipos específicos de notificações\n'
                    '• As configurações são salvas automaticamente\n'
                    '• Para receber notificações, mantenha-as ativadas nas configurações do dispositivo',
                    style: TextStyle(
                      color: AppTheme.subTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ações Avançadas
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações Avançadas'),
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.cancel_outlined,
                      color: AppTheme.errorColor,
                    ),
                    title: const Text('Cancelar todas as notificações'),
                    subtitle: const Text(
                      'Remove todas as notificações pendentes',
                    ),
                    onTap: _cancelarTodasNotificacoes,
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_outlined),
                    title: const Text('Ver notificações pendentes'),
                    subtitle: const Text('Mostra lembretes agendados'),
                    onTap: _verNotificacoesPendentes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.1 * 255).round()),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(16),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value
                ? AppTheme.secondaryColor.withAlpha((0.1 * 255).round())
                : AppTheme.subTextColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.secondaryColor : AppTheme.subTextColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.subTextColor, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _testarNotificacao() {
    NotificationService.testarNotificacao();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação de teste enviada!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _salvarConfiguracoes() {
    // Aqui você salvaria as configurações no SharedPreferences ou Firebase
    // Por enquanto, apenas mostra confirmação

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _cancelarTodasNotificacoes() async {
    await NotificationService.cancelarTodasNotificacoes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as notificações foram canceladas'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _verNotificacoesPendentes() async {
    final pendentes = await NotificationService.listarNotificacoesPendentes();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Notificações Pendentes',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: pendentes.isEmpty
                ? const Text(
                    'Nenhuma notificação pendente',
                    style: TextStyle(color: AppTheme.subTextColor),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pendentes.length,
                    itemBuilder: (context, index) {
                      final notificacao = pendentes[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.schedule,
                          color: AppTheme.secondaryColor,
                        ),
                        title: Text(
                          notificacao.title ?? 'Sem título',
                          style: const TextStyle(color: AppTheme.textColor),
                        ),
                        subtitle: Text(
                          notificacao.body ?? 'Sem descrição',
                          style: TextStyle(color: AppTheme.subTextColor),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
          ],
        ),
      );
    }
  }
}
