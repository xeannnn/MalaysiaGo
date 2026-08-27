import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _hidePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      String message;

      switch (error.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          message = 'Incorrect email or password.';
          break;

        case 'network-request-failed':
          message =
          'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;

        default:
          message = error.message ?? 'Login failed.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _authService.signInWithGoogle();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Google Sign-In failed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      await _authService.continueAsGuest();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Guest login failed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guest login failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController =
    TextEditingController(
      text: _emailController.text.trim(),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Forgot Password',
          ),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final String email =
                resetEmailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter your email address.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await _authService.sendPasswordResetEmail(
                    email,
                  );

                  if (!mounted) {
                    return;
                  }

                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.pop(dialogContext);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent. Please check your inbox or spam folder.',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (error) {
                  if (!mounted) {
                    return;
                  }

                  String message;

                  switch (error.code) {
                    case 'invalid-email':
                      message =
                      'Please enter a valid email address.';
                      break;

                    case 'user-not-found':
                      message =
                      'No account was found with this email.';
                      break;

                    case 'too-many-requests':
                      message =
                      'Too many requests. Please try again later.';
                      break;

                    case 'network-request-failed':
                      message =
                      'Network error. Please check your internet connection.';
                      break;

                    default:
                      message =
                          error.message ??
                              'Unable to send reset email.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to send reset email: $error',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Send',
              ),
            ),
          ],
        );
      },
    );

    resetEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool anyLoading =
        _isLoading ||
            _isGoogleLoading ||
            _isGuestLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to continue your heritage journey',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      size: 80,
                      color: Color(0xFF2E7D32),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'MalaysiaGo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Login to continue your heritage journey',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                      TextInputType.emailAddress,
                      textInputAction:
                      TextInputAction.next,
                      enabled: !anyLoading,
                      decoration:
                      const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your email.';
                        }

                        final RegExp emailPattern =
                        RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );

                        if (!emailPattern.hasMatch(
                          value.trim(),
                        )) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                      _passwordController,
                      obscureText: _hidePassword,
                      textInputAction:
                      TextInputAction.done,
                      enabled: !anyLoading,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        border:
                        const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: anyLoading
                              ? null
                              : () {
                            setState(() {
                              _hidePassword =
                              !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment:
                      Alignment.centerRight,
                      child: TextButton(
                        onPressed: anyLoading
                            ? null
                            : _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FilledButton(
                      onPressed:
                      anyLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Login',
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Row(
                      children: [
                        Expanded(
                          child: Divider(),
                        ),
                        Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text('OR'),
                        ),
                        Expanded(
                          child: Divider(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: anyLoading
                          ? null
                          : _googleLogin,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.g_mobiledata,
                        size: 28,
                      ),
                      label: Text(
                        _isGoogleLoading
                            ? 'Signing in...'
                            : 'Continue with Google',
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: anyLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                            const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register Account',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: anyLoading
                          ? null
                          : _continueAsGuest,
                      child: _isGuestLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Continue as Guest',
                      ),
                    ),
                  ],
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0F8A5F),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to Register Screen
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Don\'t have an account? Register'),
              ),
              TextButton(
                onPressed: () {
                  // Forgot password
                  _auth.sendPasswordResetEmail(_emailController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent if account exists')),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _auth.signInWithGoogle();
                    if (mounted) Navigator.pushReplacementNamed(context, '/home');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Google sign-in failed: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}