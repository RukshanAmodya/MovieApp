import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/focus_helper.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isLogin) {
        await AuthService().signInWithEmail(email: email, password: password);
        if (mounted) {
          setState(() => _successMessage = 'Welcome back!');
        }
      } else {
        await AuthService().signUpWithEmail(email: email, password: password);
        if (mounted) {
          setState(() => _successMessage = 'Account created! Welcome!');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user != null) {
          // Logged-in state
          return _LoggedInView(
            email: user.email,
            displayName: user.displayName,
            onSignOut: () async => await AuthService().signOut(),
          );
        }

        // Auth form
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo & header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: RooflixTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: RooflixTheme.primary.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isLogin ? 'Welcome back' : 'Join RooFlix',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Sign in to your account to continue'
                              : 'Create an account to get started',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: RooflixTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card Container
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: RooflixTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0x33E50914),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: RooflixTheme.primary
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFFF4D4D), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFFF4D4D),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Success message
                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: RooflixTheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: RooflixTheme.primary
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  _successMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field with D-Pad focus & left arrow transition
                        _FieldLabel('Email address'),
                        const SizedBox(height: 8),
                        ListenableBuilder(
                          listenable: _emailFocusNode,
                          builder: (context, child) {
                            final isFocused = _emailFocusNode.hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: RooflixTheme.surfaceSecondary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isFocused
                                      ? RooflixTheme.primary
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: isFocused ? 2.5 : 1.0,
                                ),
                                boxShadow: isFocused
                                    ? [
                                        BoxShadow(
                                          color: RooflixTheme.primary
                                              .withValues(alpha: 0.5),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'you@example.com',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                      color: RooflixTheme.textMuted,
                                      fontSize: 14),
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      color: RooflixTheme.textMuted, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field with D-Pad focus & left arrow transition
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        ListenableBuilder(
                          listenable: _passwordFocusNode,
                          builder: (context, child) {
                            final isFocused = _passwordFocusNode.hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: RooflixTheme.surfaceSecondary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isFocused
                                      ? RooflixTheme.primary
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: isFocused ? 2.5 : 1.0,
                                ),
                                boxShadow: isFocused
                                    ? [
                                        BoxShadow(
                                          color: RooflixTheme.primary
                                              .withValues(alpha: 0.5),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _submit(),
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                      color: RooflixTheme.textMuted,
                                      fontSize: 14),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: RooflixTheme.textMuted,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: RooflixTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button with D-Pad focus & left arrow transition
                        TvFocusDetector(
                          onSelect: _isLoading ? null : _submit,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                FocusScope.of(context).focusInDirection(
                                    TraversalDirection.left);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          builder: (context, isFocused) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 52,
                              decoration: BoxDecoration(
                                color: RooflixTheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isFocused
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: isFocused ? 2.5 : 0.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: RooflixTheme.primary.withValues(
                                        alpha: isFocused ? 0.6 : 0.3),
                                    blurRadius: isFocused ? 24 : 12,
                                    spreadRadius: isFocused ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'Sign In'
                                            : 'Create Account',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        // Mode toggle
                        TvFocusDetector(
                          onSelect: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          builder: (context, isFocused) {
                            return TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                  _successMessage = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: isFocused
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: _isLogin
                                          ? "Don't have an account? "
                                          : 'Already have an account? ',
                                      style: TextStyle(
                                          color: RooflixTheme.textSecondary),
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Sign Up' : 'Sign In',
                                      style: const TextStyle(
                                        color: RooflixTheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoggedInView extends StatelessWidget {
  final String email;
  final String? displayName;
  final VoidCallback onSignOut;

  const _LoggedInView({
    required this.email,
    this.displayName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final initials = displayName != null && displayName!.isNotEmpty
        ? displayName!.substring(0, 1).toUpperCase()
        : email.substring(0, 1).toUpperCase();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: RooflixTheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: RooflixTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: RooflixTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  displayName ?? 'User',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: RooflixTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _StatChip(label: 'Status', value: 'Active'),
                    SizedBox(width: 12),
                    _StatChip(label: 'Plan', value: 'RooFlix VIP'),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign Out Button with D-Pad focus & left arrow transition
                TvFocusDetector(
                  autofocus: true,
                  onSelect: onSignOut,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        FocusScope.of(context)
                            .focusInDirection(TraversalDirection.left);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  builder: (context, isFocused) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isFocused
                            ? RooflixTheme.primary
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFocused
                              ? Colors.white
                              : Colors.red.withValues(alpha: 0.4),
                          width: isFocused ? 2.5 : 1.0,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: RooflixTheme.primary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ]
                            : [],
                      ),
                      child: OutlinedButton.icon(
                        onPressed: onSignOut,
                        icon: Icon(Icons.logout_rounded,
                            size: 20,
                            color: isFocused ? Colors.white : Colors.red.shade400),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isFocused ? Colors.white : Colors.red.shade400,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white70,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: RooflixTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: RooflixTheme.primary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: RooflixTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
