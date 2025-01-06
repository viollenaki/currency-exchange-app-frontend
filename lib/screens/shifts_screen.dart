import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:currency_exchange_app/providers/auth_provider.dart';
import 'package:currency_exchange_app/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen>
    with SingleTickerProviderStateMixin {
      
  List<dynamic> _shifts = [];
  bool _isLoading = false;
  String? _errorMsg;

  int _currentPage = 1;
  String? _nextUrl;
  String? _prevUrl;
  int? _count;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final Color primaryColor = const Color(0xFF4A90E2); 
  final Color secondaryColor = const Color(0xFF50E3C2); 
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color cardColor = Colors.white; 
  final Color textColor = Colors.black87; 
  final Color accentColor = const Color(0xFF4A90E2); 

  @override
  void initState() {
    super.initState();

    // Initial fetch
    _fetchShifts(page: _currentPage);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchShifts({required int page}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final token = context.read<AuthProvider>().token;
    final url = Uri.parse(
        'https://exchanger-erbolsk.pythonanywhere.com/api/shifts/history/?page=$page');
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
          _shifts = results;
          _nextUrl = data['next'];
          _prevUrl = data['previous'];
          _count = data['count'];
          _currentPage = page;
        });
        _populateList();
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

  void _populateList() {
    Future ft = Future(() {});
    for (int i = 0; i < _shifts.length; i++) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listKey.currentState?.insertItem(i);
        });
      });
    }
  }

  void _exitToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OperationMainScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showEditDialog(Map<String, dynamic> shift) {
    final TextEditingController profitController = TextEditingController(
      text: shift['overall_profit']?.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Edit Shift',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profitController,
                decoration: const InputDecoration(
                  labelText: 'Profit',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: primaryColor,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () {
                final newProfit = double.tryParse(profitController.text);
                if (newProfit != null) {
                  Navigator.of(ctx).pop();
                  _editShift(shift['id'], newProfit);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid profit value.'),
                    ),
                  );
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editShift(int shiftId, double newProfit) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated!')),
      );
      return;
    }

    final editUrl = Uri.parse(
      'https://exchanger-erbolsk.pythonanywhere.com/api/shifts/$shiftId/edit/',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'overall_profit': newProfit,
    });

    try {
      final response = await http.patch(editUrl, headers: headers, body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift updated successfully!')),
        );
        _fetchShifts(page: _currentPage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edit exception: $e')),
      );
    }
  }

  void _navigateToReceipt(String pdfBase64, String filename) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReceiptViewerScreen(pdfBase64: pdfBase64, filename: filename),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 2;
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'История смен',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, 
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Exit to Home',
            onPressed: _exitToHome,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : _errorMsg != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: AnimatedList(
                            key: _listKey,
                            initialItemCount: 0,
                            itemBuilder:
                                (context, index, Animation<double> animation) {
                              final shift = _shifts[index];
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: _buildShiftCard(shift),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      _buildPaginationRow(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final id = shift['id'] ?? 'N/A';
    final startTime = shift['start_time'] ?? 'N/A';
    final endTime = shift['end_time'] ?? 'N/A';
    final cashier = shift['cashier_name'] ?? 'N/A';
    final opsCount = shift['operations_count']?.toString() ?? '0';
    final profit =
        double.tryParse(shift['overall_profit']?.toString() ?? '0.00')
                ?.toStringAsFixed(2) ??
            '0.00';
    final changed = shift['changed_balances'] ?? [];

    final changedBalancesText = (changed is List && changed.isNotEmpty)
        ? changed.map((item) {
            final cName = item['currency_name'] ?? '???';
            final oldB = item['old_balance'] ?? 0;
            final newB = item['new_balance'] ?? 0;
            return '$cName: $oldB → $newB';
          }).join('\n')
        : 'No changes';

    return Center(
      child: SizedBox(
        width: 300, 
        child: Card(
          color: cardColor,
          elevation: 3,
          shadowColor: primaryColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: secondaryColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SHIFT #$id',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'PROFIT: \$${profit}',
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'START: $startTime\nEND:   $endTime',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'CASHIER: $cashier',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'OPERATIONS: $opsCount',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    changedBalancesText,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: (_prevUrl == null || _currentPage <= 1)
                ? null
                : () => _fetchShifts(page: _currentPage - 1),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text(
              'Предыдущая',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: (_prevUrl == null || _currentPage <= 1)
                  ? Colors.grey
                  : primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 3,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Страница $_currentPage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: (_nextUrl == null)
                ? null
                : () => _fetchShifts(page: _currentPage + 1),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Следующая',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: (_nextUrl == null) ? Colors.grey : primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 3,
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

  final Color primaryColor = const Color(0xFF4A90E2); 
  final Color secondaryColor = const Color(0xFF50E3C2); 
  final Color backgroundColor = const Color(0xFFF5F5F5); 

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
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.filename}';
      final file = File(filePath);
      await file.writeAsBytes(_pdfBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
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
              fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Exit Viewer',
            onPressed: _exitViewer,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 750),
                color: Colors.white,
                child: _pdfBytes.isEmpty
                    ? const Center(child: Text('PDF is empty'))
                    : SfPdfViewer.memory(
                        _pdfBytes,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                      ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
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
                      fontFamily: 'Roboto',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    elevation: 3,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: _isSaving
                      ? const Text(
                          'Downloading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                          ),
                        )
                      : const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    elevation: 3,
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
