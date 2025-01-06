// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const baseUrl =
      'https://exchanger-erbolsk.pythonanywhere.com'; // Ваш бэкенд

  static Future<String> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/token/');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['access'];
    } else {
      throw Exception('Login failed: ${resp.statusCode} - ${resp.body}');
    }
  }
}
