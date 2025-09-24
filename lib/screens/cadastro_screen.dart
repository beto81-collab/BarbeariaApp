import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_corte_real.dart';
import '../models/usuario.dart';
import '../services/firebase_service.dart';
import '../utils/telefone_utils.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  DateTime? _dataNascimento;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _aceitaTermos = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceitaTermos) {
      _mostrarSnackBar('Você deve aceitar os termos de uso para continuar');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Criar objeto usuário
      final usuario = Usuario(
        id: '', // Será preenchido pelo Firebase
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        tipo: TipoUsuario.cliente,
        dataCadastro: DateTime.now(),
        dataNascimento: _dataNascimento, // Nova propriedade
      );

      // Registrar usuário no Firebase
      final user = await FirebaseService.registrarUsuario(
        _emailController.text.trim(),
        _senhaController.text,
        usuario,
      );

      if (user != null && mounted) {
        _mostrarDialogSucesso(usuario);
      }
    } catch (e) {
      if (mounted) {
        String mensagem = 'Erro ao cadastrar usuário';

        // Customizar mensagem baseada no erro
        if (e.toString().contains('email-already-in-use')) {
          mensagem = 'Este email já está cadastrado';
        } else if (e.toString().contains('weak-password')) {
          mensagem = 'A senha deve ter pelo menos 6 caracteres';
        } else if (e.toString().contains('invalid-email')) {
          mensagem = 'Email inválido';
        }

        _mostrarSnackBar(mensagem);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selecionarDataNascimento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18 anos atrás
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.secondaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataNascimento) {
      setState(() {
        _dataNascimento = picked;
        _dataNascimentoController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppTheme.errorColor),
    );
  }

  void _mostrarDialogSucesso(Usuario usuario) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Cadastro Realizado!',
            style: TextStyle(color: AppTheme.secondaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo(a), ${usuario.nome}!',
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seu cadastro foi realizado com sucesso. Você já pode fazer login e agendar seus horários na CORTE REAL.',
                style: TextStyle(color: AppTheme.textColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha dialog
                Navigator.of(context).pop(); // Volta para login
              },
              child: const Text(
                'Fazer Login',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _validarNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, digite seu nome completo';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Por favor, digite seu nome completo';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, digite seu email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Digite um email válido';
    }
    return null;
  }

  String? _validarTelefone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, digite seu telefone';
    }

    if (!TelefoneUtils.isValido(value)) {
      return 'Digite um telefone válido (10 ou 11 dígitos)';
    }

    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite uma senha';
    }
    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'A senha deve ter pelo menos uma letra minúscula, uma maiúscula e um número';
    }
    return null;
  }

  String? _validarConfirmaSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme sua senha';
    }
    if (value != _senhaController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Center(child: LogoCorteReal(size: 100)),

                const SizedBox(height: 20),

                // Título
                const Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),

                const Text(
                  'Preencha os dados abaixo para se cadastrar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.subTextColor),
                ),

                const SizedBox(height: 32),

                // Campo de nome
                TextFormField(
                  controller: _nomeController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    hintText: 'Digite seu nome completo',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: _validarNome,
                ),

                const SizedBox(height: 16),

                // Campo de email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Digite seu email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validarEmail,
                ),

                const SizedBox(height: 16),

                // Campo de telefone
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TelefoneInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: 'Digite seu telefone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: _validarTelefone,
                ),

                const SizedBox(height: 16),

                // Campo de data de nascimento
                TextFormField(
                  controller: _dataNascimentoController,
                  readOnly: true,
                  onTap: _selecionarDataNascimento,
                  decoration: const InputDecoration(
                    labelText: 'Data de Nascimento',
                    hintText: 'Selecione sua data de nascimento',
                    prefixIcon: Icon(Icons.cake),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (_dataNascimento == null) {
                      return 'Por favor, selecione sua data de nascimento';
                    }

                    // Verificar se tem pelo menos 13 anos
                    final agora = DateTime.now();
                    final idade = agora.year - _dataNascimento!.year;
                    final fezAniversario =
                        agora.month > _dataNascimento!.month ||
                        (agora.month == _dataNascimento!.month &&
                            agora.day >= _dataNascimento!.day);

                    final idadeFinal = fezAniversario ? idade : idade - 1;

                    if (idadeFinal < 13) {
                      return 'Você deve ter pelo menos 13 anos para se cadastrar';
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
                    hintText: 'Digite uma senha forte',
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
                  validator: _validarSenha,
                ),

                const SizedBox(height: 16),

                // Campo de confirmar senha
                TextFormField(
                  controller: _confirmaSenhaController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    hintText: 'Confirme sua senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: _validarConfirmaSenha,
                ),

                const SizedBox(height: 24),

                // Checkbox termos de uso
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceitaTermos,
                      onChanged: (value) {
                        setState(() {
                          _aceitaTermos = value ?? false;
                        });
                      },
                      activeColor: AppTheme.secondaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'Li e aceito os termos de uso e política de privacidade da CORTE REAL',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botão de cadastrar
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cadastrar,
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
                            'Criar Conta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Link para login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Já tem uma conta? Faça login',
                    style: TextStyle(color: AppTheme.secondaryColor),
                  ),
                ),

                const SizedBox(height: 24),

                // Texto sobre segurança
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.secondaryColor,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Seus dados estão seguros conosco',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Utilizamos criptografia para proteger suas informações pessoais',
                        style: TextStyle(
                          color: AppTheme.subTextColor,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
