import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../widgets/interactive_background.dart';
import '../services/firebase_service.dart';
import '../services/preferences_service.dart';
import 'cadastro_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Carregar credenciais salvas ao inicializar
  Future<void> _loadSavedCredentials() async {
    final credentials = await PreferencesService.getSavedCredentials();

    setState(() {
      _rememberMe = credentials['rememberMe'];
      if (_rememberMe) {
        _emailController.text = credentials['email'];
        _senhaController.text = credentials['password'];
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // HACK TEMPORÁRIO: Verificação direta para admin na web
      final email = _emailController.text.trim();
      final senha = _senhaController.text;

      // Salvar credenciais se o usuário quiser lembrar
      if (_rememberMe) {
        await PreferencesService.saveCredentials(
          email: email,
          password: senha,
          rememberMe: true,
        );
      } else {
        await PreferencesService.clearSavedCredentials();
      }

      if (email == 'admin@barbearia.com') {
        print('TENTATIVA DE LOGIN ADMIN DETECTADA!');
        try {
          // Tentar fazer login admin real no Firebase
          final user = await FirebaseService.fazerLogin(email, senha);
          if (user != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
            return;
          }
        } catch (e) {
          print('Login admin falhou: $e');
          // Se falhar, usar o hack anterior
          if (senha == 'admin123' && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
            return;
          }
        }
      }

      // Fazer login normal no Firebase
      final user = await FirebaseService.fazerLogin(email, senha);

      if (user != null && mounted) {
        // Navegar para o dashboard (será feito automaticamente pelo StreamBuilder no main.dart)
        // Não precisamos navegar manualmente pois o StreamBuilder detecta a mudança
      }
    } catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao fazer login';

        // Customizar mensagem baseada no erro
        if (e.toString().contains('user-not-found')) {
          mensagem = 'Usuário não encontrado';
        } else if (e.toString().contains('wrong-password')) {
          mensagem = 'Senha incorreta';
        } else if (e.toString().contains('invalid-email')) {
          mensagem = 'Email inválido';
        } else if (e.toString().contains('too-many-requests')) {
          mensagem = 'Muitas tentativas. Tente novamente mais tarde';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.08,
                  ), // Espaço do topo restaurado
                  // Logo da barbearia
                  const LogoCorteReal(size: 120),

                  const SizedBox(height: 20), //altura entre logo e texto
                  // Título
                  const Text(
                    'Sua experiência única',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.subTextColor,
                    ),
                  ),
                  const SizedBox(
                    height: 80,
                  ), // Espaço ajustado para centralizar o conjunto
                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Digite seu email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Digite um email válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo de senha
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Digite sua senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Checkbox "Lembrar-me"
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppTheme.secondaryColor,
                          checkColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Text(
                            'Lembrar email e senha',
                            style: TextStyle(
                              color: AppTheme.subTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botão de login
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                          : const Text('Entrar'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link para cadastro
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CadastroScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Não tem uma conta? Cadastre-se',
                      style: TextStyle(color: AppTheme.secondaryColor),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Link para esqueceu a senha
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperação de senha
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recuperação de senha em desenvolvimento',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Esqueceu sua senha?',
                      style: TextStyle(color: AppTheme.subTextColor),
                    ),
                  ),
                  
                  const SizedBox(height: 60), // Espaço ajustado antes do logo NETPIX
                  
                  // Logo NETPIX APKS no rodapé
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/NETPIX APKS.png',
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  const SizedBox(height: 20), // Espaço final
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
