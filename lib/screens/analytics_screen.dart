import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';

import 'package:currency_exchange_app/providers/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final List<String> _periods = ['3days', 'week', 'month', '3months'];
  String _selectedPeriod = '3days';

  AnalyticsData? _analyticsData;
  bool _isLoading = false;
  String? _error;

  late final AnimationController _screenFadeController;
  late final Animation<double> _screenFadeAnimation;

  late final AnimationController _dataFadeController;
  late final Animation<double> _dataFadeAnimation;

  late final AnimationController _tableSlideController;
  late final Animation<Offset> _tableSlideAnimation;

  final ThemeData _themeData = ThemeData(
    primarySwatch: Colors.blue,
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  static const Color primaryColor = Color(0xFF0B3A96);
  static const Color accentColor = Color(0xFFCC353C);
  static const Color backgroundColor = Color(0xFFF3F8FF);

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();

    _screenFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _screenFadeAnimation =
        CurvedAnimation(parent: _screenFadeController, curve: Curves.easeIn);
    _screenFadeController.forward();

    _dataFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dataFadeAnimation =
        CurvedAnimation(parent: _dataFadeController, curve: Curves.easeIn);

    _tableSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tableSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _tableSlideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _screenFadeController.dispose();
    _dataFadeController.dispose();
    _tableSlideController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Нет токена, авторизуйтесь!';
      });
      return;
    }

    const String baseUrl = 'https://exchanger-erbolsk.pythonanywhere.com';
    const String endpoint = '/api/analytics/';
    final Uri uri = Uri.parse('$baseUrl$endpoint?period=$_selectedPeriod');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _analyticsData = AnalyticsData.fromJson(jsonResponse);
          _isLoading = false;
        });

        // Start fade for data
        _dataFadeController.forward(from: 0.0);
        // Start slide for the table
        _tableSlideController.forward(from: 0.0);
      } else {
        setState(() {
          _error =
              'Ошибка ${response.statusCode}: ${response.reasonPhrase ?? 'Неизвестная ошибка'}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка сети: $e';
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String? newPeriod) {
    if (newPeriod != null && newPeriod != _selectedPeriod) {
      setState(() => _selectedPeriod = newPeriod);
      _fetchAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _themeData,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Аналитика',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _screenFadeAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                )
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : _analyticsData != null
                                      ? FadeTransition(
                                          opacity: _dataFadeAnimation,
                                          child: _buildAnalyticsContent(),
                                        )
                                      : const Center(
                                          child: Text(
                                            'Нет данных',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, accentColor],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Период:',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedPeriod,
            items: _periods.map((period) {
              final displayText = _getPeriodDisplay(period);
              return DropdownMenuItem<String>(
                value: period,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onPeriodChanged,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            iconEnabledColor: Colors.white,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: primaryColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: accentColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Сводка',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Период:',
                    _getPeriodDisplay(_analyticsData!.period),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Баланс (Сом):',
                    _analyticsData!.somBalance.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Общая прибыль:',
                    _analyticsData!.totalProfit.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'С начала периода:',
                    _formatDateTime(_analyticsData!.startTime),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'До текущего момента:',
                    _formatDateTime(_analyticsData!.endTime),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SlideTransition(
            position: _tableSlideAnimation,
            child: _buildDetailsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTable() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      shadowColor: primaryColor.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            Row(
              children: [
                const Icon(
                  Icons.table_chart_outlined,
                  color: accentColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Детали',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateColor.resolveWith(
                  (states) => primaryColor.withOpacity(0.1),
                ),
                columns: _buildDataColumns(),
                rows: _buildDataRows(),
                dividerThickness: 1,
                dataRowHeight: 60,
                headingRowHeight: 70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    const TextStyle headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: primaryColor,
    );

    return [
      const DataColumn(label: Text('Валюта', style: headerStyle)),
      const DataColumn(label: Text('Баланс', style: headerStyle)),
      const DataColumn(label: Text('Покупок', style: headerStyle)),
      const DataColumn(label: Text('Средн. курс покупки', style: headerStyle)),
      const DataColumn(label: Text('Продаж', style: headerStyle)),
      const DataColumn(label: Text('Средн. курс продажи', style: headerStyle)),
      const DataColumn(label: Text('Прибыль', style: headerStyle)),
    ];
  }

  List<DataRow> _buildDataRows() {
    return _analyticsData!.details.asMap().entries.map((entry) {
      final index = entry.key;
      final detail = entry.value;

      return DataRow(
        color: MaterialStateColor.resolveWith(
          (states) => index % 2 == 0 ? Colors.white : Colors.grey.shade100,
        ),
        cells: [
          _buildDataCell(detail.currency),
          _buildDataCell(detail.balance.toStringAsFixed(2)),
          _buildDataCell(detail.buyCount.toStringAsFixed(2)),
          _buildDataCell(detail.avgBuyRate.toStringAsFixed(4)),
          _buildDataCell(detail.sellCount.toStringAsFixed(2)),
          _buildDataCell(detail.avgSellRate.toStringAsFixed(4)),
          _buildDataCell(detail.profit.toStringAsFixed(2)),
        ],
      );
    }).toList();
  }

  DataCell _buildDataCell(String value) {
    return DataCell(
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  String _getPeriodDisplay(String period) {
    switch (period) {
      case '3days':
        return '3 дня';
      case 'week':
        return 'Неделя';
      case 'month':
        return 'Месяц';
      case '3months':
        return '3 месяца';
      default:
        return period;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class AnalyticsData {
  final String period;
  final DateTime startTime;
  final DateTime endTime;
  final double somBalance;
  final double totalProfit;
  final List<CurrencyDetail> details;

  AnalyticsData({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.somBalance,
    required this.totalProfit,
    required this.details,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] as List;
    final detailsList =
        detailsJson.map((e) => CurrencyDetail.fromJson(e)).toList();
    return AnalyticsData(
      period: json['period'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      somBalance: (json['som_balance'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
      details: detailsList,
    );
  }
}

class CurrencyDetail {
  final String currency;
  final double balance;
  final double buyCount;
  final double avgBuyRate;
  final double sellCount;
  final double avgSellRate;
  final double profit;

  CurrencyDetail({
    required this.currency,
    required this.balance,
    required this.buyCount,
    required this.avgBuyRate,
    required this.sellCount,
    required this.avgSellRate,
    required this.profit,
  });

  factory CurrencyDetail.fromJson(Map<String, dynamic> json) {
    return CurrencyDetail(
      currency: json['currency'],
      balance: (json['balance'] as num).toDouble(),
      buyCount: (json['buy_count'] as num).toDouble(),
      avgBuyRate: (json['avg_buy_rate'] as num).toDouble(),
      sellCount: (json['sell_count'] as num).toDouble(),
      avgSellRate: (json['avg_sell_rate'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }
}
