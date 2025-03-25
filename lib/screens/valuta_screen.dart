import 'dart:convert';
import 'package:currency_exchange_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:currency_exchange_app/providers/auth_provider.dart';

class ValutaScreen extends StatefulWidget {
  const ValutaScreen({Key? key}) : super(key: key);

  @override
  State<ValutaScreen> createState() => _ValutaScreenState();
}

class _ValutaScreenState extends State<ValutaScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isAdding = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _currencies = [];

  final TextEditingController _nameCtrl = TextEditingController();

  late AnimationController _bgAnimationController;
  late Animation<Color?> _color1Animation;
  late Animation<Color?> _color2Animation;

  @override
  void initState() {
    super.initState();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _color1Animation = ColorTween(
      begin: Colors.blue.shade800,
      end: Colors.pink.shade400,
    ).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    _color2Animation = ColorTween(
      begin: Colors.purple.shade900,
      end: Colors.cyan.shade400,
    ).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    _bgAnimationController.repeat(reverse: true);

    _fetchCurrencies();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1Animation.value ?? Colors.blue,
                  _color2Animation.value ?? Colors.purple,
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _color1Animation.value!.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: _color2Animation.value!.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildCustomAppBar(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 1.0, end: 0.8).animate(
                            CurvedAnimation(
                              parent: _bgAnimationController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Card(
                            elevation: 20,
                            margin: const EdgeInsets.all(30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            color: Colors.black.withOpacity(0.6),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _buildMainContent(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: GradientText(
        'Управление Валютами',
        gradient: const LinearGradient(colors: [Colors.white, Colors.yellow]),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'RobotoMono',
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Выйти',
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GradientText(
          'Список Валют',
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3A96), Color(0xFFCC353C)],
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 16),
        if (_errorMsg != null)
          Text(
            'Ошибка: $_errorMsg',
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'RobotoMono',
              fontSize: 16,
            ),
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: PulsatingLoader(color: Colors.blue),
          )
        else
          _buildListView(),
        const SizedBox(height: 24),
        _buildAddCurrencyArea(),
      ],
    );
  }

  Widget _buildListView() {
    if (_currencies.isEmpty) {
      return const Text(
        'Нет валют для отображения.',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          color: Colors.white,
          fontSize: 18,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _currencies.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.grey.shade500, height: 1),
      itemBuilder: (ctx, i) {
        final c = _currencies[i];
        final id = c['id'];
        final name = c['name'] ?? '';

        return ListTile(
          leading: Icon(
            Icons.currency_exchange,
            color: Colors.blue.shade700,
            size: 30,
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoMono',
              color: Colors.white,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
            onPressed: () {
              _confirmDelete(context, id, name);
            },
            tooltip: 'Удалить валюту',
          ),
        );
      },
    );
  }

  // Кнопка "Добавить валюту"
  Widget _buildAddCurrencyArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientText(
          'Добавить новую валюту:',
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3A96), Color(0xFFCC353C)],
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 8),
        AnimatedInputField(
          controller: _nameCtrl,
          labelText: 'Название валюты (пример: USD)',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        Center(
          child: GlowingButton(
            text: 'Добавить',
            color: Colors.green.shade700,
            onPressed: _isAdding ? null : _onAddCurrency,
            isLoading: _isAdding,
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: GradientText(
            'Удалить валюту?',
            gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.orange],
            ),
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить валюту "$name"?',
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Удалить',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'RobotoMono',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteCurrency(id);
    }
  }

  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _currencies.clear();
    });

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/currencies/');
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);

        List<dynamic> results;
        if (raw is Map && raw.containsKey('results')) {
          results = raw['results'];
        } else if (raw is List) {
          results = raw;
        } else {
          setState(() {
            _errorMsg = 'Невалидный формат ответа /api/currencies/.';
          });
          return;
        }

        setState(() {
          _currencies = results
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        });
      } else {
        setState(() {
          _errorMsg = '${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onAddCurrency() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название валюты!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/currencies/');
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({"name": name});

      final resp = await http.post(url, headers: headers, body: body);
      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Валюта "$name" успешно добавлена!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _nameCtrl.clear();
        _fetchCurrencies();
      } else {
        setState(() {
          _errorMsg = '${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _deleteCurrency(int id) async {
    setState(() {
      _errorMsg = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/currencies/$id/');
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.delete(url, headers: headers);
      if (resp.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Валюта успешно удалена!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchCurrencies();
      } else {
        setState(() {
          _errorMsg = '${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Ошибка: $e';
      });
    }
  }
}
