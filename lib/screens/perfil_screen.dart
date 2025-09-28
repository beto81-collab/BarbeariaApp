import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../models/usuario.dart';
import '../models/agendamento.dart';
import '../services/firebase_service.dart';
import '../utils/telefone_utils.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  List<Agendamento> _agendamentos = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers para edição
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosPerfil() async {
    try {
      setState(() => _isLoading = true);

      // Carregar dados do usuário
      final usuario = await FirebaseService.obterUsuarioAtual();

      // Carregar agendamentos do usuário
      final agendamentos = await FirebaseService.obterAgendamentosUsuario();

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _agendamentos = agendamentos;
        _isLoading = false;

        // Preencher controllers para edição
        if (usuario != null) {
          _nomeController.text = usuario.nome;
          _telefoneController.text = usuario.telefone;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro ao carregar perfil: $e', isError: true);
    }
  }

  Future<void> _salvarPerfil() async {
    if (_usuario == null) return;

    try {
      setState(() => _isLoading = true);

      // Criar usuário atualizado
      final usuarioAtualizado = Usuario(
        id: _usuario!.id,
        nome: _nomeController.text.trim(),
        email: _usuario!.email, // Email não pode ser alterado
        telefone: _telefoneController.text.trim(),
        foto: _usuario!.foto,
        tipo: _usuario!.tipo,
        dataCadastro: _usuario!.dataCadastro,
      );

      // Salvar no Firebase
      await FirebaseService.atualizarUsuario(usuarioAtualizado);

      if (!mounted) return;
      setState(() {
        _usuario = usuarioAtualizado;
        _isEditing = false;
        _isLoading = false;
      });

      _mostrarSnackBar('Perfil atualizado com sucesso!');
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro ao salvar perfil: $e', isError: true);
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  void _mostrarDialogLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Confirmar Saída',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: const Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService.logout();
              if (mounted) {
                Navigator.pop(context); // Volta para tela anterior
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDadosPessoais() {
    if (_usuario == null) return const SizedBox();

    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dados Pessoais',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(
                      Icons.edit,
                      color: AppTheme.secondaryColor,
                    ),
                    label: const Text(
                      'Editar',
                      style: TextStyle(color: AppTheme.secondaryColor),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isEditing) ...[
              // Modo de edição
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneInputFormatter()],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // Restaurar valores originais
                        _nomeController.text = _usuario!.nome;
                        _telefoneController.text = _usuario!.telefone;
                      });
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _salvarPerfil,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
            ] else ...[
              // Modo de visualização
              _buildInfoItem(
                icon: Icons.person,
                titulo: 'Nome',
                valor: _usuario!.nome,
              ),

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.email,
                titulo: 'Email',
                valor: _usuario!.email,
              ),

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.phone,
                titulo: 'Telefone',
                valor: TelefoneUtils.formatarTelefone(_usuario!.telefone),
              ),

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.calendar_today,
                titulo: 'Membro desde',
                valor:
                    '${_usuario!.dataCadastro.day}/${_usuario!.dataCadastro.month}/${_usuario!.dataCadastro.year}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppTheme.subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valor,
                style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstatisticas() {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildEstatisticaItem(
                    titulo: 'Total de Agendamentos',
                    valor: _agendamentos.length.toString(),
                    icon: Icons.event,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstatisticaItem(
                    titulo: 'Serviços Concluídos',
                    valor: _agendamentos
                        .where((a) => a.status == StatusAgendamento.concluido)
                        .length
                        .toString(),
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticaItem({
    required String titulo,
    required String valor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondaryColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUltimosAgendamentos() {
    if (_agendamentos.isEmpty) return const SizedBox();

    // Pegar os 3 últimos agendamentos
    final ultimosAgendamentos = _agendamentos.take(3).toList();

    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimos Agendamentos',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_agendamentos.length > 3)
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(color: AppTheme.secondaryColor),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            ...ultimosAgendamentos.map(_buildAgendamentoItem),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentoItem(Agendamento agendamento) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha((0.05 * 255).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.secondaryColor.withAlpha((0.2 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(agendamento.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${agendamento.dataHora.day}/${agendamento.dataHora.month}/${agendamento.dataHora.year}',
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    agendamento.status.label,
                    style: TextStyle(
                      color: _getStatusColor(agendamento.status),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${agendamento.valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StatusAgendamento status) {
    switch (status) {
      case StatusAgendamento.agendado:
        return Colors.blue;
      case StatusAgendamento.confirmado:
        return Colors.green;
      case StatusAgendamento.emAndamento:
        return Colors.orange;
      case StatusAgendamento.concluido:
        return AppTheme.successColor;
      case StatusAgendamento.cancelado:
        return AppTheme.errorColor;
      case StatusAgendamento.naoCompareceu:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: _mostrarDialogLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDadosPerfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar e nome
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.secondaryColor,
                          child: _usuario?.foto != null
                              ? ClipOval(
                                  child: Image.network(
                                    _usuario!.foto!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  _usuario?.nome
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (_usuario != null && !_isEditing) ...[
                          Text(
                            _usuario!.nome,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          Text(
                            _usuario!.tipo.label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.subTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dados pessoais
                    _buildDadosPessoais(),

                    const SizedBox(height: 16),

                    // Estatísticas
                    _buildEstatisticas(),

                    const SizedBox(height: 16),

                    // Últimos agendamentos
                    _buildUltimosAgendamentos(),

                    const SizedBox(height: 32),

                    // Logo no final
                    const Center(child: LogoCorteReal(size: 60)),
                  ],
                ),
              ),
            ),
    );
  }
}
