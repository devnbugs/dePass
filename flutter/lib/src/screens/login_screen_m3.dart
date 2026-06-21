import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_textfield.dart';
import '../widgets/material3_card.dart';
import '../providers/session_provider.dart';
import '../theme.dart';

class LoginScreenM3 extends StatefulWidget {
  const LoginScreenM3({super.key});

  @override
  State<LoginScreenM3> createState() => _LoginScreenM3State();
}

class _LoginScreenM3State extends State<LoginScreenM3> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _checkingDevice = false;
  bool _showPassword = false;

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        const SnackBar(
          content: Text('This device must be approved by an admin before login.'),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          behavior: SnackBarBehavior.floating,
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Image.asset(
                        'assets/icon/app-icon.png',
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.qr_code_2, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GatePassX',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 2026.07.22',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign in section
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure event pass scanning and management',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Username field
                Material3TextField(
                  label: 'Username',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Device Status Card
                Material3Card(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: deviceApproved ? AppColors.primaryContainer : AppColors.surface,
                  showBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            deviceApproved ? Icons.verified : Icons.info_outline,
                            color: deviceApproved ? AppColors.primary : AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deviceApproved ? 'Device Approved' : 'Device Approval Required',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: deviceApproved ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.deviceMessage ??
                            'Register this device, then ask an admin to approve it in the admin panel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (session.deviceUuid != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Device ID',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session.deviceUuid ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Material3Button(
                              label: _checkingDevice ? 'Checking...' : 'Register Device',
                              onPressed: _checkingDevice ? null : _registerDevice,
                              isLoading: _checkingDevice,
                              height: 40,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Material3OutlinedButton(
                              label: 'Refresh',
                              onPressed: _checkingDevice ? null : _checkDevice,
                              isLoading: _checkingDevice,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password field
                Material3TextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  enabled: deviceApproved,
                ),
                const SizedBox(height: 32),

                // Sign in button
                Material3Button(
                  label: _loading ? 'Signing In...' : 'Sign In',
                  onPressed: _loading || !deviceApproved ? null : _submit,
                  isLoading: _loading,
                  height: 48,
                ),
                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Text(
                    'Secure • Material 3 Design • Device-Approved',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
