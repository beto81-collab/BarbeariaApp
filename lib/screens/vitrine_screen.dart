import 'dart:io';
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
      setState(() {
        _imagensParaUpload.add(File(imagem.path));
      });
    }
  }

  Future<void> _adicionarImagemCamera() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.camera);
    if (imagem != null) {
      setState(() {
        _imagensParaUpload.add(File(imagem.path));
      });
    }
  }

  Future<void> _uploadImagens() async {
    setState(() => _carregando = true);
    for (final file in _imagensParaUpload) {
      await FirebaseService.uploadImagemVitrine(file);
    }
    _imagensParaUpload.clear();
    await _carregarImagensVitrine();
    setState(() => _carregando = false);
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
                        onPressed: _adicionarImagemGaleria,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                        onPressed: _adicionarImagemCamera,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Enviar'),
                        onPressed: _imagensParaUpload.isEmpty
                            ? null
                            : _uploadImagens,
                      ),
                    ],
                  ),
                ),
                if (_imagensParaUpload.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagensParaUpload.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            Image.file(
                              _imagensParaUpload[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
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
                        ),
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
