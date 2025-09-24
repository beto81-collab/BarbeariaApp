import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import removido: fl_cloud_storage
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:file_picker/file_picker.dart';
import '../services/firebase_service.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../models/promocao.dart';
import '../models/horario.dart';
import 'backup_auto_config.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  Timer? _timerAutoBackup;

  @override
  void initState() {
    super.initState();
    _iniciarTimerAutoBackup();
  }

  @override
  void dispose() {
    _timerAutoBackup?.cancel();
    super.dispose();
  }

  void _iniciarTimerAutoBackup() {
    _timerAutoBackup?.cancel();
    if (BackupAutoConfig.automatico) {
      _timerAutoBackup = Timer.periodic(BackupAutoConfig.intervalo, (_) async {
        if (BackupAutoConfig.houveAlteracao) {
          await _enviarBackupFirebase();
          BackupAutoConfig.houveAlteracao = false;
        }
      });
    }
  }

  Future<void> _enviarBackupFirebase() async {
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    try {
      final dados = await _exportarDados();
      final jsonStr = jsonEncode(dados);
      final url = await FirebaseService.uploadBackupJson(jsonStr);
      setState(() => _mensagem = 'Backup enviado para o Firebase!\nURL: $url');
    } catch (e) {
      setState(() => _mensagem = 'Erro ao enviar para o Firebase: $e');
    }
    setState(() => _carregando = false);
  }

  bool _carregando = false;
  String? _mensagem;

  Future<Map<String, dynamic>> _exportarDados() async {
    final produtos = await FirebaseService.obterProdutos();
    final servicos = await FirebaseService.obterServicos();
    final promocoes = await FirebaseService.buscarPromocoes();
    return {
      'produtos': produtos.map((e) => e.toJson()).toList(),
      'servicos': servicos.map((e) => e.toJson()).toList(),
      'promocoes': promocoes.map((e) => e.toJson()).toList(),
    };
  }

  Future<void> _exportarBackupLocal() async {
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    try {
      final dados = await _exportarDados();
      final jsonStr = jsonEncode(dados);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backup_barbearia.json');
      await file.writeAsString(jsonStr);
      await Share.shareFiles([file.path], text: 'Backup do app Corte Real');
      setState(() => _mensagem = 'Backup exportado com sucesso!');
    } catch (e) {
      setState(() => _mensagem = 'Erro ao exportar: $e');
    }
    setState(() => _carregando = false);
  }

  Future<void> _importarBackupLocal() async {
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    try {
      FilePickerResult? result;
      if (!kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else {
        setState(
          () => _mensagem = 'Importação de arquivo não suportada no navegador.',
        );
        setState(() => _carregando = false);
        return;
      }
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final dados = jsonDecode(content);

        // --- RESTAURAÇÃO AUTOMÁTICA ---
        // Limpar coleções existentes
        await _limparColecoes();

        // Restaurar produtos
        if (dados['produtos'] != null) {
          for (var p in dados['produtos']) {
            await FirebaseService.adicionarProduto(
              Produto.fromJson(Map<String, dynamic>.from(p)),
            );
          }
        }
        // Restaurar serviços
        if (dados['servicos'] != null) {
          for (var s in dados['servicos']) {
            await FirebaseService.adicionarServico(
              Servico.fromJson(Map<String, dynamic>.from(s)),
            );
          }
        }
        // Restaurar promoções
        if (dados['promocoes'] != null) {
          for (var pr in dados['promocoes']) {
            await FirebaseService.criarPromocao(
              Promocao.fromJson(Map<String, dynamic>.from(pr)),
            );
          }
        }
        // Restaurar horários
        if (dados['horarios'] != null) {
          final horarios = (dados['horarios'] as List)
              .map(
                (h) =>
                    HorarioFuncionamento.fromJson(Map<String, dynamic>.from(h)),
              )
              .toList();
          await FirebaseService.salvarHorariosFuncionamento(horarios);
        }

        setState(() => _mensagem = 'Backup restaurado com sucesso!');
      } else {
        setState(() => _mensagem = 'Importação cancelada.');
      }
    } catch (e) {
      setState(() => _mensagem = 'Erro ao importar: $e');
    }
    setState(() => _carregando = false);
  }

  Future<void> _limparColecoes() async {
    // Limpar produtos
    final produtos = await FirebaseService.obterProdutos();
    for (var p in produtos) {
      await FirebaseService.removerProduto(p.id);
    }
    // Limpar serviços
    final servicos = await FirebaseService.obterServicos();
    for (var s in servicos) {
      await FirebaseService.removerServico(s.id);
    }
    // Limpar promoções
    final promocoes = await FirebaseService.buscarPromocoes();
    for (var pr in promocoes) {
      await FirebaseService.removerPromocao(pr.id);
    }
    // Limpar horários: sobrescreve ao salvar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup de Dados')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackupAutoConfigWidget(onConfigChanged: _iniciarTimerAutoBackup),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Exportar backup'),
              onPressed: _carregando ? null : _exportarBackupLocal,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Importar backup'),
              onPressed: _carregando ? null : _importarBackupLocal,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Enviar backup'),
              onPressed: _carregando ? null : _enviarBackupFirebase,
            ),
            const SizedBox(height: 24),
            if (_carregando) const Center(child: CircularProgressIndicator()),
            if (_mensagem != null) ...[
              const SizedBox(height: 16),
              Text(
                _mensagem!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
