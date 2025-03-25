import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:currency_exchange_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:currency_exchange_app/providers/auth_provider.dart';

class OperationsHistoryScreen extends StatefulWidget {
  const OperationsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OperationsHistoryScreen> createState() =>
      _OperationsHistoryScreenState();
}

class _OperationsHistoryScreenState extends State<OperationsHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _operations = [];
  bool _isLoading = false;
  String? _errorMsg;

  int _currentPage = 1;
  String? _nextUrl;
  String? _prevUrl;

  final List<String> _periods = ['shift', '3days', 'week'];
  String _selectedPeriod = 'shift';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(_fadeAnimation);

    _fetchOperations(page: _currentPage, period: _selectedPeriod);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchOperations({
    required int page,
    required String period,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _operations.clear();
    });

    final token = context.read<AuthProvider>().token;
    final url = Uri.parse(
      'http://192.168.212.129:8000/api/operations/?page=$page&period=$period',
    );
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        setState(() {
          _operations = results;
          _nextUrl = data['next'];
          _prevUrl = data['previous'];
          _currentPage = page;
        });
        // Start animation
        _controller.forward(from: 0.0);
      } else {
        setState(() {
          _errorMsg = 'Error ${response.statusCode}: ${response.body}';
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

  // Dialog to edit "amount" or "exchange_rate"
  void _showEditDialog(Map<String, dynamic> operation) {
    final amountController = TextEditingController(
      text: '${operation["amount"]}',
    );
    final rateController = TextEditingController(
      text: '${operation["exchange_rate"]}',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutBack,
          ),
          child: AlertDialog(
            backgroundColor: Colors.grey.shade800.withOpacity(0.9),
            title: const Text(
              'Edit Operation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'RobotoMono',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'New Amount',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'New Rate',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _editOperation(
                    operation,
                    newAmountStr: amountController.text,
                    newRateStr: rateController.text,
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editOperation(
    Map<String, dynamic> operation, {
    required String newAmountStr,
    required String newRateStr,
  }) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated!')));
      return;
    }

    final opId = operation['id'];
    final editUrl = Uri.parse(
      'http://192.168.212.129:8000/api/operations/$opId/edit_operation/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final newAmount = double.tryParse(newAmountStr) ?? 0;
    final newRate = double.tryParse(newRateStr) ?? 0;

    final body = jsonEncode({"amount": newAmount, "exchange_rate": newRate});

    try {
      final response = await http.patch(editUrl, headers: headers, body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation updated successfully!')),
        );
        // Refresh
        _fetchOperations(page: _currentPage, period: _selectedPeriod);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Edit error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Edit exception: $e')));
    }
  }

  Future<void> _fetchAndShowReceipt(Map<String, dynamic> operation) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated!')));
      return;
    }

    final opId = operation['id'];
    final url = Uri.parse(
      'http://192.168.212.129:8000/api/operations/$opId/generate_receipt_inline/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pdfBase64 = data['pdf_base64'];
        final filename = data['filename'] ?? 'receipt.pdf';
        if (pdfBase64 is String) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptViewerScreen(
                pdfBase64: pdfBase64,
                filename: filename,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Receipt exception: $e')));
    }
  }

  void _exitToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OperationMainScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(behaviour: null),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade700, Colors.teal.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'История операций',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                        ),
                        tooltip: 'Exit to Home',
                        onPressed: _exitToHome,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade900.withOpacity(0.9),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                            ),
                          )
                        : _errorMsg != null
                            ? Center(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  _buildPeriodDropdown(),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: _scaleAnimation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildScrollableGrid(
                                        key: ValueKey(_operations),
                                      ),
                                    ),
                                  ),
                                  _buildPaginationRow(),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.indigo.shade600,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Период:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                items: _periods.map((p) {
                  return DropdownMenuItem<String>(
                    value: p,
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedPeriod = val;
                  });
                  _fetchOperations(page: 1, period: val);
                },
                dropdownColor: Colors.grey.shade800,
                iconEnabledColor: Colors.white,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableGrid({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_operations.length, (index) {
            final op = _operations[index];
            return _buildOperationCard(op);
          }),
        ),
      ),
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> operation) {
    final double amount = double.tryParse('${operation["amount"]}') ?? 0;
    final double rate = double.tryParse('${operation["exchange_rate"]}') ?? 0;
    final double totalSom =
        double.tryParse('${operation["total_in_som"]}') ?? 0;
    final cashier = '${operation["cashier_name"] ?? "N/A"}';
    final timestamp = '${operation["timestamp"] ?? "N/A"}';
    final currencyName = operation["currency_name"] ?? 'N/A';

    final opType = '${operation["operation_type"] ?? "?"}';
    final isBuy = (opType == 'buy');
    final arrowIcon = isBuy ? Icons.arrow_downward : Icons.arrow_upward;
    final arrowColor = isBuy ? Colors.tealAccent : Colors.deepOrangeAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 270,
      height: 220,
      decoration: BoxDecoration(
        color: isBuy ? Colors.grey.shade800 : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black26,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: isBuy ? Colors.tealAccent : Colors.deepOrangeAccent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(arrowIcon, color: arrowColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$currencyName (ID: ${operation["id"]})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54),
            Expanded(
              child: Center(
                child: Text(
                  'Сумма: ${amount.toStringAsFixed(2)}\n'
                  'Курс: ${rate.toStringAsFixed(4)}\n'
                  'Общий (сом): ${totalSom.toStringAsFixed(2)}\n'
                  'Кассир: $cashier\n'
                  'Время: $timestamp',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showEditDialog(operation),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 5,
                    shadowColor: Colors.indigo.shade300,
                  ),
                ),
                // Receipt Button
                ElevatedButton.icon(
                  onPressed: () => _fetchAndShowReceipt(operation),
                  icon: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Receipt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 5,
                    shadowColor: Colors.deepOrange.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    return Container(
      color: Colors.indigo.shade700,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Prev Button
          ElevatedButton.icon(
            onPressed: (_prevUrl == null || _currentPage <= 1)
                ? null
                : () {
                    _fetchOperations(
                      page: _currentPage - 1,
                      period: _selectedPeriod,
                    );
                  },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text(
              'Предыдущая',
              style: TextStyle(color: Colors.white, fontFamily: 'RobotoMono'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 5,
              shadowColor: Colors.indigo.shade300,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Страница $_currentPage',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(width: 20),
          // Next Button
          ElevatedButton.icon(
            onPressed: (_nextUrl == null)
                ? null
                : () {
                    _fetchOperations(
                      page: _currentPage + 1,
                      period: _selectedPeriod,
                    );
                  },
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Следующая',
              style: TextStyle(color: Colors.white, fontFamily: 'RobotoMono'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 5,
              shadowColor: Colors.indigo.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptViewerScreen extends StatefulWidget {
  final String pdfBase64;
  final String filename;

  const ReceiptViewerScreen({
    Key? key,
    required this.pdfBase64,
    required this.filename,
  }) : super(key: key);

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  late Uint8List _pdfBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rawBytes = base64Decode(widget.pdfBase64);
    _pdfBytes = Uint8List.fromList(rawBytes);
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not find the downloads directory');
      }
      final filePath = '${directory.path}/${widget.filename}';
      final file = File(filePath);
      await file.writeAsBytes(_pdfBytes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to: $filePath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _exitViewer() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filename,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Exit Viewer',
            onPressed: _exitViewer,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 750),
                color: Colors.grey.shade800,
                child: _pdfBytes.isEmpty
                    ? const Center(
                        child: Text(
                          'PDF is empty',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'RobotoMono',
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SfPdfViewer.memory(
                        _pdfBytes,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                      ),
              ),
            ),
          ),
          Container(
            color: Colors.indigo.shade700,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _exitViewer,
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  label: const Text(
                    'Exit',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 5,
                    shadowColor: Colors.red.shade300,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _downloadPdf,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: _isSaving
                      ? const Text(
                          'Downloading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'RobotoMono',
                          ),
                        )
                      : const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 5,
                    shadowColor: Colors.indigo.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
