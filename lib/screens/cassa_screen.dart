import 'dart:convert';
import 'package:currency_exchange_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:currency_exchange_app/providers/auth_provider.dart';

class CassaScreen extends StatefulWidget {
  const CassaScreen({Key? key}) : super(key: key);

  @override
  State<CassaScreen> createState() => _CassaScreenState();
}

class _CassaScreenState extends State<CassaScreen>
    with TickerProviderStateMixin {
  final List<String> _periods = ['3days', 'week', 'month', 'shift'];
  String _selectedPeriod = 'shift';

  bool _isLoading = false;
  String? _errorMsg;
  Map<String, dynamic>? _analyticsData;

  late AnimationController _bgAnimationController;
  late Animation<Color?> _color1Animation;
  late Animation<Color?> _color2Animation;

  late AnimationController _summaryAnimationController;
  late Animation<double> _summaryFadeAnimation;
  late Animation<double> _summaryScaleAnimation;

  late AnimationController _tableAnimationController;
  late Animation<double> _tableFadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _color1Animation = ColorTween(
      begin: Colors.teal.shade800,
      end: Colors.indigo.shade800,
    ).animate(_bgAnimationController);

    _color2Animation = ColorTween(
      begin: Colors.indigo.shade800,
      end: Colors.teal.shade800,
    ).animate(_bgAnimationController);

    _bgAnimationController.repeat(reverse: true);

    _summaryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _summaryFadeAnimation = CurvedAnimation(
      parent: _summaryAnimationController,
      curve: Curves.easeIn,
    );

    _summaryScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _summaryAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _summaryAnimationController.forward();

    _tableAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _tableFadeAnimation = CurvedAnimation(
      parent: _tableAnimationController,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _tableAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _summaryAnimationController.dispose();
    _tableAnimationController.dispose();
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
                colors: [_color1Animation.value!, _color2Animation.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Stack(
                  children: [
                    _isLoading
                        ? const Center(
                            child: PulsatingLoader(color: Colors.blue),
                          )
                        : _errorMsg != null
                            ? Center(
                                child: Text(
                                  'Ошибка: $_errorMsg',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontFamily: 'RobotoMono',
                                  ),
                                ),
                              )
                            : FadeTransition(
                                opacity: _summaryFadeAnimation,
                                child: ScaleTransition(
                                  scale: _summaryScaleAnimation,
                                  child: _buildMainContent(),
                                ),
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: GradientText(
        'Касса',
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

  Widget _buildMainContent() {
    final somBalance = (_analyticsData?['som_balance'] ?? 0).toDouble();
    final totalProfit = (_analyticsData?['total_profit'] ?? 0).toDouble();
    final details = _analyticsData?['details'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFilterAndSummary(somBalance, totalProfit),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _tableFadeAnimation,
            child: _buildDataTable(details),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSummary(double somBalance, double totalProfit) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.black.withOpacity(0.7),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выберите период:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      items: _periods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(
                            _capitalize(period),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPeriod = value;
                          });
                          _fetchAnalytics();
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey.shade800,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAnimatedCounter(
                    label: 'Som баланс',
                    value: somBalance,
                    color: Colors.blueAccent,
                  ),
                  _buildAnimatedCounter(
                    label: 'Общий профит',
                    value: totalProfit,
                    color: totalProfit >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCounter({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        GradientText(
          _formatCurrency(value),
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'RobotoMono',
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<dynamic> details) {
    if (details.isEmpty) {
      return const Text(
        'Нет данных для отображения.',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          color: Colors.white,
          fontSize: 18,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.grey.shade900.withOpacity(0.8),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.indigo.shade700,
            ),
            dataRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.grey.shade800,
            ),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'RobotoMono',
            ),
            dataTextStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'RobotoMono',
            ),
            columns: const [
              DataColumn(label: Text('Валюта')),
              DataColumn(label: Text('Баланс')),
              DataColumn(label: Text('Куплено')),
              DataColumn(label: Text('Средн. Покупка')),
              DataColumn(label: Text('Продано')),
              DataColumn(label: Text('Средн. Продажа')),
              DataColumn(label: Text('Профит')),
            ],
            rows: details.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item['currency'] ?? 'N/A')),
                  DataCell(
                    Text(
                      (item['balance'] ?? 0).toDouble().toStringAsFixed(2),
                    ),
                  ),
                  DataCell(Text(item['buy_count']?.toString() ?? '0')),
                  DataCell(
                    Text(
                      (item['avg_buy_rate'] ?? 0).toDouble().toStringAsFixed(2),
                    ),
                  ),
                  DataCell(Text(item['sell_count']?.toString() ?? '0')),
                  DataCell(
                    Text(
                      (item['avg_sell_rate'] ?? 0)
                          .toDouble()
                          .toStringAsFixed(2),
                    ),
                  ),
                  DataCell(
                    Text(
                      item['profit']?.toStringAsFixed(2) ?? '0.00',
                      style: TextStyle(
                        color: (item['profit'] != null &&
                                (item['profit'] as num) >= 0)
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _analyticsData = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse(
        'http://192.168.212.129:8000/api/analytics/?period=$_selectedPeriod',
      );
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _analyticsData = jsonDecode(response.body);
          _summaryAnimationController.forward(from: 0.0);
          _tableAnimationController.forward(from: 0.0);
        });
      } else {
        setState(() {
          _errorMsg = '${response.statusCode}: ${response.body}';
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
}
