import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../providers/session_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _checkingDevice = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionProvider>();
    _usernameController.text = session.deviceUsername ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerDevice() async {
    setState(() => _checkingDevice = true);
    final session = context.read<SessionProvider>();
    final username = _usernameController.text.trim();

    final approved = await session.registerDevice(username: username);

    if (!mounted) {
      return;
    }

    setState(() => _checkingDevice = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Device approved. You can sign in.'
              : session.deviceMessage ?? 'Device registration is pending admin approval.',
        ),
      ),
    );
  }

  Future<void> _checkDevice() async {
    setState(() => _checkingDevice = true);
    final session = context.read<SessionProvider>();

    await session.refreshDeviceStatus(username: _usernameController.text.trim());

    if (!mounted) {
      return;
    }

    setState(() => _checkingDevice = false);
  }

  Future<void> _submit() async {
    final session = context.read<SessionProvider>();

    if (!session.isDeviceApproved || session.deviceUsername != _usernameController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device must be approved by an admin before login.')),
      );
      return;
    }

    setState(() => _loading = true);

    final success = await session.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final deviceApproved = session.isDeviceApproved && session.deviceUsername == _usernameController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF1B1B18).withValues(alpha: 0.12)),
                      ),
                      child: Image.asset(
                        'assets/icon/app-icon.png',
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'GatePassX',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Secure event scanning on your mobile device.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: deviceApproved ? const Color(0xFFEFF8EF) : const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: deviceApproved ? const Color(0xFFB9E3C5) : const Color(0xFFF4D28A),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceApproved ? 'Device approved' : 'Device approval required',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: deviceApproved ? const Color(0xFF1E7A49) : const Color(0xFF996A00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.deviceMessage ??
                            'Register this phone, then ask an admin to approve it in the admin panel.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF4B4A45)),
                      ),
                      if (session.deviceUuid != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Device ID: ${session.deviceUuid}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6F6B61)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _checkingDevice ? null : _registerDevice,
                              child: Text(_checkingDevice ? 'Checking...' : 'Register Device'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _checkingDevice ? null : _checkDevice,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  enabled: deviceApproved,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _loading ? 'Signing In...' : 'Sign In',
                  onPressed: _loading || !deviceApproved ? null : _submit,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Designed with template-driven style and clean organization.\nPhase 3 mobile UI scaffold is ready.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
