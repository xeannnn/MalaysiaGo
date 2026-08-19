import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_screen.dart';

/// Displays the currently signed-in user's account details.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isLoggingOut = false;

  String _name = '';
  String _email = '';
  String? _photoUrl;
  String _provider = 'Email';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    String name = user.displayName ?? '';
    final String email = user.email ?? '';
    final String? photoUrl = user.photoURL;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final Map<String, dynamic>? data = snapshot.data();

        final String firestoreName =
            (data?['name'] as String?)?.trim() ?? '';

        if (firestoreName.isNotEmpty) {
          name = firestoreName;
        }
      }
    } catch (error) {
      debugPrint('Failed to load Firestore profile: $error');
    }

    String provider = 'Email';

    if (user.providerData.any(
          (info) => info.providerId == 'google.com',
    )) {
      provider = 'Google';
    }

    if (mounted) {
      setState(() {
        _name = name.isEmpty ? 'MalaysiaGo User' : name;
        _email = email;
        _photoUrl = photoUrl;
        _provider = provider;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to log out: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar() {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(_photoUrl!),
      );
    }

    return const CircleAvatar(
      radius: 48,
      backgroundColor: Color(0xFFE9F9EF),
      child: Icon(
        Icons.person,
        size: 52,
        color: Color(0xFF1F8A5C),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1F8A5C),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 16),
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _email,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 28),

              _buildInfoCard(
                icon: Icons.person_outline,
                title: 'Name',
                value: _name,
              ),

              const SizedBox(height: 12),

              _buildInfoCard(
                icon: Icons.email_outlined,
                title: 'Email',
                value: _email,
              ),

              const SizedBox(height: 12),

              _buildInfoCard(
                icon: Icons.login,
                title: 'Sign-in Method',
                value: _provider,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoggingOut ? null : _logout,
                  icon: _isLoggingOut
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.logout),
                  label: Text(
                    _isLoggingOut ? 'Logging out...' : 'Logout',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}