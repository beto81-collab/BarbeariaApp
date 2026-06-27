import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class FotosScreen extends StatefulWidget {
  const FotosScreen({super.key});

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  List<String> _fotos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFotos();
  }

  Future<void> _carregarFotos() async {
    setState(() => _carregando = true);
    try {
      final urls = await FirebaseService.listarImagensVitrine();
      setState(() {
        _fotos = urls;
      });
    } catch (e) {
      debugPrint('Erro ao carregar fotos: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirFotoFullscreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FotoFullscreenScreen(fotos: _fotos, indiceInicial: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarFotos,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _fotos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: AppTheme.subTextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma foto disponível',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.subTextColor,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarFotos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _fotos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _abrirFotoFullscreen(index),
                        child: Hero(
                          tag: 'foto_$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _fotos[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppTheme.surfaceColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.surfaceColor,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppTheme.subTextColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FotoFullscreenScreen extends StatefulWidget {
  final List<String> fotos;
  final int indiceInicial;

  const _FotoFullscreenScreen({
    required this.fotos,
    required this.indiceInicial,
  });

  @override
  State<_FotoFullscreenScreen> createState() => _FotoFullscreenScreenState();
}

class _FotoFullscreenScreenState extends State<_FotoFullscreenScreen> {
  late final PageController _pageController;
  late int _indiceAtual;

  @override
  void initState() {
    super.initState();
    _indiceAtual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_indiceAtual + 1} / ${widget.fotos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.fotos.length,
        onPageChanged: (index) {
          setState(() => _indiceAtual = index);
        },
        itemBuilder: (context, index) {
          return Hero(
            tag: 'foto_$index',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.fotos[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
