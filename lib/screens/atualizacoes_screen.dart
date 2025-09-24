import 'package:flutter/material.dart';
import '../models/app_version.dart';
import '../services/firebase_service.dart';

class AtualizacoesScreen extends StatefulWidget {
  const AtualizacoesScreen({super.key});

  @override
  State<AtualizacoesScreen> createState() => _AtualizacoesScreenState();
}

class _AtualizacoesScreenState extends State<AtualizacoesScreen> {
  AppVersion? _versao;
  bool _carregando = true;
  bool _forcando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarVersao();
  }

  Future<void> _carregarVersao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      _versao = await FirebaseService.buscarVersaoApp();
    } catch (e) {
      _erro = 'Erro ao buscar versão: $e';
    }
    setState(() => _carregando = false);
  }

  Future<void> _forcarAtualizacao() async {
    if (_versao == null) return;
    setState(() => _forcando = true);
    try {
      final nova = AppVersion(
        version: _versao!.version,
        buildNumber: _versao!.buildNumber,
        downloadUrl: _versao!.downloadUrl,
        releaseNotes: _versao!.releaseNotes,
        releaseDate: _versao!.releaseDate,
        isForceUpdate: true,
        minRequiredVersion: _versao!.minRequiredVersion,
      );
      await FirebaseService.atualizarVersaoApp(nova);
      await _carregarVersao();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Atualização forçada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao forçar atualização: $e')),
        );
      }
    }
    setState(() => _forcando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizações do App')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Text(_erro!))
          : _versao == null
          ? const Center(child: Text('Nenhuma versão encontrada.'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versão atual: ${_versao!.version} (build ${_versao!.buildNumber})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data de lançamento: ${_versao!.releaseDate.day.toString().padLeft(2, '0')}/${_versao!.releaseDate.month.toString().padLeft(2, '0')}/${_versao!.releaseDate.year}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notas da versão:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_versao!.releaseNotes),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Forçar atualização: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _versao!.isForceUpdate,
                        onChanged: _forcando
                            ? null
                            : (v) => _forcarAtualizacao(),
                      ),
                      if (_forcando) const SizedBox(width: 12),
                      if (_forcando)
                        const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Versão mínima obrigatória: ${_versao!.minRequiredVersion}',
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recarregar'),
                    onPressed: _carregarVersao,
                  ),
                ],
              ),
            ),
    );
  }
}
