import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/presentation/view/login.dart';
import 'package:flutter_xploverse/feature2/presentation/viewmodel/authentication.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
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
          actions: [], // REMOVED THE OK BUTTON
        );
      },
    );
  }

  void _signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String res = await _auth.signUpUser(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      usertype: '',
    );

    setState(() {
      _isLoading = false;
    });

    if (res == "success") {
      _showErrorDialog('Signup Successful', 'Your account has been created.');
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      _showErrorDialog('Signup Failed', res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE), // Light Blue Background
      body: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(_animation),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0), // Increased padding
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29ABE2), // Sky Blue Color
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                        ),
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
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signUpUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              const Color(0xFFF2D794), // Sand Beige Color
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
                            : const Text('Sign Up'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?",
                              style: TextStyle(color: Colors.black54)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF29ABE2),
                            ),
                            child: const Text('Login'),
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
