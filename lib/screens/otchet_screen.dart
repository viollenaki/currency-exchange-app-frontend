import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:currency_exchange_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:currency_exchange_app/screens/history_screen.dart';
import 'package:currency_exchange_app/screens/advanced_analytics_screen.dart';
import 'package:currency_exchange_app/screens/analytics_screen.dart';
import 'package:currency_exchange_app/screens/shifts_screen.dart';
import 'package:currency_exchange_app/screens/internal_history_screen.dart';

class OtchetScreen extends StatefulWidget {
  const OtchetScreen({Key? key}) : super(key: key);

  @override
  State<OtchetScreen> createState() => _OtchetScreenState();
}

class _OtchetScreenState extends State<OtchetScreen> {
  bool _showExports = false;

  final List<String> _exportTypes = [
    'operation_history',
    'event_history',
    'analytics',
  ];
  String _selectedExportType = 'operation_history';

  final List<String> _periods = ['3days', 'week', 'month', '3months', 'shift'];
  String _selectedPeriod = '3days';

  late final List<_Section> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      _Section(
        icon: Icons.analytics,
        label: 'Analytics',
        color: Colors.indigo,
        onTapLabel: 'Analytics',
        onTapFunction: _gotoAnalytics,
      ),
      _Section(
        icon: Icons.insights,
        label: 'Advanced Analytics',
        color: Colors.deepOrange,
        onTapLabel: 'Advanced Analytics',
        onTapFunction: _gotoAdvancedAnalytics,
      ),
      _Section(
        icon: Icons.history,
        label: 'Operation History',
        color: Colors.blue,
        onTapLabel: 'Operation History',
        onTapFunction: _gotoHistory,
      ),
      _Section(
        icon: Icons.work_history,
        label: 'Shifts History',
        color: const Color.fromARGB(255, 53, 155, 131),
        onTapLabel: 'Shifts History',
        onTapFunction: _gotoShiftsHistory,
      ),
      _Section(
        icon: Icons.storage,
        label: 'Internal History',
        color: Colors.purple,
        onTapLabel: 'Internal History',
        onTapFunction: _gotoInternalHistory,
      ),
      _Section(
        icon: Icons.file_download,
        label: 'Exports',
        color: Colors.green,
        onTapLabel: 'Exports',
        onTapFunction: _toggleExports,
      ),
    ];
  }

  void _gotoAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }

  void _gotoShiftsHistory() {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to Shift History'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShiftHistoryScreen()),
    );
  }

  void _toggleExports() {
    setState(() {
      _showExports = !_showExports;
    });
  }

  void _gotoInternalHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InternalHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчеты'), centerTitle: true),
      body: Container(
        // Beautiful gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purpleAccent.shade100,
              Colors.pink.shade100,
              Colors.orange.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                elevation: 16,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildMainContent(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Окно отчетов',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: _sections.map((section) {
            return _buildSectionButton(section);
          }).toList(),
        ),
        const SizedBox(height: 32),
        if (_showExports) _buildExportsForm(),
      ],
    );
  }

  Widget _buildSectionButton(_Section section) {
    return InkWell(
      onTap: () {
        if (section.onTapFunction != null) {
          section.onTapFunction!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${section.label} еще не реализовано')),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        height: 160,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: section.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: section.color.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(section.icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              section.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportsForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showExports
          ? Column(
              key: const ValueKey('exports_form'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(thickness: 1.5, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  'Экспорт в Excel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Что экспортируем',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedExportType,
                      dropdownColor: Colors.black,
                      items: _exportTypes.map((type) {
                        switch (type) {
                          case 'operation_history':
                            return const DropdownMenuItem(
                              value: 'operation_history',
                              child: Text(
                                'История Операций',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case 'event_history':
                            return const DropdownMenuItem(
                              value: 'event_history',
                              child: Text(
                                'История Действий',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case 'analytics':
                            return const DropdownMenuItem(
                              value: 'analytics',
                              child: Text(
                                'Аналитика',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          default:
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                        }
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExportType = val);
                        }
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      iconEnabledColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Период',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedPeriod,
                      dropdownColor: Colors.black,
                      items: _periods.map((p) {
                        switch (p) {
                          case '3days':
                            return const DropdownMenuItem(
                              value: '3days',
                              child: Text(
                                '3 дня',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case 'week':
                            return const DropdownMenuItem(
                              value: 'week',
                              child: Text(
                                'Неделя',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case 'month':
                            return const DropdownMenuItem(
                              value: 'month',
                              child: Text(
                                'Месяц',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case '3months':
                            return const DropdownMenuItem(
                              value: '3months',
                              child: Text(
                                '3 месяца',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          case 'shift':
                            return const DropdownMenuItem(
                              value: 'shift',
                              child: Text(
                                'Смена',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          default:
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                        }
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPeriod = val);
                        }
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      iconEnabledColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _downloadExcel,
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text(
                        'Скачать Excel',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _downloadExcel() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет токена, авторизуйтесь!')),
      );
      return;
    }

    String url = 'http://192.168.212.129:8000';
    final encodedToken = Uri.encodeComponent(token);

    switch (_selectedExportType) {
      case 'operation_history':
        url +=
            '/api/operations/export_excel/?period=$_selectedPeriod&download_token=$encodedToken';
        break;
      case 'event_history':
        url +=
            '/api/events/export_excel/?period=$_selectedPeriod&download_token=$encodedToken';
        break;
      case 'analytics':
        url +=
            '/api/analytics/export_excel/?period=$_selectedPeriod&download_token=$encodedToken';
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Неверный тип экспорта')));
        return;
    }

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть $uri')));
    }
  }

  void _gotoHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OperationsHistoryScreen()),
    );
  }

  void _gotoAdvancedAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdvancedAnalyticsScreen()),
    );
  }
}

class _Section {
  final IconData icon;
  final String label;
  final Color color;
  final String onTapLabel;
  final VoidCallback? onTapFunction;

  _Section({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTapLabel,
    this.onTapFunction,
  });
}
