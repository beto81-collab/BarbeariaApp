import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/usuario.dart';
import '../services/firebase_service.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes Cadastrados')),
      body: FutureBuilder<List<Usuario>>(
        future: FirebaseService.buscarClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clientes = snapshot.data ?? [];
          if (clientes.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              final onSurface = Theme.of(context).colorScheme.onSurface;
              final lighter = onSurface.withAlpha(230); // tom mais claro e legível no tema escuro
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(cliente.nome),
                subtitle: InkWell(
                  onTap: () => _showEmailActions(context, cliente.email),
                  child: Text(
                    cliente.email.isNotEmpty ? cliente.email : 'E-mail não informado',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: lighter),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: InkWell(
                  onTap: () => _showPhoneActions(context, cliente.telefone),
                  child: Text(
                    cliente.telefone.isNotEmpty ? cliente.telefone : '—',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: lighter),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () => _showClienteDetalhe(context, cliente),
              );
            },
          );
        },
      ),
    );
  }

  void _showClienteDetalhe(BuildContext context, Usuario cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cliente.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('E-mail: '),
                Flexible(
                  child: InkWell(
                    onTap: () => _showEmailActions(context, cliente.email),
                    child: Text(
                      cliente.email.isNotEmpty ? cliente.email : 'Não informado',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(230)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Telefone: '),
                Flexible(
                  child: InkWell(
                    onTap: () => _showPhoneActions(context, cliente.telefone),
                    child: Text(
                      cliente.telefone.isNotEmpty ? cliente.telefone : 'Não informado',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(230)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Data de nascimento: '
              '${cliente.dataNascimento != null ? _formatarData(cliente.dataNascimento!) : 'Não informado'}',
            ),
            const SizedBox(height: 8),
            Text('ID: ${cliente.id}'),
            const SizedBox(height: 8),
            Text('Tipo: ${cliente.tipo.name}'),
            const SizedBox(height: 8),
            Text('Cadastro: ${cliente.dataCadastro.toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showEmailActions(BuildContext context, String? email) {
    if (email == null || email.isEmpty) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar e-mail'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: email));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Abrir app de e-mail'),
              onTap: () {
                final uri = 'mailto:$email';
                try {
                  launchUrlString(uri);
                } catch (_) {}
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneActions(BuildContext context, String? phone) {
    if (phone == null || phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar telefone'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: cleaned));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Abrir WhatsApp'),
              onTap: () {
                final uri = 'https://wa.me/$cleaned';
                try {
                  launchUrlString(uri);
                } catch (_) {}
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('Ligar'),
              onTap: () {
                final uri = 'tel:$cleaned';
                try {
                  launchUrlString(uri);
                } catch (_) {}
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}
