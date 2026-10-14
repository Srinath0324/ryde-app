import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/bottom_navbar.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  // For password reset
  final TextEditingController _resetEmailController = TextEditingController();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _genderController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
        _aadhaarController.text = user.aadhaarNumber ?? '';
        _genderController.text = user.gender ?? '';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser != null) {
        final updatedUser = UserModel(
          id: currentUser.id,
          name: _nameController.text,
          email: currentUser.email, // Email cannot be changed
          phoneNumber: _phoneController.text,
          aadhaarNumber: _aadhaarController.text,
          gender: _genderController.text,
          profileImageUrl: currentUser.profileImageUrl,
          isVerified: currentUser.isVerified,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(),
        );

        await _authService.updateUserProfile(updatedUser);
        await authProvider.reloadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _resetEmailController.text = user.email;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_reset, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Reset Password'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('We will send a password reset link to:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.email),
                  ),
                  readOnly: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendPasswordResetEmail();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendPasswordResetEmail(
        _resetEmailController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send reset link: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign out: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : CustomScrollView(
                slivers: [
                  // App Bar with profile banner
                  SliverAppBar(
                    expandedHeight: 275,
                    backgroundColor: theme.primaryColor,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Profile image
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(46),
                                    child: Icon(
                                      Icons.person,
                                      size: 75,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // User name
                              Text(
                                _nameController.text,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              // Verification badge
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Account',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit/Save/Cancel buttons
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isEditing && !_isSaving)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text(
                                        'Cancel',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _loadUserData(); // Reset fields to original values
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_isEditing && !_isSaving)
                                    const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      _isEditing ? Icons.save : Icons.edit,
                                      size: 16,
                                      color:
                                          _isEditing
                                              ? Colors.white
                                              : theme.primaryColor,
                                    ),
                                    label: Text(
                                      _isEditing ? 'Save ' : 'Edit Profile',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed:
                                        _isSaving
                                            ? null
                                            : (_isEditing
                                                ? _saveUserData
                                                : () => setState(
                                                  () => _isEditing = true,
                                                )),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _isEditing
                                              ? Colors.green
                                              : Colors.white,
                                      foregroundColor:
                                          _isEditing
                                              ? Colors.white
                                              : theme.primaryColor,
                                      elevation: 2,
                                      minimumSize: const Size(100, 36),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // No actions in the app bar
                    actions: [],
                  ),

                  // Profile content
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Profile details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('Personal Information'),
                                  const SizedBox(height: 16),
                                  _buildProfileItem(
                                    Icons.person,
                                    'Full Name',
                                    _nameController,
                                    _isEditing,
                                  ),
                                  const Divider(height: 32),
                                  _buildProfileItem(
                                    Icons.email,
                                    'Email Address',
                                    _emailController,
                                    false,
                                  ),
                                  _buildVerificationBadge(),
                                  const Divider(height: 32),
                                  _buildProfileItem(
                                    Icons.phone,
                                    'Phone Number',
                                    _phoneController,
                                    _isEditing,
                                  ),
                                  const Divider(height: 32),
                                  _buildProfileItem(
                                    Icons.badge,
                                    'Aadhaar Number',
                                    _aadhaarController,
                                    _isEditing,
                                  ),
                                  const Divider(height: 32),
                                  _buildProfileItem(
                                    Icons.person_outline,
                                    'Gender',
                                    _genderController,
                                    _isEditing,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Account actions
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('Account Settings'),
                                  const SizedBox(height: 16),
                                  _buildSettingsItem(
                                    Icons.lock_reset,
                                    'Reset Password',
                                    'Change your account password',
                                    _showResetPasswordDialog,
                                  ),
                                  const Divider(height: 16),
                                  _buildSettingsItem(
                                    Icons.help_outline,
                                    'Help & Support',
                                    'Get help with your account',
                                    () {
                                      // Navigate to help screen
                                    },
                                  ),
                                  const Divider(height: 16),
                                  _buildSettingsItem(
                                    Icons.privacy_tip_outlined,
                                    'Privacy Policy',
                                    'View our privacy policy',
                                    () {
                                      // Navigate to privacy policy
                                    },
                                  ),
                                  const Divider(height: 16),
                                  _buildSettingsItem(
                                    Icons.logout,
                                    'Sign Out',
                                    'Log out from your account',
                                    _signOut,
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String label,
    TextEditingController controller,
    bool editable,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              editable
                  ? TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.edit, size: 18),
                    ),
                  )
                  : Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 56),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Verified Email',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDestructive
                        ? Colors.red[50]
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isDestructive ? Colors.red : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
