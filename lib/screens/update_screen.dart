import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_version.dart';
import '../services/update_service.dart';
import '../widgets/logo_corte_real.dart';

class UpdateScreen extends StatefulWidget {
  final AppVersion availableUpdate;
  final bool isForceUpdate;

  const UpdateScreen({
    super.key,
    required this.availableUpdate,
    this.isForceUpdate = false,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          !widget.isForceUpdate, // Impede voltar se for update obrigatório
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header com logo
                const SizedBox(height: 120, child: LogoCorteReal()),
                const SizedBox(height: 40),

                // Card principal
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Ícone de atualização
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              widget.isForceUpdate
                                  ? Icons.system_update_alt
                                  : Icons.system_update,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Título
                          Text(
                            widget.isForceUpdate
                                ? 'Atualização Obrigatória!'
                                : 'Nova Versão Disponível!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Versão
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Versão ${widget.availableUpdate.version}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Notas da versão
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Novidades desta versão:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      widget.availableUpdate.releaseNotes,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botões de ação
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isUpdating) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Iniciando atualização...',
              style: TextStyle(color: AppTheme.textColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Botão principal (Atualizar)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download),
                const SizedBox(width: 8),
                Text(
                  widget.isForceUpdate
                      ? 'Atualizar Agora'
                      : 'Baixar Atualização',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botão secundário (apenas se não for obrigatório)
        if (!widget.isForceUpdate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipVersion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Pular Versão'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _remindLater,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Lembrar Depois'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _startUpdate() async {
    setState(() => _isUpdating = true);

    try {
      final success = await UpdateService.startUpdate(widget.availableUpdate);

      if (success) {
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Download iniciado! Verifique suas notificações.',
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Falha ao iniciar o download');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _skipVersion() async {
    await UpdateService.skipVersion(widget.availableUpdate.version);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _remindLater() {
    Navigator.of(context).pop();
  }
}

/// Dialog para mostrar atualização disponível
class UpdateDialog extends StatelessWidget {
  final AppVersion availableUpdate;
  final bool isForceUpdate;

  const UpdateDialog({
    super.key,
    required this.availableUpdate,
    this.isForceUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              isForceUpdate
                  ? 'Atualização Obrigatória'
                  : 'Nova Versão Disponível',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Versão ${availableUpdate.version}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Notas resumidas
            Text(
              availableUpdate.releaseNotes.length > 100
                  ? '${availableUpdate.releaseNotes.substring(0, 100)}...'
                  : availableUpdate.releaseNotes,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                if (!isForceUpdate) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Depois'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UpdateScreen(
                            availableUpdate: availableUpdate,
                            isForceUpdate: isForceUpdate,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ver Detalhes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
