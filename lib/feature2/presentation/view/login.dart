import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/buttomnavigation.dart';
import 'package:flutter_xploverse/feature2/presentation/view/password_forget.dart';
import 'package:flutter_xploverse/feature2/presentation/view/signup.dart';
import 'package:flutter_xploverse/feature2/presentation/viewmodel/authentication.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthServices _auth = AuthServices();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message,
      {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF29ABE2),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black87),
          ),
          actions: isSuccess
              ? [] // No button for success
              : [
                  TextButton(
                    // The OK button for errors
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF29ABE2),
                    ),
                    child: const Text('OK'),
                  ),
                ],
        );
      },
    );
  }

  void _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String res = await _auth.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (res == "success") {
        _showErrorDialog('Login Successful', 'You have successfully logged in.',
            isSuccess: true); // Indicate success
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationPage()),
            (route) => false,
          );
        });
      } else if (res.contains("user-not-found")) {
        _showErrorDialog(
          'Account Not Found',
          'No account exists with this email address. Please check your email or create a new account.',
        );
      } else if (res.contains("wrong-password")) {
        _showErrorDialog(
          'Incorrect Password',
          'The password you entered is incorrect. Please try again or use the "Forgot Password" option.',
        );
      } else {
        _showErrorDialog(
          'Login Error',
          'An error occurred while trying to log in. Please try again.',
        );
      }
    } catch (e) {
      _showErrorDialog(
        'Connection Error',
        'Unable to connect to the server. Please check your internet connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(_animation),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome To Travel',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29ABE2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF29ABE2)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF29ABE2)),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF29ABE2),
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _loginUser();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFF2D794),
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?",
                              style: TextStyle(color: Colors.black54)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF29ABE2),
                            ),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
