import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:progdia_app/providers/habit_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

String? getUsernameValidationError(String username) {
  if (username.isEmpty) return 'Username required.';
  if (username.length < 3 || username.length > 20) return 'Username must be 3-20 characters.';
  if (!RegExp(r'^[a-z0-9._]+?$').hasMatch(username)) return 'Only lowercase letters, numbers, underscores, and periods allowed.';
  if (username.startsWith('.') || username.startsWith('_') || username.endsWith('.') || username.endsWith('_')) return 'Cannot start or end with . or _.';
  if (username.contains('..') || username.contains('__') || username.contains('._') || username.contains('_.')) return 'No consecutive periods or underscores.';
  return null;
}


class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _usernameError;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _usernameController.addListener(() {
      if (_usernameError != null) {
        setState(() {
          _usernameError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameAvailable(String username) async {
    final doc = await FirebaseFirestore.instance.collection('usernames').doc(username).get();
    return !doc.exists;
  }

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Username logic FIRST
        final username = _usernameController.text.trim();
        final usernameError = getUsernameValidationError(username);
        if (usernameError != null) {
          setState(() {
            _usernameError = usernameError;
          });
          setState(() => _isLoading = false);
          return;
        }
        final available = await _isUsernameAvailable(username);
        if (!available) {
          setState(() {
            _usernameError = 'Username already taken';
          });
          setState(() => _isLoading = false);
          return;
        }
        // Only now create the user
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        await cred.user?.updateDisplayName(_nameController.text.trim());
        // Save username to users/{userId} and usernames/{username}
        final userId = cred.user?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'username': username,
          }, SetOptions(merge: true));
          await FirebaseFirestore.instance.collection('usernames').doc(username).set({
            'userId': userId,
          });
        }
      }
      if (!mounted) return;
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.loadUserStatsFromFirestore();
      if (!mounted) return;
      await habitProvider.loadTasksFromFirestore();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication error'),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Username Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        String? username = (docSnapshot.data()?['username'] as String?);
        if (username == null || username.isEmpty) {
          username = await _promptForUsername(context);
          if (username == null) return; // User cancelled
          await userDoc.set({
            'username': username,
            'email': user.email,
          }, SetOptions(merge: true));
          await FirebaseFirestore.instance.collection('usernames').doc(username).set({
            'userId': user.uid,
          });
        }
      }
      if (!mounted) return;
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.loadUserStatsFromFirestore();
      if (!mounted) return;
      await habitProvider.loadTasksFromFirestore();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      debugPrint('Google Sign-in Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Google sign-in failed'),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptForUsername(BuildContext context) async {
    String username = '';
    String? error;
    final theme = Theme.of(context);
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: theme.colorScheme.surface,
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App icon or illustration
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create a Username',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick a unique username to use in the app. You can only do this once.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorText: error,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withAlpha(120)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        labelStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                      onChanged: (value) => username = value,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: error == null
                          ? const SizedBox(height: 0)
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                error!,
                                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final validation = getUsernameValidationError(username);
                          if (validation != null) {
                            setState(() => error = validation);
                            return;
                          }
                          final available = await _isUsernameAvailable(username);
                          if (!available) {
                            setState(() => error = 'Username already taken');
                            return;
                          }
                          Navigator.of(context).pop(username);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleForm() {
    setState(() => isLogin = !isLogin);
    if (isLogin) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.pets, color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Welcome to Progdia',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Sign in to continue' : 'Create your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withAlpha(240),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.alternate_email,
                          errorText: _usernameError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      _isLoading
                          ? const SizedBox(
                              height: 48,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _signInWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _toggleForm,
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Sign In",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In
                _isLoading
                    ? const SizedBox.shrink()
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _signInWithGoogle,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, color: Theme.of(context).colorScheme.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontWeight: FontWeight.w500,
        ),
        errorText: errorText,
      ),
    );
  }
}
