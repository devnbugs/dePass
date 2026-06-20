import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://log.travelnetng.serv00.net/api';
const _secureStorage = FlutterSecureStorage();
const _requestTimeout = Duration(seconds: 15);

class SessionProvider extends ChangeNotifier {
  String? _token;
  String? _userName;
  String? _role;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _passes = [];

  String? get token => _token;
  String? get userName => _userName;
  String? get role => _role;
  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get passes => _passes;
  bool get isAuthenticated => _token != null;

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

    try {
      storedToken = await _secureStorage.read(key: 'api_token');
      storedUser = await _secureStorage.read(key: 'user_name');
      storedRole = await _secureStorage.read(key: 'user_role');
    } catch (_) {
      return;
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
    http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Accept': 'application/json'},
            body: {
              'username': username,
              'password': password,
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
