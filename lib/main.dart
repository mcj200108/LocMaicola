import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _obterLocalizacao() async {
    setState(() {
      _carregando = true;
      _obtido = false;
      _linkLocalizacao = null;
    });

    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      _mostrarErro('O GPS está desativado. Ative nas configurações.');
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        _mostrarErro('Permissão de localização negada.');
        return;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      _mostrarErro('Permissão negada permanentemente. Vá em Configurações > Aplicativos.');
      return;
    }

    try {
      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final lat = posicao.latitude.toStringAsFixed(6);
      final lng = posicao.longitude.toStringAsFixed(6);
      final prec = posicao.accuracy.toStringAsFixed(0);
      setState(() {
        _linkLocalizacao = 'https://www.google.com/maps?q=$lat,$lng';
        _coordenadas = '$lat, $lng';
        _precisao = '~${prec}m';
        _carregando = false;
        _obtido = true;
      });
    } catch (e) {
      _mostrarErro('Não foi possível obter a localização. Tente novamente.');
    }
  }

  void _mostrarErro(String msg) {
    setState(() => _carregando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _copiarLink() {
    if (_linkLocalizacao == null) return;
    Clipboard.setData(ClipboardData(text: _linkLocalizacao!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado!'), backgroundColor: Colors.green),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                Icon(
                  _obtido ? Icons.location_on : Icons.location_searching,
                  size: 64,
                  color: _obtido ? Colors.green : const Color(0xFF1565C0),
                ),
                const SizedBox(height: 12),
                Text(
                  _obtido
                      ? 'Localização obtida!'
                      : _carregando
                          ? 'Buscando sua posição...'
                          : 'Toque para obter sua localização',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _obtido ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                if (_coordenadas != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$_coordenadas · $_precisao',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            if (_linkLocalizacao != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_linkLocalizacao!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1565C0))),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregando ? null : _obterLocalizacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_obtido ? Icons.refresh : Icons.my_location),
              label: Text(
                _carregando
                    ? 'Obtendo...'
                    : _obtido
                        ? 'Atualizar localização'
                        : 'Obter minha localização',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _obtido ? _copiarLink : null,
              icon: const Icon(Icons.copy),
              label: const Text('Copiar link',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _obtido ? _enviarWhatsApp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Enviar pelo WhatsApp',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _obtido ? _compartilhar : null,
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar link',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
