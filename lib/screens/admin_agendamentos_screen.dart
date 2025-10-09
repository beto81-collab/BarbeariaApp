import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/agendamento.dart';
import '../services/firebase_service.dart';

class AdminAgendamentosScreen extends StatefulWidget {
  const AdminAgendamentosScreen({super.key});

  @override
  State<AdminAgendamentosScreen> createState() =>
      _AdminAgendamentosScreenState();
}

class _AdminAgendamentosScreenState extends State<AdminAgendamentosScreen> {
  Color _statusColor(StatusAgendamento status) {
    switch (status) {
      case StatusAgendamento.confirmado:
        return const Color.fromARGB(255, 30, 177, 1);
      case StatusAgendamento.concluido:
        return const Color.fromARGB(255, 0, 119, 255);
      case StatusAgendamento.cancelado:
        return Colors.red;
      case StatusAgendamento.agendado:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

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
            print(
              'Erro no stream de agendamentos pendentes: ${snapshot.error}',
            );
            return Center(
              child: Text('Erro ao carregar agendamentos: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final agendamentos = snapshot.data ?? [];
          print(
            'Stream agendamentos pendentes - documentos recebidos: ${agendamentos.length}',
          );

          if (agendamentos.isEmpty) {
            return FutureBuilder<List<Agendamento>>(
              future: FirebaseService.obterTodosAgendamentos().then(
                (list) => list
                    .where(
                      (a) =>
                          (a.status.name == 'pendente' ||
                          a.status == StatusAgendamento.agendado),
                    )
                    .toList(),
              ),
              builder: (context, snap2) {
                if (snap2.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final fallback = snap2.data ?? [];
                print(
                  'Fallback obteve agendamentos pendentes: ${fallback.length}',
                );
                if (fallback.isEmpty)
                  return const Center(
                    child: Text('Nenhum agendamento pendente'),
                  );
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

        final clienteNome =
            clienteNomeDoc ?? _clienteNomes[a.clienteId] ?? a.clienteId;
        final servicoNome =
            servicoNomeDoc ?? _servicoNomes[a.servicoId] ?? a.servicoId;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.indigo, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clienteNome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      a.toJson()['clienteTelefone']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.design_services,
                      color: Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      servicoNome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${a.dataHora.day.toString().padLeft(2, '0')}/'
                      '${a.dataHora.month.toString().padLeft(2, '0')}/'
                      '${a.dataHora.year} • ${a.dataHora.hour.toString().padLeft(2, '0')}:${a.dataHora.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${a.toJson()['duracao'] ?? ''} min',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Status: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(a.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.status.name,
                        style: TextStyle(
                          color: _statusColor(a.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.blue),
                      tooltip: 'Confirmar',
                      onPressed: () async {
                        await FirebaseService.alterarStatusAgendamento(
                          a.id,
                          StatusAgendamento.confirmado,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agendamento confirmado'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Concluído',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Concluir agendamento'),
                            content: const Text(
                              'Deseja marcar este agendamento como concluído? Isso irá removê-lo do sistema.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Concluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseService.removerAgendamento(a.id);

                            // Ao concluir um agendamento, adicionar 1 ponto ao usuário
                            // apenas se ele participa do Programa de Pontos.
                            try {
                              final userMap = await FirebaseService.obterUsuarioMapPorId(a.clienteId);
                              final participa = (userMap?['participaProgramaPontos'] ?? false) as bool;
                              if (participa) {
                                await FirebaseService.incrementarPontosFidelidade(a.clienteId, 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Agendamento concluído e ponto adicionado ao cliente',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Agendamento concluído',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Se houver erro ao tentar adicionar ponto, apenas notificar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Agendamento concluído (erro ao adicionar ponto)'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro ao concluir agendamento'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Cancelar',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text(
                              'Deseja remover este agendamento permanentemente do sistema?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Remover'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseService.removerAgendamento(a.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Agendamento removido'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro ao remover agendamento'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
