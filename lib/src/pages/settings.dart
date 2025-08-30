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

  List<Map<String, String>> collaborators = [
    {'email': 'editor@email.com', 'role': 'Editor'},
    {'email': 'viewer@email.com', 'role': 'Viewer'},
  ];

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

  void _changeRole(int index, String newRole) {
    setState(() {
      collaborators[index]['role'] = newRole;
    });
  }

  void _addCollaborator() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _emailController = TextEditingController();
        String selectedRole = 'Viewer';
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2B2B),
          title: const Text('Add Collaborator',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Main Font',
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Main Font'),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFFB99750)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB99750)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB99750), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFF2C2B2B),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedRole,
                dropdownColor: const Color(0xFF2C2B2B),
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Main Font'),
                items: const [
                  DropdownMenuItem(value: 'Editor', child: Text('Editor')),
                  DropdownMenuItem(value: 'Viewer', child: Text('Viewer')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB99750)),
              onPressed: () {
                setState(() {
                  collaborators.add({
                    'email': _emailController.text,
                    'role': selectedRole,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _removeCollaborator(int index) {
    setState(() {
      collaborators.removeAt(index);
    });
  }

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
                  onTap: () {
                    
                  },
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
                          ...collaborators.map((c) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2.0),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: c['role'] == 'Editor'
                                      ? const Color(0xFFB99750)
                                      : Colors.grey,
                                  child: Text(
                                    c['email']![0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Main Font'),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Owner: ${userName.isNotEmpty ? userName : 'No username'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Main Font',
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
              // Collaborators section
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
                      collaborators[i]['invited'] == 'true'
                          ? Dismissible(
                              key: Key(collaborators[i]['email']!),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.red,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Remove',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Main Font',
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _removeCollaborator(i),
                              child: ListTile(
                                leading: const Icon(Icons.person,
                                    color: Color(0xFFB99750)),
                                title: Row(
                                  children: [
                                    Text(collaborators[i]['email']!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Main Font',
                                            fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Text('•',
                                        style: TextStyle(
                                            color: Color(0xFFB99750),
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text('Invitation sent',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Main Font',
                                            fontSize: 14)),
                                  ],
                                ),
                                subtitle: Text('${collaborators[i]['role']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Main Font',
                                        fontSize: 14)),
                                trailing: const Icon(Icons.swipe_left,
                                    color: Colors.white38),
                              ),
                            )
                          : Dismissible(
                              key: Key(collaborators[i]['email']!),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.red,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Remove',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Main Font',
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _removeCollaborator(i),
                              child: ListTile(
                                leading: const Icon(Icons.person,
                                    color: Color(0xFFB99750)),
                                title: Text(collaborators[i]['email']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Main Font',
                                        fontSize: 16)),
                                subtitle: Text('${collaborators[i]['role']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Main Font',
                                        fontSize: 14)),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Color(0xFFB99750)),
                                  onSelected: (value) => _changeRole(i, value),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'Editor',
                                      child: Text(
                                        'Editor',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                        value: 'Viewer',
                                        child: Text(
                                          'Viewer',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                          fontFamily: 'Main Font',
                          fontSize: 12)),
                  trailing: Switch(
                    value: false,
                    onChanged: (val) {}, // To be implemented later
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
            ],
          ),
        ),
      ),
    );
  }
}
