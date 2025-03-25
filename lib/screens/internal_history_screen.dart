import 'dart:convert';
import 'package:currency_exchange_app/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:currency_exchange_app/providers/auth_provider.dart';

class InternalHistoryScreen extends StatefulWidget {
  const InternalHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InternalHistoryScreen> createState() => _InternalHistoryScreenState();
}

class _InternalHistoryScreenState extends State<InternalHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _histories = [];
  bool _isLoading = false;
  String? _errorMsg;

  int _currentPage = 1;
  String? _nextUrl;
  String? _prevUrl;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _fetchHistories(page: _currentPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchHistories({required int page}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _histories.clear();
    });

    final token = context.read<AuthProvider>().token;
    final url = Uri.parse(
      'http://192.168.212.129:8000/api/internal-history/?page=$page',
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
          _histories = results;
          _nextUrl = data['next'];
          _prevUrl = data['previous'];
          _currentPage = page;
        });
        _controller.forward(from: 0.0);
      } else {
        setState(() {
          _errorMsg = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
    } catch (e) {
      return timestamp;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Internal History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
            : _errorMsg != null
                ? Center(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1000) {
                        return Column(
                          children: [
                            const SizedBox(height: 20),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: _buildDataTable(
                                    key: ValueKey(_histories),
                                  ),
                                ),
                              ),
                            ),
                            _buildPaginationRow(),
                            const SizedBox(height: 20),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            const SizedBox(height: 20),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: _buildScrollableCards(
                                    key: ValueKey(_histories),
                                  ),
                                ),
                              ),
                            ),
                            _buildPaginationRow(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                    },
                  ),
      ),
    );
  }

  Widget _buildDataTable({Key? key}) {
    return SingleChildScrollView(
      key: key,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => Colors.purple.shade700,
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Event ID',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Event Type',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Cashier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Target User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Currency',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: _histories.map((history) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${history["id"]}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                DataCell(
                  Text(
                    '${history["event_type"] ?? "N/A"}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                DataCell(
                  Text(
                    '${history["user"] ?? "N/A"}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                DataCell(
                  Text(
                    '${history["target_user"] ?? "N/A"}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                DataCell(
                  Text(
                    '${history["currency"] ?? "N/A"}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTimestamp('${history["timestamp"] ?? "N/A"}'),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScrollableCards({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: _histories.map((history) {
          return _buildHistoryCard(history);
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade100,
                blurRadius: 12,
                offset: const Offset(6, 6),
              ),
            ],
            border: Border.all(color: Colors.purple.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${history["id"]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.purple,
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${history["event_type"] ?? "N/A"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.purple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Details
              Text(
                'Cashier: ${history["user"] ?? "N/A"}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Target User: ${history["target_user"] ?? "N/A"}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Currency: ${history["currency"] ?? "N/A"}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Time: ${_formatTimestamp('${history["timestamp"] ?? "N/A"}')}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    _showDetailsDialog(history);
                  },
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Details', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> history) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: AlertDialog(
            title: Text('Details for ID: ${history["id"]}'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('Event Type: ${history["event_type"] ?? "N/A"}'),
                  Text('Cashier: ${history["user"] ?? "N/A"}'),
                  Text('Target User: ${history["target_user"] ?? "N/A"}'),
                  Text('Currency: ${history["currency"] ?? "N/A"}'),
                  Text(
                    'Time: ${_formatTimestamp('${history["timestamp"] ?? "N/A"}')}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _fetchAndShowReceipt(history);
                },
                child: const Text('View Receipt'),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildPaginationRow() {
    return Container(
      color: Colors.purple.shade50,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: (_prevUrl == null || _currentPage <= 1)
                ? null
                : () {
                    _fetchHistories(page: _currentPage - 1);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text('Previous', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 30),
          Text(
            'Page $_currentPage',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 30),
          ElevatedButton(
            onPressed: (_nextUrl == null)
                ? null
                : () {
                    _fetchHistories(page: _currentPage + 1);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
