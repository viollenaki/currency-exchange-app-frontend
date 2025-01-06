import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMsg;
  AdvancedAnalyticsData? _analyticsData;

  String _selectedPeriod = 'week';

  late AnimationController _screenFadeController;
  late Animation<double> _screenFadeAnimation;

  late AnimationController _metricsScaleController;
  late Animation<double> _metricsScaleAnimation;

  late AnimationController _tableSlideController;
  late Animation<Offset> _tableSlideAnimation;

  late AnimationController _miniTablesFadeController;
  late Animation<double> _miniTablesFadeAnimation;

  static const Color primaryRed = Color(0xFFCC353C);
  static const Color primaryBlue = Color(0xFF0B3A96);
  static const Color darkBlue = Color(0xFF030836);
  static const Color blackColor = Color(0xFF000000);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFF44336);
  static const Color cardBackground = Color(0xFFFFFFFF);
  @override
  void initState() {
    super.initState();
    _fetchAnalytics();

    _screenFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _screenFadeAnimation = CurvedAnimation(
      parent: _screenFadeController,
      curve: Curves.easeIn,
    );
    _screenFadeController.forward();

    _metricsScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _metricsScaleAnimation = CurvedAnimation(
      parent: _metricsScaleController,
      curve: Curves.easeOutBack,
    );

    _tableSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tableSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tableSlideController,
        curve: Curves.easeInOut,
      ),
    );

    _miniTablesFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _miniTablesFadeAnimation = CurvedAnimation(
      parent: _miniTablesFadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _screenFadeController.dispose();
    _metricsScaleController.dispose();
    _tableSlideController.dispose();
    _miniTablesFadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMsg = "Нет токена, авторизуйтесь!";
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
          'https://exchanger-erbolsk.pythonanywhere.com/api/analytics/advanced/?period=$_selectedPeriod');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analyticsData = AdvancedAnalyticsData.fromJson(data);
        });
        _metricsScaleController.forward(from: 0.0);
        _tableSlideController.forward(from: 0.0);
        _miniTablesFadeController.forward(from: 0.0);
      } else {
        setState(() {
          _errorMsg = "Ошибка: ${response.statusCode}, ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Ошибка: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<CurrencyDetail> get top2MostProfitable {
    if (_analyticsData == null) return [];
    final sorted = [..._analyticsData!.details];
    sorted.sort((a, b) => b.profit.compareTo(a.profit));
    return sorted.take(2).toList();
  }

  List<CurrencyDetail> get top2LeastProfitable {
    if (_analyticsData == null) return [];
    final sorted = [..._analyticsData!.details];
    sorted.sort((a, b) => a.profit.compareTo(b.profit));
    return sorted.take(2).toList();
  }

  List<CurrencyDetail> get top2MostPopular {
    if (_analyticsData == null) return [];
    final sorted = [..._analyticsData!.details];
    sorted.sort((a, b) =>
        (b.buyCount + b.sellCount).compareTo(a.buyCount + a.sellCount));
    return sorted.take(2).toList();
  }

  List<CurrencyDetail> get top2LeastPopular {
    if (_analyticsData == null) return [];
    final sorted = [..._analyticsData!.details];
    sorted.sort((a, b) =>
        (a.buyCount + a.sellCount).compareTo(b.buyCount + b.sellCount));
    return sorted.take(2).toList();
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: ScaleTransition(
        scale: _metricsScaleAnimation,
        child: Card(
          color: color,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeakHours(List<PeakHour> peakHours) {
    return FadeTransition(
      opacity: _miniTablesFadeAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Часы пик',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade900,
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.deepPurple,
                thickness: 1.2,
                height: 30,
              ),
              if (peakHours.isEmpty)
                const Text(
                  "Нет данных",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: peakHours.length,
                  itemBuilder: (context, index) {
                    final peak = peakHours[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.schedule, color: Colors.deepPurple),
                      title: Text(
                        peak.hour,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        "${peak.operationCount} оп.",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    if (_analyticsData == null) return Container();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard(
          "Общая прибыль",
          "${_analyticsData!.totalProfit.toStringAsFixed(2)} Сом",
          accentGreen,
        ),
        _buildMetricCard(
          "Средняя прибыль\nна транзакцию",
          "${_analyticsData!.averageProfitPerTransaction.toStringAsFixed(2)} Сом",
          primaryBlue,
        ),
        _buildMetricCard(
          "Всего покупок",
          "${_analyticsData!.totalBuys}",
          Colors.purple.shade700,
        ),
        _buildMetricCard(
          "Всего продаж",
          "${_analyticsData!.totalSells}",
          Colors.red.shade700,
        ),
        _buildMetricCard(
          "Общее кол-во\nопераций",
          "${_analyticsData!.overallOperations}",
          Colors.teal.shade700,
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown() {
    final periods = {
      "week": "Неделя",
      "month": "Месяц",
      "3months": "3 месяца",
      "3days": "3 дня",
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Период:",
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue),
          ),
          child: DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.black87,
            ),
            dropdownColor: Colors.white,
            iconEnabledColor: primaryBlue,
            onChanged: (val) {
              if (val != null && val != _selectedPeriod) {
                setState(() {
                  _selectedPeriod = val;
                });
                _fetchAnalytics();
              }
            },
            items: periods.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    if (_analyticsData == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Обзор аналитики",
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildPeriodDropdown(),
        const SizedBox(height: 16),
        _buildSummaryMetrics(),
        const SizedBox(height: 24),
        _buildPeakHours(_analyticsData!.peakHours),
      ],
    );
  }

  Widget _buildMiniTable(String title, List<CurrencyDetail> details,
      {bool isPopularity = false}) {
    return FadeTransition(
      opacity: _miniTablesFadeAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBackground,
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const Divider(
                color: Colors.deepPurple,
                thickness: 1.2,
                height: 30,
              ),
              if (details.isEmpty)
                const Text(
                  "Нет данных",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                )
              else
                for (var d in details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          d.currency,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!isPopularity)
                          Text(
                            "${d.profit.toStringAsFixed(2)} Сом",
                            style: TextStyle(
                              fontSize: 14,
                              color: d.profit >= 0 ? accentGreen : accentRed,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            "${(d.buyCount + d.sellCount).toStringAsFixed(0)} оп.",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.black87,
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

  FadeTransition _buildMiniTablesRow() {
    return FadeTransition(
      opacity: _miniTablesFadeAnimation,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMiniTable("2 самых прибыльных", top2MostProfitable),
            const SizedBox(width: 16),
            _buildMiniTable("2 наименее прибыльных", top2LeastProfitable),
            const SizedBox(width: 16),
            _buildMiniTable("2 самых популярных", top2MostPopular,
                isPopularity: true),
            const SizedBox(width: 16),
            _buildMiniTable("2 наименее популярных", top2LeastPopular,
                isPopularity: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDetailsTable(List<CurrencyDetail> details) {
    return DataTable(
      columns: const [
        DataColumn(
          label: Text(
            'Валюта',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Покупок',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Продаж',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Средний курс покупки',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Средний курс продажи',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Прибыль',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
      rows: details.map((detail) {
        return DataRow(
          color: MaterialStateColor.resolveWith(
            (states) =>
                detail.profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          ),
          cells: [
            DataCell(Text(
              detail.currency,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            )),
            DataCell(Text(
              detail.buyCount.toStringAsFixed(0),
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            )),
            DataCell(Text(
              detail.sellCount.toStringAsFixed(0),
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            )),
            DataCell(Text(
              detail.avgBuyRate.toStringAsFixed(4),
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            )),
            DataCell(Text(
              detail.avgSellRate.toStringAsFixed(4),
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            )),
            DataCell(Text(
              "${detail.profit.toStringAsFixed(2)} Сом",
              style: TextStyle(
                fontSize: 14,
                color: detail.profit >= 0 ? accentGreen : accentRed,
                fontWeight: FontWeight.bold,
              ),
            )),
          ],
        );
      }).toList(),
      headingRowColor: MaterialStateColor.resolveWith(
        (states) => primaryBlue.withOpacity(0.1),
      ),
      columnSpacing: 24,
      horizontalMargin: 20,
      dataRowHeight: 60,
      headingRowHeight: 60,
      dividerThickness: 1,
      dataRowColor: MaterialStateColor.resolveWith((states) => Colors.white),
    );
  }

  Widget _buildDetailsSection() {
    if (_analyticsData == null) return Container();

    return SlideTransition(
      position: _tableSlideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_chart,
                    color: primaryBlue,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Полная информация по валютам',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.deepPurple,
                thickness: 1.2,
                height: 30,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildMainDetailsTable(_analyticsData!.details),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsSection(),
          const SizedBox(height: 24),
          _buildMiniTablesRow(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Расширенная аналитика"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue,
                  primaryRed,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _screenFadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade100,
                Colors.blue.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                  ),
                )
              : _errorMsg != null
                  ? _buildError()
                  : _analyticsData == null
                      ? const Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : _buildAnalyticsContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _errorMsg!,
                style: GoogleFonts.roboto(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdvancedAnalyticsData {
  final String period;
  final DateTime startTime;
  final DateTime endTime;
  final double totalProfit;
  final double averageProfitPerTransaction;
  final int totalTransactions;
  final int totalBuys;
  final int totalSells;
  final int overallOperations;
  final List<PeakHour> peakHours;
  final List<CurrencyDetail> details;

  AdvancedAnalyticsData({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.totalProfit,
    required this.averageProfitPerTransaction,
    required this.totalTransactions,
    required this.totalBuys,
    required this.totalSells,
    required this.overallOperations,
    required this.peakHours,
    required this.details,
  });

  factory AdvancedAnalyticsData.fromJson(Map<String, dynamic> json) {
    var peakHoursFromJson = json['peak_hours'] as List? ?? [];
    List<PeakHour> peakHoursList =
        peakHoursFromJson.map((e) => PeakHour.fromJson(e)).toList();

    var detailsFromJson = json['details'] as List? ?? [];
    List<CurrencyDetail> detailsList =
        detailsFromJson.map((e) => CurrencyDetail.fromJson(e)).toList();

    return AdvancedAnalyticsData(
      period: json['period'] ?? 'week',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      averageProfitPerTransaction:
          (json['average_profit_per_transaction'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['total_transactions'] ?? 0,
      totalBuys: json['total_buys'] ?? 0,
      totalSells: json['total_sells'] ?? 0,
      overallOperations: json['overall_operations'] ?? 0,
      peakHours: peakHoursList,
      details: detailsList,
    );
  }
}

class PeakHour {
  final String hour;
  final int operationCount;

  PeakHour({
    required this.hour,
    required this.operationCount,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['hour'] ?? '00:00',
      operationCount: json['operation_count'] ?? 0,
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
      currency: json['currency'] ?? 'Неизвестно',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      buyCount: (json['buy_count'] as num?)?.toDouble() ?? 0.0,
      avgBuyRate: (json['avg_buy_rate'] as num?)?.toDouble() ?? 0.0,
      sellCount: (json['sell_count'] as num?)?.toDouble() ?? 0.0,
      avgSellRate: (json['avg_sell_rate'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
