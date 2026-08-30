import 'package:flutter/material.dart';
import '../../datos/modelos/asistencia_modelos.dart';
import '../../datos/servicios/api_asistencia_cliente.dart';
import 'marcacion_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiAsistenciaCliente _api = ApiAsistenciaCliente();
  final TextEditingController _documentoCtrl = TextEditingController(text: '1010123456');
  final TextEditingController _passwordCtrl = TextEditingController(text: '123456');
  bool _cargando = false;

  Future<void> _iniciarSesion([String? doc, String? pass]) async {
    final documento = doc ?? _documentoCtrl.text.trim();
    final password = pass ?? _passwordCtrl.text.trim();

    if (documento.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa documento y contraseña')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final res = await _api.postPublico('/auth/login', {
        'documento': documento,
        'password': password,
      });

      final data = res.data as Map<String, dynamic>;
      final tokens = data['tokens'];
      final usuarioMap = data['usuario'] as Map<String, dynamic>;
      final usuario = UsuarioModelo.fromMap(usuarioMap);

      // RF-02: Guardar refresh token en el almacenamiento cifrado Keystore / Keychain
      await _api.almacen.guardarTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );
      await _api.almacen.guardarNombreUsuario(usuario.nombre);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MarcacionPage(usuario: usuario),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de autenticación: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'Asistencia Biométrica CEET',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión una vez con tus credenciales. Después podrás marcar con tu huella o rostro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _documentoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : () => _iniciarSesion(),
                child: _cargando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Accesos rápidos de prueba (Seed):', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _iniciarSesion('1010123456', '123456'),
                      child: const Text('Entrar como Aprendiz'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _iniciarSesion('2020987654', '123456'),
                      child: const Text('Entrar como Instructor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
