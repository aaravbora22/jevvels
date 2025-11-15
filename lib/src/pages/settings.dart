import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_event.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_state.dart'
    as bloc_auth;
import 'package:jevvels/authentication/presentation/pages/login_page.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
import 'package:jevvels/src/components/dashboard/nav_item.dart';
import 'package:jevvels/src/pages/dashboard.dart';
import 'package:jevvels/new_entry/new_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings extends StatefulWidget {
  const Settings({
    super.key,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String userEmail = '';
  String userName = '';
  String profileImageUrl = '';
  final TextEditingController _usernameController = TextEditingController();

  // NEW:
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _biometricEnabled = false;

  bool _deleting = false; 

  // Collaborators feature temporarily disabled.
  List<Map<String, String>> collaborators = [];

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF272424),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Delete Account?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Main Font',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will permanently delete your Jevvels account and all portfolio entries linked to it. This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Main Font',
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete permanently',
                    style: TextStyle(
                      fontFamily: 'Main Font',
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFB99750),
                      fontFamily: 'Main Font',
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleting) return;

    setState(() {
      _deleting = true;
    });

    try {
      final functions = Supabase.instance.client.functions;

      // Call Edge Function instead of direct RPC
      final response = await functions.invoke('delete-account');

      // Optional: you can inspect response.data here

      // Clear PowerSync local DB
      await db.disconnectAndClear();

      // Make sure the client is signed out
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    userEmail = user?.email ?? '';
    if (user != null &&
        user.userMetadata != null &&
        user.userMetadata!['username'] != null) {
      userName = user.userMetadata!['username'] as String;
    } else {
      userName = '';
    }
    _usernameController.text = userName;

    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final saved = await _secureStorage.read(key: 'biometric_enabled');
    setState(() {
      _biometricEnabled = saved == 'true';
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    // If turning OFF: just disable and save.
    if (!value) {
      setState(() {
        _biometricEnabled = false;
      });
      await _secureStorage.write(key: 'biometric_enabled', value: 'false');
      return;
    }

    // If turning ON: check device support first.
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Biometric authentication not available on this device.'),
        ),
      );
      // Make sure switch goes back to OFF
      setState(() {
        _biometricEnabled = false;
      });
      return;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Enable Face ID to quickly unlock Jevvels.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        setState(() {
          _biometricEnabled = true;
        });
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');
      } else {
        setState(() {
          _biometricEnabled = false;
        });
      }
    } catch (e) {
      setState(() {
        _biometricEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enable biometrics: $e')),
      );
    }
  }

  void _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'username': newUsername,
            'display_name': newUsername,
          },
        ),
      );
      if (response.user != null) {
        setState(() {
          userName = newUsername;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update username.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: $e')),
      );
    }
  }

  // logout button pressed (uses AuthBloc if available, else fallback to Supabase)
  Future<void> logout() async {
    try {
      final bloc = BlocProvider.of<AuthBloc>(context, listen: false);
      bloc.add(AuthSignOutRequested());
    } catch (e) {
      // fallback: direct supabase logout if bloc not available
      Supabase.instance.client.auth.signOut();
      await db.disconnectAndClear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // void _changeRole(int index, String newRole) {
  //   setState(() {
  //     collaborators[index]['role'] = newRole;
  //   });
  // }

  // void _addCollaborator() {
  //   // Collaborator UI and logic temporarily disabled.
  //   // Re-enable by restoring the original implementation.
  // }

  // void _removeCollaborator(int index) {
  //   setState(() {
  //     collaborators.removeAt(index);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, bloc_auth.AuthState>(
      listener: (context, state) {
        if (state is bloc_auth.AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
        if (state is bloc_auth.AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          color: const Color.fromARGB(255, 39, 36, 36),
          elevation: 0,
          child: SizedBox(
            height: 55, // Set the actual height of the nav bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => Dashboard()),
                    );
                  },
                ),
                NavItem(
                  icon: Icons.add_outlined,
                  label: 'Add Entry',
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const JewelryFormPage()));
                  },
                ),
                NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 39, 36, 36),
          elevation: 0,
          title: const Text(
            'Settings',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Main Font',
                fontSize: 30),
          ),
          actions: const [
            // Light/Dark mode toggle (UI only)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.brightness_6, color: Color(0xFFB99750)),
            ),
          ],
          iconTheme: const IconThemeData(color: Color(0xFFB99750)),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 36, 36),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFB99750),
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(userName.isNotEmpty ? userName : 'No username',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(userEmail,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Main Font',
                            fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Username section
              const Text('Username',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 18)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Main Font'),
                      decoration: const InputDecoration(
                        hintText: 'Enter username',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB99750)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFB99750), width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Color(0xFF2C2B2B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Color(0xFFB99750)),
                    onPressed: _saveUsername,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Portfolio section
              const Text('Your Portfolio',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 24)),
              Card(
                color: const Color(0xFF2C2B2B),
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Portfolio Name',
                              style: TextStyle(
                                  color: Color(0xFFB99750),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Main Font',
                                  fontSize: 20)),
                          const SizedBox(width: 12),
                        
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Owner: ${userName.isNotEmpty ? userName : 'No username'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Main Font',
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
              // Collaborators section temporarily disabled.
              /*
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Collaborators',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Main Font',
                          fontSize: 24)),
                  ElevatedButton.icon(
                    onPressed: _addCollaborator,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Add',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Main Font')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB99750),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFF2C2B2B),
                child: Column(
                  children: [
                    for (int i = 0; i < collaborators.length; i++)
                      // Original collaborator list items commented out.
                  ],
                ),
              ),
              const SizedBox(height: 32),
              */
              // Security section
              const Text('Security',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 24)),
              Card(
                color: const Color(0xFF2C2B2B),
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ListTile(
                  leading: const Icon(Icons.security, color: Color(0xFFB99750)),
                  title: const Text('Biometric Authentication',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Main Font',
                          fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Enable Biometric authentication, recommended for security',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Main Font',
                          fontSize: 12)),
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (val) {
                      _toggleBiometric(
                          val); // <- THIS triggers Face ID sheet when enabling
                    },
                    activeColor: const Color(0xFFB99750),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // Logout button
              Center(
                child: BlocBuilder<AuthBloc, bloc_auth.AuthState>(
                  builder: (context, state) {
                    return ElevatedButton.icon(
                      onPressed: state is bloc_auth.AuthLoading ? null : logout,
                      icon: const Icon(Icons.logout),
                      label: state is bloc_auth.AuthLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton.icon(
                    onPressed: _deleting ? null : _confirmDeleteAccount,
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    label: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const Text(
                            'Delete account',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'Main Font',
                              fontWeight: FontWeight.w600,
                            ),
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
