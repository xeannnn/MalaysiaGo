import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  bool _isEditing = false;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _state = '';
  String? _photoUrl;
  List<String> _selectedInterests = <String>[];

  static const List<String> _states = <String>[
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  static const List<String> _interestOptions = <String>[
    'Heritage',
    'Food',
    'Nature',
    'Culture',
    'History',
    'Architecture',
    'Photography',
    'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    String name = user.displayName?.trim() ?? '';
    String phone = '';
    String state = '';
    String? photoUrl = user.photoURL;
    List<String> interests = <String>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();
      if (data != null) {
        final String firestoreName = (data['name'] as String?)?.trim() ?? '';
        if (firestoreName.isNotEmpty) name = firestoreName;

        phone = (data['phone'] as String?)?.trim() ?? '';
        state = (data['state'] as String?)?.trim() ?? '';

        final String firestorePhoto = (data['photoUrl'] as String?)?.trim() ?? '';
        if (firestorePhoto.isNotEmpty) photoUrl = firestorePhoto;

        final dynamic storedInterests = data['interests'];
        if (storedInterests is List) {
          interests = storedInterests.map((item) => item.toString()).toList();
        }
      }
    } catch (error) {
      debugPrint('Failed to load Firestore profile: $error');
    }

    if (!mounted) return;

    setState(() {
      _name = name.isEmpty ? 'MalaysiaGo User' : name;
      _email = user.email ?? (user.isAnonymous ? 'Guest account' : '');
      _phone = phone;
      _state = state;
      _photoUrl = photoUrl;
      _selectedInterests = interests;
      _nameController.text = _name;
      _phoneController.text = _phone;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final String newName = _nameController.text.trim();
    final String newPhone = _phoneController.text.trim();

    if (newName.length < 2) {
      _showMessage('Please enter a valid name.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await user.updateDisplayName(newName);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'uid': user.uid,
          'name': newName,
          'email': user.email?.toLowerCase() ?? '',
          'photoUrl': _photoUrl,
          'phone': newPhone,
          'state': _state,
          'interests': _selectedInterests,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _name = newName;
        _phone = newPhone;
        _isEditing = false;
      });
      _showMessage('Profile updated successfully.');
    } catch (error) {
      if (mounted) _showMessage('Unable to update profile: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showMessage('Unable to log out: $error');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _openChangePassword() async {
    final bool? changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(authService: _authService),
    );
    if (changed == true && mounted) {
      _showMessage('Password changed successfully.');
    }
  }

  Future<void> _openDeleteAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bool? deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(
        authService: _authService,
        needsPassword: _authService.userUsesPasswordProvider(),
      ),
    );

    if (deleted == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  int get _profileCompletion {
    int completed = 0;
    const int total = 5;
    if (_name.trim().isNotEmpty && _name != 'MalaysiaGo User') completed++;
    if (_phone.trim().isNotEmpty) completed++;
    if (_state.trim().isNotEmpty) completed++;
    if (_selectedInterests.isNotEmpty) completed++;
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) completed++;
    return ((completed / total) * 100).round();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _avatar() {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(_photoUrl!),
      );
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFF1F8A5C),
      child: Text(
        _name.isNotEmpty ? _name.substring(0, 1).toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF1F8A5C)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _state.isEmpty ? null : _state,
          decoration: const InputDecoration(
            labelText: 'Home State',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          items: _states
              .map((state) => DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _state = value ?? ''),
        ),
        const SizedBox(height: 20),
        const Text('Travel Interests', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((interest) {
            final bool selected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _nameController.text = _name;
                          _phoneController.text = _phone;
                          _isEditing = false;
                        });
                      },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        actions: <Widget>[
          if (!isGuest && !_isEditing)
            IconButton(
              tooltip: 'Edit Profile',
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Center(child: _avatar()),
                  if (!isGuest && _photoUrl != null && _photoUrl!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    const Text(
                      'Profile photo synced from your sign-in account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (!isGuest) ...<Widget>[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Profile Completion',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '$_profileCompletion%',
                                style: const TextStyle(
                                  color: Color(0xFF1F8A5C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: _profileCompletion / 100,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          if (_profileCompletion < 100) ...<Widget>[
                            const SizedBox(height: 8),
                            const Text(
                              'Add your phone, state, interests and profile photo to complete your profile.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_isEditing)
                    _editForm()
                  else ...<Widget>[
                    _infoTile(Icons.person_outline, 'Name', _name),
                    const SizedBox(height: 12),
                    _infoTile(Icons.email_outlined, 'Email', _email),
                    const SizedBox(height: 12),
                    _infoTile(Icons.phone_outlined, 'Phone Number', _phone),
                    const SizedBox(height: 12),
                    _infoTile(Icons.location_on_outlined, 'Home State', _state),
                    const SizedBox(height: 12),
                    _infoTile(
                      Icons.interests_outlined,
                      'Travel Interests',
                      _selectedInterests.isEmpty ? '-' : _selectedInterests.join(', '),
                    ),
                    if (!isGuest && _authService.userUsesPasswordProvider()) ...<Widget>[
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: _openChangePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                    if (!isGuest) ...<Widget>[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openDeleteAccount,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.authService});
  final AuthService authService;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _current.text;
    final next = _newPassword.text;
    final confirm = _confirm.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please complete all password fields.');
      return;
    }
    if (next.length < 8) {
      setState(() => _error = 'New password must contain at least 8 characters.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (current == next) {
      setState(() => _error = 'New password must be different.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authService.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      String message;
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Your current password is incorrect.';
          break;
        case 'weak-password':
          message = 'Your new password is too weak.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
        default:
          message = error.message ?? 'Unable to change password.';
      }
      if (mounted) setState(() => _error = message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to change password: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _passwordField(_current, 'Current Password', _hideCurrent,
                () => setState(() => _hideCurrent = !_hideCurrent)),
            const SizedBox(height: 12),
            _passwordField(_newPassword, 'New Password', _hideNew,
                () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 12),
            _passwordField(_confirm, 'Confirm New Password', _hideConfirm,
                () => setState(() => _hideConfirm = !_hideConfirm)),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change'),
        ),
      ],
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool hidden,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.authService,
    required this.needsPassword,
  });

  final AuthService authService;
  final bool needsPassword;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (widget.needsPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password to confirm.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authService.deleteAccount(
        currentPassword: widget.needsPassword ? _password.text : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      String message;
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Your current password is incorrect.';
          break;
        case 'requires-recent-login':
          message = 'Please log in again, then try deleting your account.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
        default:
          message = error.message ?? 'Unable to delete account.';
      }
      if (mounted) setState(() => _error = message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to delete account: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'This permanently deletes your MalaysiaGo account and cannot be undone.',
          ),
          if (widget.needsPassword) ...<Widget>[
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 12),
            const Text('You may be asked to confirm your Google account.'),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
