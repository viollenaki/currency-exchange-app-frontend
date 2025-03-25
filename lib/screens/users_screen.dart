import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:currency_exchange_app/providers/auth_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMsg;

  final List<Map<String, dynamic>> _users = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchUsers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add User',
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error: $_errorMsg',
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                textStyle: const TextStyle(fontFamily: 'RobotoMono'),
              ),
              onPressed: _fetchUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text(
          'No users available.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'RobotoMono',
            color: Colors.black87,
          ),
        ),
      );
    }

    // Display the list of users with animation
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white, // Light-colored card
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User List',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 16),
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _users.length,
              itemBuilder: (ctx, index, animation) {
                final user = _users[index];
                return _buildUserTile(user, animation);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(
    Map<String, dynamic> user,
    Animation<double> animation,
  ) {
    final userId = user['id'];
    final userName = user['username'] ?? 'N/A';
    final userEmail = user['email'] ?? 'N/A';
    final userRole = user['role'] ?? 'N/A';

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.grey.shade100,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              '$userName (${_capitalize(userRole)})',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              userEmail,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                color: Colors.grey.shade700,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditUserDialog(user),
                  tooltip: 'Edit User',
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(userId),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/users/');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        List<Map<String, dynamic>> newUsers = [];
        if (data is Map && data.containsKey('results')) {
          final results = data['results'];
          if (results is List) {
            newUsers = results
                .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
                .toList();
          } else {
            setState(() {
              _errorMsg =
                  'Invalid response format (expected list in "results").';
            });
          }
        } else if (data is List) {
          newUsers = data
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        } else {
          setState(() {
            _errorMsg = 'Invalid response format (expected list).';
          });
        }

        _updateUserList(newUsers);
        _fadeController.forward(from: 0.0);
      } else {
        setState(() {
          _errorMsg = '${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateUserList(List<Map<String, dynamic>> newList) {
    for (int i = _users.length - 1; i >= 0; i--) {
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildUserTile(_users[i], animation),
        duration: const Duration(milliseconds: 300),
      );
    }

    _users.clear();

    for (int i = 0; i < newList.length; i++) {
      _users.add(newList[i]);
      _listKey.currentState?.insertItem(
        i,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _showAddUserDialog() {
    String username = '';
    String email = '';
    String password = '';
    String role = 'cashier';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add New User',
            style: TextStyle(fontFamily: 'RobotoMono'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username Field
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Please enter a username.'
                        : null,
                    onChanged: (val) => username = val,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => email = val,
                  ),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Please enter a password.'
                        : null,
                    onChanged: (val) => password = val,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Text('Cashier'),
                      ),
                    ],
                    onChanged: (val) => role = val ?? 'cashier',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
            ElevatedButton(
              onPressed: () => _submitAddUser(
                ctx,
                formKey,
                username,
                email,
                password,
                role,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: const TextStyle(fontFamily: 'RobotoMono'),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAddUser(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    String username,
    String email,
    String password,
    String role,
  ) async {
    if (!formKey.currentState!.validate()) return;

    Navigator.of(dialogCtx).pop();
    try {
      setState(() => _isLoading = true);

      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/users/');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      });

      final resp = await http.post(url, headers: headers, body: body);
      if (resp.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        _fetchUsers();
      } else {
        setState(() {
          _errorMsg = 'Failed to add user: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final userId = user['id'];
    final formKey = GlobalKey<FormState>();

    // Initial values
    String username = user['username'] ?? '';
    String email = user['email'] ?? '';
    String role = user['role'] ?? 'cashier';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit User',
            style: TextStyle(fontFamily: 'RobotoMono'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: username,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Please enter a username.'
                        : null,
                    onChanged: (val) => username = val,
                  ),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => email = val,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Text('Cashier'),
                      ),
                    ],
                    onChanged: (val) => role = val ?? 'cashier',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
            ElevatedButton(
              onPressed: () => _submitEditUser(
                ctx,
                formKey,
                userId,
                username,
                email,
                role,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                textStyle: const TextStyle(fontFamily: 'RobotoMono'),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEditUser(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    dynamic userId,
    String username,
    String email,
    String role,
  ) async {
    if (!formKey.currentState!.validate()) return;

    Navigator.of(dialogCtx).pop(); // Close the dialog

    try {
      setState(() => _isLoading = true);

      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/users/$userId/');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        "username": username,
        "email": email,
        "role": role,
      });

      final resp = await http.patch(url, headers: headers, body: body);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
        _fetchUsers();
      } else {
        setState(() {
          _errorMsg = 'Failed to update user: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteUser(dynamic userId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete User?',
            style: TextStyle(fontFamily: 'RobotoMono'),
          ),
          content: const Text(
            'Are you sure you want to delete this user?',
            style: TextStyle(fontFamily: 'RobotoMono'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                textStyle: const TextStyle(fontFamily: 'RobotoMono'),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteUser(userId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(dynamic userId) async {
    try {
      setState(() => _isLoading = true);

      final token = context.read<AuthProvider>().token;
      final url = Uri.parse('http://192.168.212.129:8000/api/users/$userId/');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.delete(url, headers: headers);
      if (resp.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully!')),
        );
        _fetchUsers();
      } else {
        setState(() {
          _errorMsg = 'Failed to delete user: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
