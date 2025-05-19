import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_home_screen.dart';
import 'admin_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Make sure Firebase is initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role Based Auth',
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => LoginScreen(),
        '/admin_home_screen': (ctx) => AdminHomeScreen(),
        '/user_home_screen': (ctx) => UserHomeScreen(),
      },
    );
  }
}

enum AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedRole = 'user';
  final List<String> _roles = ['user', 'admin'];

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_authMode == AuthMode.login) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        await _redirectBasedOnRole(userCredential.user!.uid);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Save user role in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': _email,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _redirectBasedOnRole(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _redirectBasedOnRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final role = userDoc.get('role') as String?;
        if (role == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin_home_screen');
        } else {
          Navigator.of(context).pushReplacementNamed('/user_home_screen');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/user_home_screen');
      }
    } catch (e) {
      Navigator.of(context).pushReplacementNamed('/user_home_screen');
    }
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_authMode == AuthMode.login ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 10),
                    color: Colors.red[100],
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!.trim(),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!.trim(),
                ),

                if (_authMode == AuthMode.register) ...[
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(labelText: 'Select Role'),
                    items: _roles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role[0].toUpperCase() + role.substring(1)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value ?? 'user';
                      });
                    },
                    onSaved: (value) => _selectedRole = value ?? 'user',
                  ),
                ],

                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_authMode == AuthMode.login ? 'Login' : 'Register'),
                  ),
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text(_authMode == AuthMode.login
                      ? 'Create new account'
                      : 'Have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
