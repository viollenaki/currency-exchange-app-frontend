import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:vitality/vitality.dart';
import 'package:currency_exchange_app/providers/auth_provider.dart';

import 'package:currency_exchange_app/screens/valuta_screen.dart';
import 'package:currency_exchange_app/screens/otchet_screen.dart';
import 'package:currency_exchange_app/screens/cassa_screen.dart';
import 'package:currency_exchange_app/screens/users_screen.dart';
import 'package:currency_exchange_app/screens/clear_screen.dart';
import 'package:currency_exchange_app/screens/history_screen.dart';
import 'package:currency_exchange_app/screens/login_screen.dart';

class GlowingButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color textColor;

  const GlowingButton({
    Key? key,
    required this.text,
    required this.color,
    this.onPressed,
    this.isLoading = false,
    this.textColor = Colors.white,
    required Icon child,
  }) : super(key: key);

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _pressAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_pressController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _pressAnimation,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: widget.isLoading ? null : widget.onPressed,
                child: widget.isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: AnimatedLoader(), // Custom Animated Loader
                      )
                    : Text(
                        widget.text,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedLoader extends StatefulWidget {
  const AnimatedLoader({Key? key}) : super(key: key);

  @override
  _AnimatedLoaderState createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _loaderController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 2 * 3.1416).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loaderController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
      child: const Icon(
        Icons.autorenew,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({Key? key, required behaviour}) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  // Interface Colors
  static const Color primaryRed = Color(0xFFCC353C); // Red
  static const Color primaryBlue = Color(0xFF0B3A96); // Blue
  static const Color darkBlue = Color(0xFF030836); // Dark Blue
  static const Color blackColor = Color(0xFF000000); // Black

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final itemsCount = (width * height / 10000).clamp(100, 1000).toInt();
        final maxSize = (width / 30).clamp(8.0, 38.0);
        final minSize = (width / 60).clamp(4.0, 16.0);

        final backgroundKey = ValueKey('${width.toInt()}x${height.toInt()}');

        return Vitality.randomly(
          key: backgroundKey,
          background: darkBlue,
          maxOpacity: 0.8,
          minOpacity: 0.3,
          itemsCount: itemsCount,
          enableXMovements: false,
          whenOutOfScreenMode: WhenOutOfScreenMode.Teleport,
          maxSpeed: 1.3,
          maxSize: maxSize,
          minSize: minSize,
          minSpeed: 0.4,
          randomItemsColors: [primaryRed, primaryBlue],
          randomItemsBehaviours: [
            ItemBehaviour(shape: ShapeType.FilledSquare),
            ItemBehaviour(shape: ShapeType.StrokeSquare),
          ],
        );
      },
    );
  }
}

class OperationMainScreen extends StatefulWidget {
  const OperationMainScreen({Key? key}) : super(key: key);

  @override
  State<OperationMainScreen> createState() => _OperationMainScreenState();
}

class _OperationMainScreenState extends State<OperationMainScreen>
    with TickerProviderStateMixin {
  bool isBuy = true;

  List<Map<String, dynamic>> _currencies = [];
  int? selectedCurrencyId;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _totalCtrl = TextEditingController();

  bool _isLoadingAdd = false;
  bool _isLoadingCurrencies = false;
  String? _errorMsg;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _allCashiers = [];
  int? _currentCashierId;
  bool _isLoadingCashiers = false;
  String? _cashierError;

  static const Color primaryRed = Color(0xFFCC353C);
  static const Color secondaryDarkRed = Color(0xFF5E0414);
  static const Color primaryBlue = Color(0xFF0B3A96);
  static const Color darkBlue = Color(0xFF030836);
  static const Color blackColor = Color(0xFF000000);
  static const Color sellRed = primaryRed;

  late AnimationController _titleAnimationController;
  late Animation<double> _titleAnimation;

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
    _fadeController.forward();

    _titleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleAnimation = CurvedAnimation(
        parent: _titleAnimationController, curve: Curves.easeIn);

    _amountCtrl.addListener(_updateTotal);
    _rateCtrl.addListener(_updateTotal);

    _fetchCurrencies();
    _fetchCurrentCashier();
    _fetchAllCashiers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleAnimationController.dispose();
    _amountCtrl.removeListener(_updateTotal);
    _rateCtrl.removeListener(_updateTotal);
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentCashier() async {
    setState(() => _cashierError = null);

    final token = context.read<AuthProvider>().token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final url = Uri.parse(
          'http://exchanger-erbolsk.pythonanywhere.com/api/shifts/current_cashier/');
      final resp = await http.get(url, headers: headers);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (!mounted) return;
        setState(() {
          _currentCashierId = data['cashier_id'] as int?;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _cashierError =
              'Error fetching shift cashier: ${resp.statusCode} ${resp.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cashierError = 'Exception: $e';
      });
    }
  }

  Future<void> _fetchAllCashiers() async {
    setState(() {
      _isLoadingCashiers = true;
      _cashierError = null;
    });

    final token = context.read<AuthProvider>().token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final url = Uri.parse(
          'http://exchanger-erbolsk.pythonanywhere.com/api/users/?role=cashier');
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;

          if (!mounted) return;
          setState(() {
            _allCashiers = results
                .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
                .toList();

            if (_currentCashierId == null && _allCashiers.isNotEmpty) {
              _currentCashierId = _allCashiers.first['id'] as int?;
            }
          });
        } else {
          if (!mounted) return;
          setState(() {
            _cashierError =
                'Invalid cashiers list format: "results" key missing';
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _cashierError =
              'Error loading cashiers: ${resp.statusCode} ${resp.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cashierError = 'Exception: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingCashiers = false);
    }
  }

  Future<void> _changeCashier(int? newId) async {
    if (newId == null) return;
    final token = context.read<AuthProvider>().token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final url = Uri.parse(
          'http://exchanger-erbolsk.pythonanywhere.com/api/shifts/set_cashier/');
      final body = jsonEncode({"cashier_id": newId});
      final resp = await http.post(url, headers: headers, body: body);
      if (resp.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _currentCashierId = newId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cashier changed successfully!')),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _cashierError =
              'Error setting cashier: ${resp.statusCode} ${resp.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cashierError = 'Error: $e';
      });
    }
  }

  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
      _errorMsg = null;
    });

    try {
      final authProv = context.read<AuthProvider>();
      final response = await authProv.makeAuthenticatedRequest(
        Uri.parse(
            'http://exchanger-erbolsk.pythonanywhere.com/api/operations/currencies/'),
        'GET',
        context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _currencies = List<Map<String, dynamic>>.from(data);
          if (selectedCurrencyId == null && _currencies.isNotEmpty) {
            selectedCurrencyId = _currencies.first['id'] as int?;
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMsg =
              'Error loading currencies: ${response.statusCode} ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Error loading currencies: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingCurrencies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [darkBlue, blackColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned.fill(
            child: AnimatedBackground(
              behaviour: null,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 20,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.white.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth < 500
                              ? constraints.maxWidth * 0.9
                              : 500;
                          return SizedBox(
                            width: maxWidth,
                            child: _buildMainContent(context),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: GradientText(
            isBuy ? 'Покупка валюты' : 'Продажа валюты',
            key: ValueKey<bool>(isBuy),
            gradient: const LinearGradient(
              colors: [primaryBlue, primaryRed],
            ),
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchCurrencies();
              _fetchCurrentCashier();
              _fetchAllCashiers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: _buildLeftDrawer(),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Route _createReplacementRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isLoadingCurrencies) {
      return const Center(child: PulsatingLoader(color: Colors.blue));
    }
    if (_errorMsg != null && _currencies.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ошибка: $_errorMsg',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontFamily: 'RobotoMono',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchCurrencies,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Повторить загрузку валют',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (_currencies.isEmpty) {
      return const Center(
        child: Text(
          'Нет доступных валют (кроме Som) или ещё не загружено',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 16,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedToggleButton(
              isActive: isBuy,
              activeColor: primaryBlue,
              inactiveColor: primaryBlue.withOpacity(0.5),
              icon: Icons.arrow_downward,
              onPressed: () {
                if (!isBuy) {
                  setState(() {
                    isBuy = true;
                    _titleAnimationController.forward(from: 0.0);
                  });
                }
              },
              label: 'Покупка',
            ),
            const SizedBox(width: 40),
            AnimatedToggleButton(
              isActive: !isBuy,
              activeColor: primaryRed,
              inactiveColor: primaryRed.withOpacity(0.5),
              icon: Icons.arrow_upward,
              onPressed: () {
                if (isBuy) {
                  setState(() {
                    isBuy = false;
                    _titleAnimationController.forward(from: 0.0);
                  });
                }
              },
              label: 'Продажа',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _titleAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _titleAnimation.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _titleAnimation.value) * 20),
                child: child,
              ),
            );
          },
          child: GradientText(
            isBuy ? 'Покупка' : 'Продажа',
            gradient: const LinearGradient(
              colors: [primaryBlue, primaryRed],
            ),
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),
        AnimatedDropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Валюта',
            labelStyle: const TextStyle(
              color: Colors.black,
              fontFamily: 'RobotoMono',
            ),
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.blue.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
          ),
          value: selectedCurrencyId,
          items: _currencies.map((c) {
            final id = c['id'] as int;
            final name = c['name'] as String;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => selectedCurrencyId = val);
          },
        ),
        const SizedBox(height: 20),
        AnimatedInputField(
          controller: _amountCtrl,
          labelText: 'Количество',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        AnimatedInputField(
          controller: _rateCtrl,
          labelText: 'Курс',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        AnimatedInputField(
          controller: _totalCtrl,
          labelText: 'Общий (сом)',
          readOnly: true,
        ),
        const SizedBox(height: 25),
        if (_errorMsg != null && _currencies.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error,
                color: Color(0xFFB83026),
                size: 20,
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Ошибка: $_errorMsg',
                  key: ValueKey<String>(_errorMsg!),
                  style: const TextStyle(
                    color: Color(0xFFB83026),
                    fontFamily: 'RobotoMono',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        GlowingButton(
          text: 'ADD',
          color: Colors.blue,
          onPressed: _isLoadingAdd ? null : () => _onAddOperation(),
          isLoading: _isLoadingAdd,
          child: Icon(Icons.add),
        ),
        GlowingButton(
          text: 'Событие',
          color: Colors.red,
          onPressed: _isLoadingAdd ? null : () => _gotoHistory(),
          isLoading: false,
          textColor: Colors.white,
          child: Icon(Icons.event),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required Key key,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        key: key,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }

  void _updateTotal() {
    final amountStr = _amountCtrl.text;
    final rateStr = _rateCtrl.text;
    if (amountStr.isEmpty || rateStr.isEmpty) {
      _totalCtrl.text = '';
      return;
    }
    final amount = double.tryParse(amountStr) ?? 0;
    final rate = double.tryParse(rateStr) ?? 0;
    _totalCtrl.text = (amount * rate).toStringAsFixed(2);
  }

  Future<void> _onAddOperation() async {
    if (selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите валюту из списка!')),
      );
      return;
    }
    if (_amountCtrl.text.isEmpty || _rateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите количество и курс!')),
      );
      return;
    }

    setState(() => _isLoadingAdd = true);

    final token = context.read<AuthProvider>().token;
    final opType = isBuy ? 'buy' : 'sell';
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;

    try {
      final url = Uri.parse(
          'http://exchanger-erbolsk.pythonanywhere.com/api/operations/');
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        "operation_type": opType,
        "currency": selectedCurrencyId,
        "amount": amount,
        "exchange_rate": rate,
      });

      final resp = await http.post(url, headers: headers, body: body);
      if (resp.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Операция успешно создана!')),
        );
        _amountCtrl.clear();
        _rateCtrl.clear();
        _totalCtrl.clear();
        setState(() => selectedCurrencyId =
            _currencies.isNotEmpty ? _currencies.first['id'] as int? : null);
      } else if (resp.statusCode == 400) {
        final responseBody = jsonDecode(resp.body);
        if (responseBody is Map<String, dynamic> &&
            responseBody['detail'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка: ${utf8.decode(responseBody['detail'].toString().codeUnits)}',
              ),
            ),
          );
        } else if (responseBody is List) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${responseBody.join(", ")}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${resp.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неизвестная ошибка: ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingAdd = false);
    }
  }

  void _gotoHistory() {
    Navigator.push(
      context,
      _createRoute(const OperationsHistoryScreen()),
    );
  }

  Widget _buildLeftDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBlue, blackColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Главное меню',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingCashiers)
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    _buildShiftCashierCombo(),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDrawerItem(
              icon: Icons.currency_exchange,
              text: 'Valuta',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createRoute(const ValutaScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.description,
              text: 'Отчет',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createRoute(const OtchetScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.savings,
              text: 'Касса',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createRoute(const CassaScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.group,
              text: 'Пользователи',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createRoute(const UsersScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.cleaning_services,
              text: 'Очистить смену',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createRoute(const ClearShiftScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Выйти',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      backgroundColor: darkBlue,
                      title: const Text(
                        "Выход",
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      content: const Text(
                        "Вы уверены, что хотите выйти?",
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          color: Colors.white,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text(
                            "Отмена",
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AuthProvider>().logout(context);
                            Navigator.of(context).pushReplacement(
                              _createReplacementRoute(
                                  const LoginScreen()), // Updated with smooth transition
                            );
                          },
                          child: const Text(
                            "Выйти",
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: AnimatedIconWidget(icon: icon),
      title: Text(
        text,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildShiftCashierCombo() {
    if (_cashierError != null) {
      return Text(
        _cashierError!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      );
    }

    final items = _allCashiers.map((c) {
      final id = c['id'] as int;
      final username = c['username'] as String;
      return DropdownMenuItem<int>(
        value: id,
        child: Text(
          username,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList();

    final isValidValue = _allCashiers.any((c) => c['id'] == _currentCashierId);
    final currentCashierId = isValidValue ? _currentCashierId : null;

    if (items.isEmpty) {
      return const Text(
        'No cashiers found!',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Cashier:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DropdownButton<int>(
            value: currentCashierId,
            items: items,
            hint: const Text(
              'Select a cashier',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: (val) => _changeCashier(val),
            underline: const SizedBox(),
            dropdownColor: Colors.blue,
            iconEnabledColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class AnimatedToggleButton extends StatefulWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const AnimatedToggleButton({
    Key? key,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.icon,
    required this.onPressed,
    required this.label,
  }) : super(key: key);

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: widget.inactiveColor,
      end: widget.activeColor,
    ).animate(_animationController);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onPressed,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                shape: BoxShape.circle,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: _colorAnimation.value!.withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedIconWidget extends StatefulWidget {
  final IconData icon;

  const AnimatedIconWidget({Key? key, required this.icon}) : super(key: key);

  @override
  State<AnimatedIconWidget> createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 0.5).animate(_iconController);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _animateIcon() {
    if (!_iconController.isAnimating) {
      _iconController.forward().then((_) => _iconController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _animateIcon();
      },
      child: AnimatedBuilder(
        animation: _iconController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 3.1416,
            child: Icon(
              widget.icon,
              color: const Color.fromARGB(255, 10, 69, 117),
              size: 24,
            ),
          );
        },
      ),
    );
  }
}

class PulsatingLoader extends StatefulWidget {
  final Color color;

  const PulsatingLoader({Key? key, required this.color}) : super(key: key);

  @override
  _PulsatingLoaderState createState() => _PulsatingLoaderState();
}

class _PulsatingLoaderState extends State<PulsatingLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulsateController;
  late Animation<double> _pulsateAnimation;

  @override
  void initState() {
    super.initState();
    _pulsateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulsateAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulsateController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulsateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulsateAnimation,
      child: Icon(
        Icons.sync,
        color: widget.color,
        size: 30,
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText(this.text,
      {Key? key, required this.style, required this.gradient})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class AnimatedDropdownButtonFormField<T> extends StatefulWidget {
  final InputDecoration decoration;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool readOnly;

  const AnimatedDropdownButtonFormField({
    Key? key,
    required this.decoration,
    required this.value,
    required this.items,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  _AnimatedDropdownButtonFormFieldState<T> createState() =>
      _AnimatedDropdownButtonFormFieldState<T>();
}

class _AnimatedDropdownButtonFormFieldState<T>
    extends State<AnimatedDropdownButtonFormField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(_focusController);
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
      if (focused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.readOnly) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      },
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _focusAnimation.value,
            child: child,
          );
        },
        child: Focus(
          onFocusChange: _handleFocusChange,
          child: DropdownButtonFormField<T>(
            decoration: widget.decoration,
            value: widget.value,
            items: widget.items,
            onChanged: widget.readOnly ? null : widget.onChanged,
            style: widget.decoration.labelStyle?.copyWith(
                  color: Colors.black,
                ) ??
                const TextStyle(color: Colors.black),
            iconEnabledColor: const Color.fromARGB(255, 10, 69, 117),
            dropdownColor: Colors.blue.shade100,
            isExpanded: true,
          ),
        ),
      ),
    );
  }
}

class AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final bool readOnly;

  const AnimatedInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  }) : super(key: key);

  @override
  _AnimatedInputFieldState createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _shadowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderColorAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.5),
      end: Colors.blue,
    ).animate(_focusController);
    _shadowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
      if (focused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.6),
                blurRadius: _shadowAnimation.value,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Focus(
            onFocusChange: _handleFocusChange,
            child: TextFormField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'RobotoMono',
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: widget.labelText,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'RobotoMono',
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value!,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
