import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../screens/update_screen.dart';
import '../models/app_version.dart';

class AppStartupWrapper extends StatefulWidget {
  final Widget child;

  const AppStartupWrapper({super.key, required this.child});

  @override
  State<AppStartupWrapper> createState() => _AppStartupWrapperState();
}

class _AppStartupWrapperState extends State<AppStartupWrapper> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Aguarda um pouco para o app carregar completamente
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Usa o novo sistema inteligente de verificação
      final update = await UpdateService.checkForUpdate();

      if (update != null && mounted) {
        // Se é atualização obrigatória, vai direto para tela de atualização
        if (update.isForceUpdate) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  UpdateScreen(availableUpdate: update, isForceUpdate: true),
            ),
          );
        } else {
          // Se é atualização opcional, mostra dialog
          _showUpdateDialog(update);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar atualizações: $e');
    }
  }

  void _showUpdateDialog(AppVersion update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          UpdateDialog(availableUpdate: update, isForceUpdate: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
