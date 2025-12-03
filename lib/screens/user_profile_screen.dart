import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  CefrLevel? _selectedLevel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _selectedLevel = user.cefrLevel;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final updatedProfile = await apiService.updateUserProfile(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        cefrLevel: _selectedLevel,
      );

      // Update the user in auth service
      authService.updateUser(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: Text('No user data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          (user.fullName?.isNotEmpty == true ? user.fullName![0] : user.username[0]).toUpperCase(),
                          style: const TextStyle(fontSize: 36, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Read-only fields
                    _buildInfoCard('Email', user.email, Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildInfoCard('Username', user.username, Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Member Since',
                      '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                      Icons.calendar_today_outlined,
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Editable Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        // Full name is optional, so no validation needed
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // CEFR Level Dropdown
                    DropdownButtonFormField<CefrLevel>(
                      value: _selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'CEFR Level',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: CefrLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedLevel = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your CEFR level';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Level Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About CEFR Levels',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getLevelDescription(_selectedLevel ?? user.cefrLevel),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelDescription(CefrLevel level) {
    switch (level) {
      case CefrLevel.A1:
        return 'Beginner: Can understand and use familiar everyday expressions and basic phrases.';
      case CefrLevel.A2:
        return 'Elementary: Can communicate in simple and routine tasks requiring basic information exchange.';
      case CefrLevel.B1:
        return 'Intermediate: Can deal with most situations while traveling and describe experiences and events.';
      case CefrLevel.B2:
        return 'Upper Intermediate: Can interact with fluency and spontaneity, and understand complex texts.';
      case CefrLevel.C1:
        return 'Advanced: Can express ideas fluently and use language flexibly for social, academic, and professional purposes.';
      case CefrLevel.C2:
        return 'Proficient: Can understand virtually everything and express themselves with precision and subtlety.';
    }
  }
}
