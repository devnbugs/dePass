import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/session_provider.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_card.dart';
import '../widgets/material3_textfield.dart';
import '../theme.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://log.travelnetng.serv00.net/api',
);

class QrWizardScreen extends StatefulWidget {
  const QrWizardScreen({super.key});

  @override
  State<QrWizardScreen> createState() => _QrWizardScreenState();
}

class _QrWizardScreenState extends State<QrWizardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _themes = [
    {'id': 'classic', 'name': 'Classic', 'fg': '#000000', 'bg': '#FFFFFF'},
    {'id': 'neon', 'name': 'Neon', 'fg': '#00E5FF', 'bg': '#1A1A2E'},
    {'id': 'gold', 'name': 'Gold', 'fg': '#FFD700', 'bg': '#000000'},
    {'id': 'ocean', 'name': 'Ocean', 'fg': '#1565C0', 'bg': '#FFFFFF'},
  ];

  List<dynamic> _events = [];
  List<dynamic> _passTypes = [];
  bool _loadingEvents = true;
  bool _loadingPassTypes = false;
  bool _generating = false;
  Map<String, dynamic>? _result;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countCtrl = TextEditingController(text: '10');
  final _prefixCtrl = TextEditingController(text: 'GPX');

  String _selectedEventId = '';
  String _selectedPassTypeId = '';
  String _selectedTheme = 'classic';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _countCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  String get _baseApi => _baseUrl;

  Map<String, String> _getHeaders(SessionProvider session) {
    return {
      'Authorization': 'Bearer ${session.token}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchEvents() async {
    final session = context.read<SessionProvider>();
    if (session.token == null) return;

    setState(() => _loadingEvents = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseApi/events'),
        headers: _getHeaders(session),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _events = data['data'] as List<dynamic>? ?? [];
          _loadingEvents = false;
        });
      }
    } catch (_) {
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _fetchPassTypes(String eventId) async {
    final session = context.read<SessionProvider>();
    if (session.token == null) return;

    setState(() {
      _loadingPassTypes = true;
      _selectedPassTypeId = '';
      _passTypes = [];
    });
    try {
      final res = await http.get(
        Uri.parse('$_baseApi/events/$eventId/pass-types'),
        headers: _getHeaders(session),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _passTypes = data['data'] as List<dynamic>? ?? [];
          _loadingPassTypes = false;
        });
      }
    } catch (_) {
      setState(() => _loadingPassTypes = false);
    }
  }

  Future<void> _generateSingle() async {
    final session = context.read<SessionProvider>();
    if (session.token == null) return;

    setState(() {
      _generating = true;
      _result = null;
    });

    try {
      final body = {
        'event_id': int.parse(_selectedEventId),
        'pass_type_id': int.parse(_selectedPassTypeId),
        'theme': _selectedTheme,
      };
      if (_nameCtrl.text.isNotEmpty) body['attendee_name'] = _nameCtrl.text;
      if (_phoneCtrl.text.isNotEmpty) body['phone'] = _phoneCtrl.text;

      final res = await http.post(
        Uri.parse('$_baseApi/qr-wizard/generate'),
        headers: _getHeaders(session),
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _result = data);
      } else {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        _showError(err['message'] as String? ?? 'Generation failed');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _generateBulk() async {
    final session = context.read<SessionProvider>();
    if (session.token == null) return;

    setState(() {
      _generating = true;
      _result = null;
    });

    try {
      final count = int.tryParse(_countCtrl.text) ?? 10;
      final body = {
        'event_id': int.parse(_selectedEventId),
        'pass_type_id': int.parse(_selectedPassTypeId),
        'count': count.clamp(1, 500),
        'theme': _selectedTheme,
      };
      if (_prefixCtrl.text.isNotEmpty) body['prefix'] = _prefixCtrl.text;

      final res = await http.post(
        Uri.parse('$_baseApi/qr-wizard/bulk-generate'),
        headers: _getHeaders(session),
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() => _result = data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Generated ${data['pass'] != null ? 1 : data['generated_count'] ?? count} QR codes',
              ),
            ),
          );
        }
      } else if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() => _result = data);
        }
      } else {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        _showError(err['message'] as String? ?? 'Generation failed');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Widget _themeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _themes.map((t) {
            final selected = t['id'] == _selectedTheme;
            return GestureDetector(
              onTap: () => setState(() => _selectedTheme = t['id'] as String),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryContainer : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                          (t['fg'] as String).replaceFirst('#', '0xFF'),
                        )),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['name'] as String,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _eventDropdown() {
    return _loadingEvents
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<String>(
            initialValue: _selectedEventId.isNotEmpty ? _selectedEventId : null,
            decoration: const InputDecoration(
              labelText: 'Event',
              filled: true,
            ),
            items: _events.map((e) {
              return DropdownMenuItem(
                value: e['id'].toString(),
                child: Text(e['name'] as String? ?? ''),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedEventId = v ?? '';
                _selectedPassTypeId = '';
                _passTypes = [];
              });
              if (v != null) _fetchPassTypes(v);
            },
          );
  }

  Widget _passTypeDropdown() {
    if (_selectedEventId.isEmpty) {
      return const SizedBox.shrink();
    }
    return _loadingPassTypes
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<String>(
            initialValue: _selectedPassTypeId.isNotEmpty ? _selectedPassTypeId : null,
            decoration: const InputDecoration(
              labelText: 'Pass Type',
              filled: true,
            ),
            items: _passTypes.map((pt) {
              return DropdownMenuItem(
                value: pt['id'].toString(),
                child: Text(pt['name'] as String? ?? ''),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedPassTypeId = v ?? ''),
          );
  }

  Widget _qrPreview() {
    if (_result == null) {
      return Material3Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('Generate a QR code to preview', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final qrData = _result!['qr_data'] as String? ?? '';

    return Material3Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _result!['gpid'] as String? ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (_result!['pass'] != null) ...[
            Text(
              _result!['pass']['attendee_name'] as String? ?? '',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Theme: ${_result!['theme'] as String? ?? 'classic'}',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulkResultPreview() {
    if (_result == null) return const SizedBox.shrink();
    final passes = _result!['pass'] != null
        ? [_result!['pass']]
        : (_result!['passes'] as List<dynamic>?) ?? [];
    if (passes.isEmpty && _result!['gpid'] != null) {
      return Material3Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: 8),
              Text(
                'GPID: ${_result!['gpid']}',
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    if (passes.isEmpty) return const SizedBox.shrink();
    return Material3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated ${passes.length} QR codes',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...passes.take(10).map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.qr_code, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    p['pass_uid'] as String? ?? p['gpid'] as String? ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          if (passes.length > 10)
            Text(
              '... and ${passes.length - 10} more',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
        ],
      ),
    );
  }

  bool get _canGenerate =>
      _selectedEventId.isNotEmpty &&
      _selectedPassTypeId.isNotEmpty &&
      !_generating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Wizard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Single', icon: Icon(Icons.qr_code)),
            Tab(text: 'Bulk', icon: Icon(Icons.dynamic_feed)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleTab(),
          _buildBulkTab(),
        ],
      ),
    );
  }

  Widget _buildSingleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _eventDropdown(),
          const SizedBox(height: 16),
          _passTypeDropdown(),
          const SizedBox(height: 16),
          Material3TextField(
            label: 'Attendee Name',
            hint: 'John Doe',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 16),
          Material3TextField(
            label: 'Phone (optional)',
            hint: '+234800000000',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _themeSelector(),
          const SizedBox(height: 24),
          Material3Button(
            label: 'Generate QR',
            isLoading: _generating,
            onPressed: _canGenerate ? _generateSingle : null,
            leadingIcon: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 24),
          _qrPreview(),
        ],
      ),
    );
  }

  Widget _buildBulkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _eventDropdown(),
          const SizedBox(height: 16),
          _passTypeDropdown(),
          const SizedBox(height: 16),
          Material3TextField(
            label: 'Number of QR Codes',
            controller: _countCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Material3TextField(
            label: 'GPID Prefix',
            hint: 'GPX',
            controller: _prefixCtrl,
          ),
          const SizedBox(height: 16),
          _themeSelector(),
          const SizedBox(height: 24),
          Material3Button(
            label: 'Generate & Download',
            isLoading: _generating,
            onPressed: _canGenerate ? _generateBulk : null,
            leadingIcon: const Icon(Icons.download),
          ),
          const SizedBox(height: 24),
          _bulkResultPreview(),
        ],
      ),
    );
  }
}
