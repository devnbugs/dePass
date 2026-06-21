import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://log.travelnetng.serv00.net/api',
);
const _secureStorage = FlutterSecureStorage();
const _requestTimeout = Duration(seconds: 15);
const _deviceUuidKey = 'device_uuid';
const _deviceUsernameKey = 'device_username';

class SessionProvider extends ChangeNotifier {
  String? _token;
  String? _userName;
  String? _role;
  String? _deviceUuid;
  String? _deviceUsername;
  String? _deviceStatus;
  String? _deviceMessage;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _passes = [];

  String? get token => _token;
  String? get userName => _userName;
  String? get role => _role;
  String? get deviceUuid => _deviceUuid;
  String? get deviceUsername => _deviceUsername;
  String? get deviceStatus => _deviceStatus;
  String? get deviceMessage => _deviceMessage;
  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get passes => _passes;
  bool get isAuthenticated => _token != null;
  bool get isDeviceApproved => _deviceStatus == 'approved';

  Map<String, String> get _authHeaders {
    return _token != null
        ? {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          }
        : {
            'Accept': 'application/json',
          };
  }

  Future<void> initialize() async {
    String? storedToken;
    String? storedUser;
    String? storedRole;
    String? storedDeviceUuid;
    String? storedDeviceUsername;

    try {
      storedDeviceUuid = await _secureStorage.read(key: _deviceUuidKey);
      storedDeviceUsername = await _secureStorage.read(key: _deviceUsernameKey);
      storedToken = await _secureStorage.read(key: 'api_token');
      storedUser = await _secureStorage.read(key: 'user_name');
      storedRole = await _secureStorage.read(key: 'user_role');
    } catch (_) {
      return;
    }

    _deviceUuid = storedDeviceUuid ?? await _createAndStoreDeviceUuid();
    _deviceUsername = storedDeviceUsername;

    if (_deviceUsername != null) {
      await refreshDeviceStatus(username: _deviceUsername!);
    }

    if (storedToken != null) {
      _token = storedToken;
      _userName = storedUser;
      _role = storedRole;
      notifyListeners();

      final refreshed = await refreshData();
      if (!refreshed) {
        await _clearStoredSession();
        _token = null;
        _userName = null;
        _role = null;
        notifyListeners();
      }
    }
  }

  Future<bool> login({required String username, required String password}) async {
    final deviceUuid = await ensureDeviceUuid();
    if (!isDeviceApproved || _deviceUsername != username) {
      final refreshed = await refreshDeviceStatus(username: username);
      if (!refreshed || !isDeviceApproved) {
        return false;
      }
    }

    http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Accept': 'application/json'},
            body: {
              'username': username,
              'password': password,
              'device_uuid': deviceUuid,
            },
          )
          .timeout(_requestTimeout);
    } catch (_) {
      return false;
    }

    if (response.statusCode == 200) {
      final data = _decodeJsonMap(response.body);
      if (data == null) {
        return false;
      }

      _token = data['token'] as String?;
      _userName = data['user']?['username'] as String? ?? username;
      _role = data['user']?['role'] as String?;
      _deviceUsername = username;

      if (_token == null) {
        return false;
      }

      await _writeStoredSession();
      notifyListeners();
      final refreshed = await refreshData();
      if (!refreshed) {
        await logout();
        return false;
      }

      return true;
    }

    return false;
  }

  Future<bool> refreshData() async {
    if (!isAuthenticated) {
      return false;
    }

    final eventsLoaded = await fetchEvents();
    final passesLoaded = eventsLoaded ? await fetchPasses() : false;
    return eventsLoaded && passesLoaded;
  }

  Future<String> ensureDeviceUuid() async {
    if (_deviceUuid != null) {
      return _deviceUuid!;
    }

    _deviceUuid = await _createAndStoreDeviceUuid();
    notifyListeners();
    return _deviceUuid!;
  }

  Future<bool> registerDevice({required String username}) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      _deviceStatus = null;
      _deviceMessage = 'Enter your username before registering this device.';
      notifyListeners();
      return false;
    }

    final deviceUuid = await ensureDeviceUuid();

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/device-registration'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'uuid': deviceUuid,
              'username': normalizedUsername,
              'device_fingerprint': _buildDeviceFingerprint(deviceUuid),
            }),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      _deviceStatus = null;
      _deviceMessage = 'Unable to reach the server for device registration.';
      notifyListeners();
      return false;
    }

    final data = _decodeJsonMap(response.body);
    _deviceMessage = data?['message'] as String? ?? 'Device registration failed.';

    if (response.statusCode == 200 || response.statusCode == 201) {
      final device = data?['device'];
      _deviceStatus = device is Map ? device['status']?.toString() : null;
      _deviceUsername = normalizedUsername;
      await _writeDeviceUsername();
      notifyListeners();
      return _deviceStatus == 'approved';
    }

    notifyListeners();
    return false;
  }

  Future<bool> refreshDeviceStatus({required String username}) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      return false;
    }

    final deviceUuid = await ensureDeviceUuid();

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/device-registration/status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'uuid': deviceUuid,
              'username': normalizedUsername,
            }),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      _deviceMessage = 'Unable to check device approval.';
      notifyListeners();
      return false;
    }

    final data = _decodeJsonMap(response.body);
    _deviceMessage = data?['message'] as String? ?? 'Device is not registered.';

    if (response.statusCode == 200) {
      _deviceStatus = data?['status'] as String?;
      _deviceUsername = normalizedUsername;
      await _writeDeviceUsername();
      notifyListeners();
      return _deviceStatus == 'approved';
    }

    _deviceStatus = data?['status'] as String? ?? 'unregistered';
    notifyListeners();
    return false;
  }

  Future<bool> fetchEvents() async {
    if (!isAuthenticated) return false;

    final response = await _get('$_baseUrl/events');
    if (response == null) {
      return false;
    }

    if (response.statusCode == 200) {
      final data = _decodeJsonMap(response.body);
      if (data == null) {
        return false;
      }

      final items = data['data'] as List<dynamic>?;
      _events = items
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [];
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> fetchPasses() async {
    if (!isAuthenticated || _events.isEmpty) {
      _passes = [];
      notifyListeners();
      return true;
    }

    final allPasses = <Map<String, dynamic>>[];

    for (final event in _events) {
      final eventId = event['id'];
      if (eventId == null) {
        continue;
      }

      final response = await _get('$_baseUrl/events/$eventId/passes');
      if (response == null) {
        return false;
      }

      if (response.statusCode != 200) {
        continue;
      }

      final data = _decodeJsonMap(response.body);
      if (data == null) {
        continue;
      }

      final items = data['data'] as List<dynamic>?;
      if (items != null) {
        allPasses.addAll(items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)));
      }
    }

    _passes = allPasses;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userName = null;
    _role = null;
    _events = [];
    _passes = [];
    await _clearStoredSession();
    notifyListeners();
  }

  Future<String> _createAndStoreDeviceUuid() async {
    final uuid = _generateUuidV4();
    try {
      await _secureStorage.write(key: _deviceUuidKey, value: uuid);
    } catch (_) {
      // The UUID still works for this session even if storage is unavailable.
    }
    return uuid;
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }

  String _buildDeviceFingerprint(String uuid) {
    return '${defaultTargetPlatform.name}-$uuid';
  }

  Future<http.Response?> _get(String url) async {
    try {
      return await http.get(Uri.parse(url), headers: _authHeaders).timeout(_requestTimeout);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    try {
      final decoded = json.decode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeStoredSession() async {
    try {
      await _secureStorage.write(key: 'api_token', value: _token);
      await _secureStorage.write(key: 'user_name', value: _userName);
      await _secureStorage.write(key: 'user_role', value: _role);
    } catch (_) {
      // A storage failure should not block an already-authenticated session.
    }
  }

  Future<void> _writeDeviceUsername() async {
    try {
      await _secureStorage.write(key: _deviceUsernameKey, value: _deviceUsername);
    } catch (_) {
      // Device approval can still be checked again if this write fails.
    }
  }

  Future<void> _clearStoredSession() async {
    try {
      await _secureStorage.delete(key: 'api_token');
      await _secureStorage.delete(key: 'user_name');
      await _secureStorage.delete(key: 'user_role');
    } catch (_) {
      // Ignore storage failures during cleanup.
    }
  }
}
