import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

void main() {
  runApp(const MinhaLocalizacaoApp());
}

class MinhaLocalizacaoApp extends StatelessWidget {
  const MinhaLocalizacaoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Localização',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});
  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  String? _linkLocalizacao;
  String? _coordenadas;
  String? _precisao;
  bool _carregando = false;
  bool _obtido = false;
  bool _rastreamentoAtivo = false;
  StreamSubscription<Position>? _positionStream;
  DateTime? _ultimaAtualizacao;

  @override
  void dispose() {
    _pararRastreamento();
    super.dispose();
  }

  Future<bool> _verificarPermissoes() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      _mostrarErro('O GPS está desativado. Ative nas configurações.');
      return false;
    }
    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        _mostrarErro('Permissão de localização negada.');
        return false;
      }
    }
    if (permissao == LocationPermission.deniedForever) {
      _mostrarErro('Permissão negada permanentemente. Vá em Configurações > Aplicativos.');
      return false;
    }
    return true;
  }

  void _atualizarPosicao(Position posicao) {
    final lat = posicao.latitude.toStringAsFixed(6);
    final lng = posicao.longitude.toStringAsFixed(6);
    final prec = posicao.accuracy.toStringAsFixed(0);
    setState(() {
      _linkLocalizacao = 'https://www.google.com/maps?q=$lat,$lng';
      _coordenadas = '$lat, $lng';
      _precisao = '~${prec}m';
      _obtido = true;
      _carregando = false;
      _ultimaAtualizacao = DateTime.now();
    });
  }

  Future<void> _obterLocalizacaoUnica() async {
    setState(() { _carregando = true; _obtido = false; });
    if (!await _verificarPermissoes()) return;
    try {
      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _atualizarPosicao(posicao);
    } catch (e) {
      _mostrarErro('Não foi possível obter a localização.');
    }
  }

  Future<void> _iniciarRastreamento() async {
    if (!await _verificarPermissoes()) return;
    setState(() { _carregando = true; _rastreamentoAtivo = true; });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // atualiza a cada 10 metros
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position posicao) {
        _atualizarPosicao(posicao);
      },
      onError: (e) {
        _mostrarErro('Erro no rastreamento. Tente novamente.');
        _pararRastreamento();
      },
    );
  }

  void _pararRastreamento() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _rastreamentoAtivo = false;
    });
  }

  void _mostrarErro(String msg) {
    setState(() { _carregando = false; _rastreamentoAtivo = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copiarLink() {
    if (_linkLocalizacao == null) return;
    Clipboard.setData(ClipboardData(text: _linkLocalizacao!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enviarWhatsApp() async {
    if (_linkLocalizacao == null) return;
    final msg = Uri.encodeComponent('Olá! Estou aqui agora: $_linkLocalizacao');
    final url = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _compartilhar() async {
    if (_linkLocalizacao == null) return;
    await Share.share('Olá! Estou aqui agora: $_linkLocalizacao');
  }

  String _formatarHora(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Minha Localização',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Card de status
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _rastreamentoAtivo
                      ? Colors.green.shade300
                      : Colors.grey.shade200,
                  width: _rastreamentoAtivo ? 2 : 1,
                ),
              ),
              child: Column(children: [
                Icon(
                  _rastreamentoAtivo
                      ? Icons.location_on
                      : _obtido
                          ? Icons.location_on
                          : Icons.location_searching,
                  size: 64,
                  color: _rastreamentoAtivo
                      ? Colors.green
                      : _obtido
                          ? const Color(0xFF1565C0)
                          : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  _rastreamentoAtivo
                      ? 'Rastreamento em tempo real ativo'
                      : _obtido
                          ? 'Localização obtida'
                          : _carregando
                              ? 'Buscando posição...'
                              : 'Toque para obter sua localização',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _rastreamentoAtivo
                        ? Colors.green.shade700
                        : _obtido
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade700,
                  ),
                ),
                if (_coordenadas != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$_coordenadas · $_precisao',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                if (_ultimaAtualizacao != null && _rastreamentoAtivo) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.update, size: 13, color: Colors.green.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Atualizado às ${_formatarHora(_ultimaAtualizacao)}',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 16),

            // Link gerado
            if (_linkLocalizacao != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_linkLocalizacao!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
              ),

            const SizedBox(height: 16),

            // Botão localização única
            ElevatedButton.icon(
              onPressed: (_carregando || _rastreamentoAtivo) ? null : _obterLocalizacaoUnica,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _carregando && !_rastreamentoAtivo
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_obtido ? Icons.refresh : Icons.my_location),
              label: Text(
                _carregando && !_rastreamentoAtivo
                    ? 'Obtendo...'
                    : _obtido ? 'Atualizar uma vez' : 'Obter localização',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 12),

            // Botão rastreamento em tempo real
            ElevatedButton.icon(
              onPressed: _carregando ? null : (_rastreamentoAtivo ? _pararRastreamento : _iniciarRastreamento),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rastreamentoAtivo ? Colors.red.shade600 : Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_rastreamentoAtivo ? Icons.stop : Icons.play_arrow),
              label: Text(
                _rastreamentoAtivo ? 'Parar rastreamento' : 'Iniciar rastreamento contínuo',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 12),

            // Botão copiar
            OutlinedButton.icon(
              onPressed: _obtido ? _copiarLink : null,
              icon: const Icon(Icons.copy),
              label: const Text('Copiar link',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Botão WhatsApp
            ElevatedButton.icon(
              onPressed: _obtido ? _enviarWhatsApp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Enviar pelo WhatsApp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 12),

            // Botão compartilhar
            OutlinedButton.icon(
              onPressed: _obtido ? _compartilhar : null,
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar link',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // Aviso de bateria
            if (_rastreamentoAtivo)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.battery_alert, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rastreamento ativo consome mais bateria. Lembre de parar quando não precisar.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
