import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';

class VitrineScreen extends StatefulWidget {
  const VitrineScreen({super.key});

  @override
  State<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends State<VitrineScreen> {
  List<String> _imagensVitrine = [];
  final List<File> _imagensParaUpload = [];
  final List<Uint8List> _imagensBytesWeb = [];
  // Mapas para rastrear progresso e status por índice
  final Map<int, double> _progressoPorIndice = {};
  final Map<int, bool> _sucessoPorIndice = {};
  final ImagePicker _picker = ImagePicker();

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarImagensVitrine();
  }

  Future<void> _carregarImagensVitrine() async {
    setState(() => _carregando = true);
    final urls = await FirebaseService.listarImagensVitrine();
    setState(() {
      _imagensVitrine = urls;
      _carregando = false;
    });
  }

  Future<void> _adicionarImagemGaleria() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      if (kIsWeb) {
        final bytes = await imagem.readAsBytes();
        setState(() {
          _imagensBytesWeb.add(bytes);
        });
      } else {
        setState(() {
          _imagensParaUpload.add(File(imagem.path));
        });
      }
    }
  }

  Future<void> _adicionarImagemCamera() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.camera);
    if (imagem != null) {
      if (kIsWeb) {
        final bytes = await imagem.readAsBytes();
        setState(() {
          _imagensBytesWeb.add(bytes);
        });
      } else {
        setState(() {
          _imagensParaUpload.add(File(imagem.path));
        });
      }
    }
  }

  Future<void> _uploadImagens() async {
    setState(() => _carregando = true);
    try {
      if (kIsWeb) {
        // Upload com progresso por arquivo (web)
        for (var i = 0; i < _imagensBytesWeb.length; i++) {
          final bytes = _imagensBytesWeb[i];
          _progressoPorIndice[i] = 0.0;
          _sucessoPorIndice[i] = false;
          await FirebaseService.uploadImagemVitrineBytesWithProgress(
            bytes,
            onProgress: (snapshot) {
              final progress = snapshot.totalBytes > 0
                  ? snapshot.bytesTransferred / snapshot.totalBytes
                  : 0.0;
              setState(() => _progressoPorIndice[i] = progress);
            },
          );
          _sucessoPorIndice[i] = true;
        }
        _imagensBytesWeb.clear();
        _progressoPorIndice.clear();
      } else {
        // Upload com progresso por arquivo (mobile/desktop)
        for (var i = 0; i < _imagensParaUpload.length; i++) {
          final file = _imagensParaUpload[i];
          _progressoPorIndice[i] = 0.0;
          _sucessoPorIndice[i] = false;
          await FirebaseService.uploadImagemVitrineFileWithProgress(
            file,
            onProgress: (snapshot) {
              final progress = snapshot.totalBytes > 0
                  ? snapshot.bytesTransferred / snapshot.totalBytes
                  : 0.0;
              setState(() => _progressoPorIndice[i] = progress);
            },
          );
          _sucessoPorIndice[i] = true;
        }
        _imagensParaUpload.clear();
        _progressoPorIndice.clear();
      }
      await _carregarImagensVitrine();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload concluído com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagens: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _removerImagemVitrine(int index) async {
    final url = _imagensVitrine[index];
    setState(() => _carregando = true);
    await FirebaseService.removerImagemVitrine(url);
    await _carregarImagensVitrine();
    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitrine de Serviços')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                        onPressed: _carregando ? null : _adicionarImagemGaleria,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                        onPressed: _carregando ? null : _adicionarImagemCamera,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: _carregando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label:
                            Text(_carregando ? 'Enviando...' : 'Enviar'),
                        onPressed: (_imagensParaUpload.isEmpty &&
                                _imagensBytesWeb.isEmpty) ||
                            _carregando
                            ? null
                            : _uploadImagens,
                      ),
                    ],
                  ),
                ),
                if (_imagensParaUpload.isNotEmpty ||
                    _imagensBytesWeb.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _imagensParaUpload.length + _imagensBytesWeb.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index < _imagensParaUpload.length) {
                            return Stack(
                              children: [
                                Image.file(
                                  _imagensParaUpload[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                                // Overlay de progresso/acao
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: _progressoPorIndice.containsKey(index)
                                      ? Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${(_progressoPorIndice[index]! * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imagensParaUpload.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            );
                          } else {
                            final webIndex = index - _imagensParaUpload.length;
                            return Stack(
                              children: [
                                Image.memory(
                                  _imagensBytesWeb[webIndex],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: _progressoPorIndice.containsKey(webIndex)
                                      ? Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${(_progressoPorIndice[webIndex]! * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imagensBytesWeb.removeAt(webIndex);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _imagensVitrine.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _imagensVitrine[index],
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removerImagemVitrine(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
