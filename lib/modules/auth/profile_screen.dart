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

  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isSaving = false;
  bool _isEditing = false;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _state = '';
  String? _photoUrl;

  List<String> _selectedInterests = [];

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final List<String> _states = [
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

  final List<String> _interestOptions = [
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

  // ============================================================
  // LOAD PROFILE
  // ============================================================

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
    String phone = '';
    String state = '';
    List<String> interests = [];

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

        phone =
            (data?['phone'] as String?)?.trim() ?? '';

        state =
            (data?['state'] as String?)?.trim() ?? '';

        final dynamic storedInterests =
        data?['interests'];

        if (storedInterests is List) {
          interests = storedInterests
              .map((item) => item.toString())
              .toList();
        }
      }
    } catch (error) {
      debugPrint(
        'Failed to load Firestore profile: $error',
      );
    }

    if (mounted) {
      setState(() {
        _name =
        name.isEmpty ? 'MalaysiaGo User' : name;

        _email = email;
        _photoUrl = photoUrl;
        _phone = phone;
        _state = state;
        _selectedInterests = interests;

        _nameController.text = _name;
        _phoneController.text = _phone;

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final String newName =
    _nameController.text.trim();

    final String newPhone =
    _phoneController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your name.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await user.updateDisplayName(newName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': newName,
          'phone': newPhone,
          'state': _state,
          'interests': _selectedInterests,
          'updatedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _name = newName;
        _phone = newPhone;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
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
            'Unable to update profile: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    final bool? changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(
        authService: _authService,
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> _showDeleteAccountDialog() async {
    final bool isPasswordUser =
    _authService.isPasswordUser();

    final bool isGoogleUser =
    _authService.isGoogleUser();

    final TextEditingController passwordController =
    TextEditingController();

    bool isDeleting = false;
    bool hidePassword = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter setDialogState,
              ) {
            Future<void> confirmDelete() async {
              if (isPasswordUser &&
                  passwordController.text
                      .trim()
                      .isEmpty) {
                ScaffoldMessenger.of(this.context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter your current password.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isDeleting = true;
              });

              try {
                await _authService.deleteAccount(
                  password: isPasswordUser
                      ? passwordController.text.trim()
                      : null,
                );

                if (!mounted) {
                  return;
                }

                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                    const LoginScreen(),
                  ),
                      (route) => false,
                );
              } on FirebaseAuthException catch (error) {
                if (!mounted) {
                  return;
                }

                String message;

                switch (error.code) {
                  case 'wrong-password':
                  case 'invalid-credential':
                    message =
                    'Your current password is incorrect.';
                    break;

                  case 'requires-recent-login':
                    message =
                    'Please sign in again before deleting your account.';
                    break;

                  case 'network-request-failed':
                    message =
                    'Network error. Please check your connection.';
                    break;

                  default:
                    message =
                        error.message ??
                            'Unable to delete account.';
                }

                ScaffoldMessenger.of(this.context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(message),
                  ),
                );

                if (dialogContext.mounted) {
                  setDialogState(() {
                    isDeleting = false;
                  });
                }
              } catch (error) {
                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to delete account: $error',
                    ),
                  ),
                );

                if (dialogContext.mounted) {
                  setDialogState(() {
                    isDeleting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Delete Account',
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action is permanent.',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your MalaysiaGo account and profile information will be permanently deleted.',
                    ),

                    if (isPasswordUser) ...[
                      const SizedBox(height: 18),

                      TextField(
                        controller:
                        passwordController,
                        obscureText:
                        hidePassword,
                        decoration:
                        InputDecoration(
                          labelText:
                          'Current Password',
                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setDialogState(
                                    () {
                                  hidePassword =
                                  !hidePassword;
                                },
                              );
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons
                                  .visibility_off
                                  : Icons
                                  .visibility,
                            ),
                          ),
                          border:
                          const OutlineInputBorder(),
                        ),
                      ),
                    ],

                    if (!isPasswordUser &&
                        isGoogleUser) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'You will be asked to confirm your Google account before deletion.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                FilledButton.icon(
                  onPressed: isDeleting
                      ? null
                      : confirmDelete,
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    Colors.red,
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.delete_forever,
                  ),
                  label: Text(
                    isDeleting
                        ? 'Deleting...'
                        : 'Delete Account',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
          const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to log out: $error',
          ),
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

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildProfileAvatar() {
    if (_photoUrl != null &&
        _photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage:
        NetworkImage(_photoUrl!),
      );
    }

    final String initial =
    _name.isNotEmpty
        ? _name
        .substring(0, 1)
        .toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 48,
      backgroundColor:
      const Color(0xFF1F8A5C),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 42,
          color: Colors.white,
          fontWeight:
          FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
            const Color(0xFF1F8A5C),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY OPTION
  // ============================================================

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final Color color = destructive
        ? Colors.red
        : const Color(0xFF1F8A5C);

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  color.withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                        color: destructive
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: destructive
                    ? Colors.red
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration:
          const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(
              Icons.person_outline,
            ),
            border:
            OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _phoneController,
          keyboardType:
          TextInputType.phone,
          decoration:
          const InputDecoration(
            labelText:
            'Phone Number',
            prefixIcon: Icon(
              Icons.phone_outlined,
            ),
            border:
            OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          value:
          _state.isEmpty ? null : _state,
          decoration:
          const InputDecoration(
            labelText:
            'Home State',
            prefixIcon: Icon(
              Icons
                  .location_on_outlined,
            ),
            border:
            OutlineInputBorder(),
          ),
          items: _states
              .map(
                (String state) =>
                DropdownMenuItem<
                    String>(
                  value: state,
                  child: Text(state),
                ),
          )
              .toList(),
          onChanged: (String? value) {
            setState(() {
              _state = value ?? '';
            });
          },
        ),

        const SizedBox(height: 20),

        const Text(
          'Travel Interests',
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
          _interestOptions.map(
                (String interest) {
              final bool selected =
              _selectedInterests
                  .contains(interest);

              return FilterChip(
                label:
                Text(interest),
                selected: selected,
                onSelected:
                    (bool value) {
                  setState(() {
                    if (value) {
                      if (!_selectedInterests
                          .contains(
                        interest,
                      )) {
                        _selectedInterests
                            .add(
                          interest,
                        );
                      }
                    } else {
                      _selectedInterests
                          .remove(
                        interest,
                      );
                    }
                  });
                },
              );
            },
          ).toList(),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                _isSaving
                    ? null
                    : () {
                  _nameController
                      .text =
                      _name;

                  _phoneController
                      .text =
                      _phone;

                  setState(() {
                    _isEditing =
                    false;
                  });
                },
                child:
                const Text(
                  'Cancel',
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: FilledButton(
                onPressed:
                _isSaving
                    ? null
                    : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Save Profile',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F5F7),
      appBar: AppBar(
        title:
        const Text('My Account'),
        centerTitle: true,
        actions: [
          if (!_isLoading &&
              !_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon:
              const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            20,
          ),
          child: Column(
            children: [
              _buildProfileAvatar(),

              const SizedBox(
                height: 16,
              ),

              Text(
                _name,
                style:
                const TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                _email,
                style:
                const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              if (_isEditing)
                _buildEditSection()
              else ...[
                SizedBox(
                  width:
                  double.infinity,
                  child:
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing =
                        true;
                      });
                    },
                    icon:
                    const Icon(
                      Icons.edit,
                    ),
                    label:
                    const Text(
                      'Edit Profile',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                _buildInfoCard(
                  icon: Icons
                      .person_outline,
                  title: 'Name',
                  value: _name,
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildInfoCard(
                  icon: Icons
                      .email_outlined,
                  title: 'Email',
                  value: _email,
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildInfoCard(
                  icon: Icons
                      .phone_outlined,
                  title:
                  'Phone Number',
                  value: _phone,
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildInfoCard(
                  icon: Icons
                      .location_on_outlined,
                  title:
                  'Home State',
                  value: _state,
                ),

                const SizedBox(
                  height: 12,
                ),

                _buildInfoCard(
                  icon: Icons
                      .favorite_outline,
                  title:
                  'Travel Interests',
                  value:
                  _selectedInterests
                      .isEmpty
                      ? '-'
                      : _selectedInterests
                      .join(', '),
                ),

                const SizedBox(
                  height: 28,
                ),

                const Align(
                  alignment:
                  Alignment.centerLeft,
                  child: Text(
                    'Account Security',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (_authService
                    .isPasswordUser())
                  _buildSecurityOption(
                    icon: Icons
                        .lock_outline,
                    title:
                    'Change Password',
                    subtitle:
                    'Update your account password',
                    onTap:
                    _showChangePasswordDialog,
                  ),

                if (_authService
                    .isPasswordUser())
                  const SizedBox(
                    height: 12,
                  ),

                _buildSecurityOption(
                  icon: Icons
                      .delete_outline,
                  title:
                  'Delete Account',
                  subtitle:
                  'Permanently delete your MalaysiaGo account',
                  destructive: true,
                  onTap:
                  _showDeleteAccountDialog,
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  child:
                  FilledButton.icon(
                    onPressed:
                    _isLoggingOut
                        ? null
                        : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    )
                        : const Icon(
                      Icons.logout,
                    ),
                    label: Text(
                      _isLoggingOut
                          ? 'Logging out...'
                          : 'Logout',
                    ),
                    style:
                    FilledButton
                        .styleFrom(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class ChangePasswordDialog extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordDialog({
    super.key,
    required this.authService,
  });

  @override
  State<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends State<ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
  TextEditingController();

  final TextEditingController _newPasswordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _isChanging = false;

  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _changePassword() async {
    final String currentPassword =
        _currentPasswordController.text;

    final String newPassword =
        _newPasswordController.text;

    final String confirmPassword =
        _confirmPasswordController.text;

    setState(() {
      _errorMessage = null;
    });

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage =
        'Please complete all password fields.';
      });
      return;
    }

    if (newPassword.length < 8) {
      setState(() {
        _errorMessage =
        'New password must contain at least 8 characters.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage =
        'New passwords do not match.';
      });
      return;
    }

    if (currentPassword == newPassword) {
      setState(() {
        _errorMessage =
        'New password must be different from your current password.';
      });
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      await widget.authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      String message;

      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message =
          'Your current password is incorrect.';
          break;

        case 'weak-password':
          message =
          'Your new password is too weak.';
          break;

        case 'requires-recent-login':
          message =
          'Please log in again before changing your password.';
          break;

        case 'network-request-failed':
          message =
          'Network error. Please check your internet connection.';
          break;

        default:
          message =
              error.message ??
                  'Unable to change password.';
      }

      setState(() {
        _errorMessage = message;
        _isChanging = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Unable to change password: $error';

        _isChanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Change Password',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller:
              _currentPasswordController,
              obscureText: _hideCurrent,
              enabled: !_isChanging,
              decoration: InputDecoration(
                labelText:
                'Current Password',
                prefixIcon: const Icon(
                  Icons.lock_outline,
                ),
                suffixIcon: IconButton(
                  onPressed: _isChanging
                      ? null
                      : () {
                    setState(() {
                      _hideCurrent =
                      !_hideCurrent;
                    });
                  },
                  icon: Icon(
                    _hideCurrent
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
                border:
                const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
              _newPasswordController,
              obscureText: _hideNew,
              enabled: !_isChanging,
              decoration: InputDecoration(
                labelText:
                'New Password',
                prefixIcon: const Icon(
                  Icons.password_outlined,
                ),
                suffixIcon: IconButton(
                  onPressed: _isChanging
                      ? null
                      : () {
                    setState(() {
                      _hideNew =
                      !_hideNew;
                    });
                  },
                  icon: Icon(
                    _hideNew
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
                border:
                const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
              _confirmPasswordController,
              obscureText: _hideConfirm,
              enabled: !_isChanging,
              onSubmitted: (_) {
                if (!_isChanging) {
                  _changePassword();
                }
              },
              decoration: InputDecoration(
                labelText:
                'Confirm New Password',
                prefixIcon: const Icon(
                  Icons
                      .verified_user_outlined,
                ),
                suffixIcon: IconButton(
                  onPressed: _isChanging
                      ? null
                      : () {
                    setState(() {
                      _hideConfirm =
                      !_hideConfirm;
                    });
                  },
                  icon: Icon(
                    _hideConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
                border:
                const OutlineInputBorder(),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                  Colors.red.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color:
                    Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: _isChanging
              ? null
              : () {
            Navigator.of(context)
                .pop(false);
          },
          child: const Text(
            'Cancel',
          ),
        ),

        FilledButton(
          onPressed:
          _isChanging
              ? null
              : _changePassword,
          child: _isChanging
              ? const SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Change Password',
          ),
        ),
      ],
    );
  }
}