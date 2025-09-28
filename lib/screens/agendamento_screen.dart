import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/barbeiro.dart';
import '../models/servico.dart';
import '../models/agendamento.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({super.key});

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores e variáveis de estado
  Barbeiro? _barbeiroSelecionado;
  Servico? _servicoSelecionado;
  DateTime? _dataSelecionada;
  String? _horarioSelecionado;
  final TextEditingController _observacoesController = TextEditingController();
  bool _isLoading = false;

  // Dados mock - em uma aplicação real, viriam de uma API
  final List<Barbeiro> _barbeiros = [
    Barbeiro(
      id: '1',
      nome: 'Carlos Silva',
      especialidade: 'Cortes Clássicos',
      avaliacao: 4.9,
      foto: 'assets/images/barbeiro1.jpg',
      telefone: '(11) 99999-1111',
      email: 'carlos@cortereal.com',
    ),
    Barbeiro(
      id: '2',
      nome: 'Roberto Santos',
      especialidade: 'Barba e Bigode',
      avaliacao: 4.8,
      foto: 'assets/images/barbeiro2.jpg',
      telefone: '(11) 99999-2222',
      email: 'roberto@cortereal.com',
    ),
    Barbeiro(
      id: '3',
      nome: 'Fernando Costa',
      especialidade: 'Cortes Modernos',
      avaliacao: 4.7,
      foto: 'assets/images/barbeiro3.jpg',
      telefone: '(11) 99999-3333',
      email: 'fernando@cortereal.com',
    ),
  ];

  final List<Servico> _servicos = [
    Servico(
      id: '1',
      nome: 'Corte Masculino',
      descricao: 'Corte clássico ou moderno',
      preco: 25.0,
      duracao: 30,
      icone: 'cut',
    ),
    Servico(
      id: '2',
      nome: 'Barba Completa',
      descricao: 'Aparar e modelar barba',
      preco: 20.0,
      duracao: 25,
      icone: 'beard',
    ),
    Servico(
      id: '3',
      nome: 'Corte + Barba',
      descricao: 'Pacote completo',
      preco: 40.0,
      duracao: 50,
      icone: 'package',
    ),
    Servico(
      id: '4',
      nome: 'Lavagem + Corte',
      descricao: 'Lavagem com produtos premium',
      preco: 35.0,
      duracao: 45,
      icone: 'wash',
    ),
  ];

  final List<String> _horariosDisponiveis = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
  ];

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      confirmText: 'OK', // ou '' / ' ' conforme preferir
      builder: (ctx, child) {
        final base = Theme.of(ctx);
        return Theme(
          data: base.copyWith(
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _horarioSelecionado = null; // Reset horário quando muda data
      });
    }
  }

  Future<void> _confirmarAgendamento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_barbeiroSelecionado == null) {
      _mostrarSnackBar('Por favor, selecione um barbeiro');
      return;
    }

    if (_servicoSelecionado == null) {
      _mostrarSnackBar('Por favor, selecione um serviço');
      return;
    }

    if (_dataSelecionada == null) {
      _mostrarSnackBar('Por favor, selecione uma data');
      return;
    }

    if (_horarioSelecionado == null) {
      _mostrarSnackBar('Por favor, selecione um horário');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obter usuário atual
      final usuarioAtual = await FirebaseService.obterUsuarioAtual();
      if (usuarioAtual == null) {
        throw Exception('Usuário não encontrado');
      }

      // Criar objeto agendamento
      final agendamento = Agendamento(
        id: '', // Será preenchido pelo Firebase
        clienteId: usuarioAtual.id,
        barbeiroId: _barbeiroSelecionado!.id,
        servicoId: _servicoSelecionado!.id,
        dataHora: DateTime(
          _dataSelecionada!.year,
          _dataSelecionada!.month,
          _dataSelecionada!.day,
          int.parse(_horarioSelecionado!.split(':')[0]),
          int.parse(_horarioSelecionado!.split(':')[1]),
        ),
        status: StatusAgendamento.agendado,
        observacoes: _observacoesController.text,
        valor: _servicoSelecionado!.preco,
      );

      // Salvar no Firebase
      final agendamentoId = await FirebaseService.criarAgendamento(agendamento);

      // Criar agendamento com ID correto
      final agendamentoFinal = Agendamento(
        id: agendamentoId,
        clienteId: agendamento.clienteId,
        barbeiroId: agendamento.barbeiroId,
        servicoId: agendamento.servicoId,
        dataHora: agendamento.dataHora,
        status: agendamento.status,
        observacoes: agendamento.observacoes,
        valor: agendamento.valor,
      );

      // Enviar notificação de confirmação
      await NotificationService.notificarAgendamentoCriado(
        agendamento: agendamentoFinal,
        usuario: usuarioAtual,
      );

      // Mostrar dialog de confirmação
      if (mounted) {
        _mostrarDialogConfirmacao(agendamentoFinal);
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Erro ao criar agendamento: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppTheme.errorColor),
    );
  }

  void _mostrarDialogConfirmacao(Agendamento agendamento) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Agendamento Confirmado!',
            style: TextStyle(color: AppTheme.secondaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barbeiro: ${_barbeiroSelecionado!.nome}',
                style: const TextStyle(color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Serviço: ${_servicoSelecionado!.nome}',
                style: const TextStyle(color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Data: ${_formatarData(agendamento.dataHora)}',
                style: const TextStyle(color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Horário: ${_formatarHorario(agendamento.dataHora)}',
                style: const TextStyle(color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor: R\$ ${agendamento.valor.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Voltar para dashboard
              },
              child: const Text(
                'OK',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarHorario(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção de Barbeiro
              const Text(
                'Escolha o Barbeiro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _barbeiros.length,
                  itemBuilder: (context, index) {
                    final barbeiro = _barbeiros[index];
                    final isSelected = _barbeiroSelecionado?.id == barbeiro.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _barbeiroSelecionado = barbeiro;
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.secondaryColor.withOpacity(0.2)
                              : AppTheme.surfaceColor,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: AppTheme.secondaryColor,
                              child: Text(
                                barbeiro.nome.substring(0, 2).toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              barbeiro.nome.split(' ')[0],
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppTheme.secondaryColor,
                                ),
                                Text(
                                  ' ${barbeiro.avaliacao}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Seleção de Serviço
              const Text(
                'Escolha o Serviço',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _servicos.length,
                itemBuilder: (context, index) {
                  final servico = _servicos[index];
                  final isSelected = _servicoSelecionado?.id == servico.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _servicoSelecionado = servico;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryColor.withOpacity(0.2)
                            : AppTheme.surfaceColor,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servico.nome,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.secondaryColor
                                        : AppTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  servico.descricao,
                                  style: const TextStyle(
                                    color: AppTheme.subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${servico.duracao} min',
                                  style: const TextStyle(
                                    color: AppTheme.subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'R\$ ${servico.preco.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.secondaryColor
                                  : AppTheme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Seleção de Data
              const Text(
                'Escolha a Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selecionarData,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dataSelecionada != null
                          ? AppTheme.secondaryColor
                          : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dataSelecionada != null
                            ? _formatarData(_dataSelecionada!)
                            : 'Selecionar data',
                        style: TextStyle(
                          color: _dataSelecionada != null
                              ? AppTheme.textColor
                              : AppTheme.subTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Seleção de Horário
              if (_dataSelecionada != null) ...[
                const Text(
                  'Escolha o Horário',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _horariosDisponiveis.map((horario) {
                    final isSelected = _horarioSelecionado == horario;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _horarioSelecionado = horario;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          horario,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Campo de observações
              const Text(
                'Observações (opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Alguma observação especial?',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // Botão de confirmar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarAgendamento,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirmar Agendamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
