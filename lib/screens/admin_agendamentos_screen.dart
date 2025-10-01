import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/agendamento.dart';
import '../services/firebase_service.dart';

class AdminAgendamentosScreen extends StatefulWidget {
  const AdminAgendamentosScreen({super.key});

  @override
  State<AdminAgendamentosScreen> createState() => _AdminAgendamentosScreenState();
}

class _AdminAgendamentosScreenState extends State<AdminAgendamentosScreen> {
  final Map<String, String> _clienteNomes = {};
  final Map<String, String> _servicoNomes = {};

  Future<void> _ensureClienteNome(String clienteId) async {
    if (_clienteNomes.containsKey(clienteId)) return;
    final u = await FirebaseService.obterUsuarioPorId(clienteId);
    if (u != null) setState(() => _clienteNomes[clienteId] = u.nome);
  }

  Future<void> _ensureServicoNome(String servicoId) async {
    if (_servicoNomes.containsKey(servicoId)) return;
    final s = await FirebaseService.obterServicoPorId(servicoId);
    if (s != null) setState(() => _servicoNomes[servicoId] = s.nome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos (pendentes)'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: FirebaseService.streamAgendamentosPendentes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Erro no stream de agendamentos pendentes: ${snapshot.error}');
            return Center(child: Text('Erro ao carregar agendamentos: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final agendamentos = snapshot.data ?? [];
          print('Stream agendamentos pendentes - documentos recebidos: ${agendamentos.length}');

          if (agendamentos.isEmpty) {
            return FutureBuilder<List<Agendamento>>(
              future: FirebaseService.obterTodosAgendamentos().then((list) => list.where((a) => (a.status.name == 'pendente' || a.status == StatusAgendamento.agendado)).toList()),
              builder: (context, snap2) {
                if (snap2.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final fallback = snap2.data ?? [];
                print('Fallback obteve agendamentos pendentes: ${fallback.length}');
                if (fallback.isEmpty) return const Center(child: Text('Nenhum agendamento pendente'));
                return _buildListView(fallback);
              },
            );
          }

          return _buildListView(agendamentos);
        },
      ),
    );
  }

  Widget _buildListView(List<Agendamento> agendamentos) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: agendamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = agendamentos[index];

        final clienteNomeDoc = a.clienteNome;
        final servicoNomeDoc = a.servicoNome;

        if (clienteNomeDoc == null) _ensureClienteNome(a.clienteId);
        if (servicoNomeDoc == null) _ensureServicoNome(a.servicoId);

        final clienteNome = clienteNomeDoc ?? _clienteNomes[a.clienteId] ?? a.clienteId;
        final servicoNome = servicoNomeDoc ?? _servicoNomes[a.servicoId] ?? a.servicoId;

        return Card(
          child: ListTile(
            title: Text(servicoNome),
            subtitle: Text('$clienteNome • ${a.dataHora.toLocal()}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Confirmar',
                  onPressed: () async {
                    await FirebaseService.alterarStatusAgendamento(a.id, StatusAgendamento.concluido);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento confirmado')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Cancelar',
                  onPressed: () async {
                    await FirebaseService.alterarStatusAgendamento(a.id, StatusAgendamento.cancelado);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento cancelado')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
