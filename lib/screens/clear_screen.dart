import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'login_screen.dart';
class ClearShiftScreen extends StatefulWidget {
  const ClearShiftScreen({Key? key}) : super(key: key);

  @override
  State<ClearShiftScreen> createState() => _ClearShiftScreenState();
}

class _ClearShiftScreenState extends State<ClearShiftScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMsg;


  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _loadCurrencies();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://exchanger-erbolsk.pythonanywhere.com/api/currencies/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> fetchedCurrencies =
            List<Map<String, dynamic>>.from(data['results'] ?? []);

        setState(() {
          _currencies = fetchedCurrencies;
        });

        _fadeController.forward(from: 0.0);
      } else {
        throw Exception("Failed to load currencies: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Error loading currencies: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearShift() async {
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final changedBalances = _currencies.where((c) {
        return c['balance'] != c['original_balance'];
      }).map((c) {
        return {
          'currency_id': c['id'],
          'leftover': c['balance'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse(
            'https://exchanger-erbolsk.pythonanywhere.com/api/shifts/clear/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'balances': changedBalances}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift cleared successfully!')),
        );
        _redirectToLogin();
      } else {
        throw Exception("Failed to clear shift: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error clearing shift: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _redirectToLogin() {
    final authProvider = context.read<AuthProvider>();
    authProvider.logout(context); // Clear token and user info
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern Gradient AppBar
      appBar: AppBar(
        title: const Text(
          "Clear Shift",
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.tealAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
                  ? _buildErrorContent()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildContent(),
                          ),
                        ),
                      ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _clearShift,
        backgroundColor: _isSubmitting ? Colors.grey : Colors.red,
        child: _isSubmitting
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              )
            : const Icon(Icons.refresh),
        tooltip: 'Clear Shift',
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMsg!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontFamily: 'RobotoMono',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCurrencies,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 16,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currencies.isEmpty) {
      return const Center(
        child: Text(
          "No currencies available",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontFamily: 'RobotoMono',
          ),
        ),
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Adjust Balances if needed",
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedList(
              key: _listKey,
              initialItemCount: _currencies.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index, animation) {
                final currency = _currencies[index];
                return _buildCurrencyItem(currency, index, animation);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _clearShift,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    )
                  : const Text("Clear Shift"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyItem(
      Map<String, dynamic> currency, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  currency['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'RobotoMono',
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: currency['balance'].toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Balance',
                    labelStyle: const TextStyle(
                      fontFamily: 'RobotoMono',
                      color: Colors.teal,
                    ),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    color: Colors.black87,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currencies[index]['balance'] =
                          double.tryParse(value) ?? currency['balance'];
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
