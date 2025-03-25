import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userName;
  bool _isLoadingPrefs = true;

  bool get isLoadingPrefs => _isLoadingPrefs;
  bool get isLoggedIn => _token != null;

  String? get token => _token;
  String? get userName => _userName;

  Future<void> loadTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    _userName = prefs.getString('userName');
    _isLoadingPrefs = false;
    notifyListeners();
  }

  Future<void> saveToken(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userName = userName;
    await prefs.setString('authToken', token);
    await prefs.setString('userName', userName);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userName = null;
    await prefs.remove('authToken');
    await prefs.remove('userName');
    notifyListeners();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> login(String username, String password) async {
    final url = Uri.parse('http://192.168.212.129:8000/api/token/');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'username': username, 'password': password});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access'];

      // Save token and username
      await saveToken(token, username);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  Future<http.Response> makeAuthenticatedRequest(
    Uri url,
    String method,
    BuildContext context, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    if (_token == null) {
      logout(context);
      throw Exception("Token is missing");
    }

    final effectiveHeaders = {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: effectiveHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: effectiveHeaders,
            body: jsonEncode(body),
          );
          break;
        default:
          throw Exception("Unsupported HTTP method");
      }

      if (response.statusCode == 401 &&
          response.body.contains("token_not_valid")) {
        logout(context);
        throw Exception("Session expired. Redirecting to login.");
      }

      return response;
    } catch (e) {
      throw Exception("Request failed: $e");
    }
  }
}
