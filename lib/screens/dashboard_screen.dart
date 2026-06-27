import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../services/firebase_service.dart';
import 'produtos_cliente_screen.dart';
import 'fotos/fotos_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Verificar presente de aniversário quando iniciar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarPresenteAniversario();
    });
  }

  Future<void> _verificarPresenteAniversario() async {
    try {
      final usuario = await FirebaseService.obterUsuarioAtual();
      if (usuario == null) return;

      // Verificar se é aniversário hoje usando o método já existente no modelo
      if (!usuario.isAniversarioHoje) {
        return; // Não é aniversário hoje
      }

      // Verificar se tem presente pendente
      if (usuario.presenteAniversario != null) {
        final presente = usuario.presenteAniversario!;
        final resgatado = presente['resgatado'] == true;
        final entregue = presente['entregue'] == true;
        // checar expiração se existe
        bool dentroPrazo = true;
        if (presente['expiraEm'] != null) {
          try {
            final exp = presente['expiraEm'];
            DateTime expDate;
            // Caso venha como string ISO
            if (exp is String) {
              expDate = DateTime.parse(exp);
            } else if (exp != null &&
                exp is Map<String, dynamic> &&
                (exp['_seconds'] != null || exp['seconds'] != null)) {
              // Timestamp serializado como map vindo do build/web
              final seconds = exp['_seconds'] ?? exp['seconds'];
              expDate = DateTime.fromMillisecondsSinceEpoch(
                (seconds as int) * 1000,
              );
            } else if (exp != null && exp is DateTime) {
              expDate = exp;
            } else if (exp != null && exp is num) {
              expDate = DateTime.fromMillisecondsSinceEpoch(exp.toInt());
            } else {
              expDate = DateTime.parse(exp.toString());
            }
            dentroPrazo = DateTime.now().isBefore(expDate);
          } catch (e) {
            dentroPrazo = true;
          }
        }

        if (!resgatado && !entregue && dentroPrazo) {
          _mostrarPopupAniversario(presente);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar presente de aniversário: $e');
    }
  }

  void _mostrarPopupAniversario(Map<String, dynamic> presente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cake, color: Colors.pink),
            const SizedBox(width: 8),
            const Expanded(child: Text('🎉 Parabéns pelo seu aniversário!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Você ganhou um presente especial:'),
            const SizedBox(height: 16),

            // Mostrar produto se existir
            if (presente['produto'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎁 Produto:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(presente['produto']['nome']),
                    if (presente['produto']['precoEspecial'] != null) ...[
                      Text(
                        'Preço especial: R\$ ${presente['produto']['precoEspecial'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (presente['produto']['precoOriginal'] !=
                          presente['produto']['precoEspecial'])
                        Text(
                          'De: R\$ ${presente['produto']['precoOriginal'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Mostrar serviço se existir
            if (presente['servico'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✂️ Serviço:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(presente['servico']['nome']),
                    if (presente['servico']['precoEspecial'] != null) ...[
                      Text(
                        'Preço especial: R\$ ${presente['servico']['precoEspecial'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (presente['servico']['precoOriginal'] !=
                          presente['servico']['precoEspecial'])
                        Text(
                          'De: R\$ ${presente['servico']['precoOriginal'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],

            if (presente['produto'] == null && presente['servico'] == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  '🎈 Parabéns pelo seu aniversário! Desejamos um dia especial!',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _resgatarPresente();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Resgatar presente!'),
          ),
        ],
      ),
    );
  }

  Future<void> _resgatarPresente() async {
    try {
      final usuario = await FirebaseService.obterUsuarioAtual();
      if (usuario == null) return;

      // Marcar presente como resgatado
      final presenteAtualizado = Map<String, dynamic>.from(
        usuario.presenteAniversario!,
      );
      presenteAtualizado['resgatado'] = true;
      presenteAtualizado['resgatadoEm'] = DateTime.now().toIso8601String();

      await FirebaseService.atualizarPresenteAniversario(
        usuario.id,
        presenteAtualizado,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Presente resgatado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resgatar presente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LogoCorteRealHorizontal(height: 50),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ação de configuração
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const ProdutosClienteScreen(),
          _buildConfigTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produtos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const LogoCorteReal(size: 100),
          const SizedBox(height: 20),
          Text(
            'Bem-vindo à CORTE REAL!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Explore nossos produtos e serviços',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.subTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _HomeCard(
            icon: Icons.photo_library,
            label: 'Fotos',
            descricao: 'Veja nosso portfólio de cortes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FotosScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Meu Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para perfil do usuário
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Meus Agendamentos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para agendamentos
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Contato'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Mostrar informações de contato
              _mostrarContato();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await FirebaseService.logout();
            },
          ),
        ],
      ),
    );
  }

  void _mostrarContato() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contato'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Telefone: (11) 99999-9999'),
            SizedBox(height: 8),
            Text('📧 E-mail: contato@cortereal.com.br'),
            SizedBox(height: 8),
            Text('📍 Endereço: Rua Exemplo, 123'),
            Text('   Centro - São Paulo/SP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descricao;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.label,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppTheme.secondaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corte Real',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
