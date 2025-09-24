import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../services/firebase_service.dart';

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
      if (usuario.presenteAniversario != null &&
          usuario.presenteAniversario!['resgatado'] != true) {
        _mostrarPopupAniversario(usuario.presenteAniversario!);
      }
    } catch (e) {
      print('Erro ao verificar presente de aniversário: $e');
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
      presenteAtualizado['resgatadoEm'] = DateTime.now();

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
      body: IndexedStack(index: _selectedIndex, children: [_buildConfigTab()]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    return Center(
      child: IconButton(
        icon: const Icon(
          Icons.settings,
          size: 64,
          color: AppTheme.subTextColor,
        ),
        onPressed: () {
          // Ação de configuração
        },
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
