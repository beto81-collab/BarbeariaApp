import 'package:flutter/material.dart';
import 'vitrine_screen.dart';

class BackupAutoConfig {
  static bool automatico = false;
  static Duration intervalo = const Duration(minutes: 5);
  static DateTime? ultimaExecucao;
  static bool houveAlteracao = false;
}

class BackupAutoConfigWidget extends StatefulWidget {
  final void Function()? onConfigChanged;
  const BackupAutoConfigWidget({super.key, this.onConfigChanged});

  @override
  State<BackupAutoConfigWidget> createState() => _BackupAutoConfigWidgetState();
}

class _BackupAutoConfigWidgetState extends State<BackupAutoConfigWidget> {
  bool _automatico = BackupAutoConfig.automatico;
  int _intervaloMin = BackupAutoConfig.intervalo.inMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _automatico,
              onChanged: (v) {
                setState(() {
                  _automatico = v;
                  BackupAutoConfig.automatico = v;
                  if (widget.onConfigChanged != null) widget.onConfigChanged!();
                });
              },
            ),
            const Text('Backup automático'),
          ],
        ),
        if (_automatico)
          Row(
            children: [
              const Text('Intervalo: '),
              DropdownButton<int>(
                value: _intervaloMin,
                items: [1, 5, 10, 15, 30, 60]
                    .map(
                      (min) =>
                          DropdownMenuItem(value: min, child: Text('$min min')),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _intervaloMin = v;
                      BackupAutoConfig.intervalo = Duration(minutes: v);
                      if (widget.onConfigChanged != null) {
                        widget.onConfigChanged!();
                      }
                    });
                  }
                },
              ),
            ],
          ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Vitrine de Serviços'),
          style: ElevatedButton.styleFrom(minimumSize: Size(180, 48)),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const VitrineScreen()));
          },
        ),
      ],
    );
  }
}
