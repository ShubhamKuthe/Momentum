import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/responsive.dart';
import '../../widgets/momentum_logo.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onEmailAuth,
    required this.onForgotPassword,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required bool createAccount,
  }) onEmailAuth;
  final Future<void> Function(String email) onForgotPassword;
  final Future<void> Function() onGoogleSignIn;
  final Future<void> Function() onAppleSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _createAccountMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final derivedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _emailController.text.trim().split('@').first;

    setState(() => _isSubmitting = true);
    try {
      await widget.onEmailAuth(
        name: derivedName,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        createAccount: _createAccountMode,
      );
    } catch (error) {
      _showPlaceholderMessage(_normalizeErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleSocialSignIn(Future<void> Function() action) async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await action();
    } catch (error) {
      _showPlaceholderMessage(_normalizeErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showPlaceholderMessage(
          'Enter your email first, then reset the password.');
      return;
    }

    try {
      await widget.onForgotPassword(email);
      _showPlaceholderMessage('Password reset link sent to $email');
    } catch (error) {
      _showPlaceholderMessage(_normalizeErrorMessage(error));
    }
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  InputDecoration _darkFieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    final responsive = context.responsive;
    final palette = context.momentum;

    return InputDecoration(
      hintText: hintText,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: palette.textMuted,
            fontSize: responsive.font(15, min: 14, max: 16),
          ),
      filled: true,
      fillColor: AppColors.inkText,
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.value(AppSpacing.x4, min: 14, max: 18),
        vertical: responsive.value(AppSpacing.x3, min: 12, max: 16),
      ),
      constraints: BoxConstraints(minHeight: responsive.minFieldHeight),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.radius(AppRadii.field)),
        borderSide: const BorderSide(color: AppColors.inkText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.radius(AppRadii.field)),
        borderSide: const BorderSide(color: AppColors.inkText),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.radius(AppRadii.field)),
        borderSide: const BorderSide(color: AppColors.ember),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.radius(AppRadii.field)),
        borderSide: const BorderSide(color: AppColors.ember),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final compact = responsive.width < 390;
    final palette = context.momentum;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortHeight = constraints.maxHeight < 820;
            final ultraCompact = constraints.maxHeight < 760;
            final keyboardOpen = responsive.keyboardInset > 0;
            final sidePadding = responsive.pagePadding;
            final topSpacing = responsive.value(
              ultraCompact
                  ? 8
                  : shortHeight
                      ? 12
                      : 24,
              min: 8,
              max: 28,
            );
            final heroSize = responsive.value(
              ultraCompact
                  ? 56
                  : shortHeight
                      ? 68
                      : compact
                          ? 74
                          : 82,
              min: 54,
              max: 88,
            );
            final titleSize = responsive.font(
              ultraCompact
                  ? 24
                  : shortHeight
                      ? 26
                      : compact
                          ? 28
                          : 30,
              min: 23,
              max: 32,
            );
            final bodyFont = responsive.font(
              ultraCompact
                  ? 13.5
                  : shortHeight
                      ? 14
                      : compact
                          ? 15
                          : 16,
              min: 13,
              max: 17,
            );
            final fieldGap = responsive.value(
              ultraCompact
                  ? 10
                  : shortHeight
                      ? 12
                      : 16,
              min: 10,
              max: 18,
            );
            final sectionGap = responsive.value(
              ultraCompact
                  ? 10
                  : shortHeight
                      ? 14
                      : 18,
              min: 10,
              max: 22,
            );
            final restingBottomPadding = responsive.value(
              ultraCompact
                  ? 10
                  : shortHeight
                      ? 14
                      : 18,
              min: 10,
              max: 18,
            );
            final bottomPadding = keyboardOpen
                ? responsive.value(12, min: 8, max: 16)
                : restingBottomPadding;
            final availableHeight =
                (constraints.maxHeight - topSpacing - restingBottomPadding)
                    .clamp(0.0, double.infinity);

            return Stack(
              children: [
                if (!keyboardOpen) ...[
                  const Positioned(
                    top: 22,
                    left: 28,
                    child: _BackgroundDot(),
                  ),
                  const Positioned(
                    top: 48,
                    right: 34,
                    child: _BackgroundDot(size: 7),
                  ),
                  const Positioned(
                    top: 34,
                    left: 0,
                    right: 0,
                    child: _TopWaveLine(offset: 0),
                  ),
                  const Positioned(
                    top: 68,
                    left: 0,
                    right: 0,
                    child: _TopWaveLine(offset: 14),
                  ),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    topSpacing,
                    sidePadding,
                    bottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsive.value(420, min: 0, max: 460),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: availableHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: responsive.value(
                                  ultraCompact
                                      ? 2
                                      : shortHeight
                                          ? 6
                                          : 14,
                                  min: 2,
                                  max: 16,
                                ),
                              ),
                              Center(
                                child: MomentumLogo(
                                  size: heroSize,
                                  radius: responsive.radius(
                                    ultraCompact
                                        ? 18
                                        : shortHeight
                                            ? 22
                                            : 24,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: responsive.value(
                                  ultraCompact
                                      ? 12
                                      : shortHeight
                                          ? 18
                                          : 22,
                                  min: 12,
                                  max: 24,
                                ),
                              ),
                              Text(
                                _createAccountMode
                                    ? 'Create your account'
                                    : 'Welcome back',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                      color: palette.text,
                                    ),
                              ),
                              SizedBox(
                                height: responsive.value(
                                  ultraCompact
                                      ? 6
                                      : shortHeight
                                          ? 8
                                          : 10,
                                  min: 6,
                                  max: 10,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.value(
                                    ultraCompact
                                        ? 0
                                        : shortHeight
                                            ? 6
                                            : 16,
                                    min: 0,
                                    max: 18,
                                  ),
                                ),
                                child: Text(
                                  _createAccountMode
                                      ? 'Create your account.'
                                      : 'Sign in to continue.',
                                  textAlign: TextAlign.center,
                                  maxLines: ultraCompact
                                      ? 2
                                      : shortHeight
                                          ? 3
                                          : 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: palette.textSoft,
                                        height: 1.4,
                                        fontSize: bodyFont,
                                      ),
                                ),
                              ),
                              SizedBox(
                                height: responsive.value(
                                  ultraCompact
                                      ? 12
                                      : shortHeight
                                          ? 18
                                          : 22,
                                  min: 12,
                                  max: 24,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(
                                  responsive.value(4, min: 4, max: 6),
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(
                                    responsive.radius(AppRadii.tile),
                                  ),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _AuthModeButton(
                                        label: 'Sign in',
                                        selected: !_createAccountMode,
                                        onTap: () => setState(
                                            () => _createAccountMode = false),
                                      ),
                                    ),
                                    Expanded(
                                      child: _AuthModeButton(
                                        label: 'Create account',
                                        selected: _createAccountMode,
                                        onTap: () => setState(
                                            () => _createAccountMode = true),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: responsive.value(
                                  ultraCompact
                                      ? 10
                                      : shortHeight
                                          ? 14
                                          : 16,
                                  min: 10,
                                  max: 18,
                                ),
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_createAccountMode) ...[
                                      TextFormField(
                                        controller: _nameController,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: responsive.font(15.5,
                                              min: 14.5, max: 16.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: _darkFieldDecoration(
                                          hintText: 'Full name',
                                        ),
                                        validator: (value) {
                                          if (!_createAccountMode) {
                                            return null;
                                          }
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: fieldGap),
                                    ],
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: responsive.font(15.5,
                                            min: 14.5, max: 16.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _darkFieldDecoration(
                                        hintText: 'Email',
                                      ),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty ||
                                            !text.contains('@')) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: fieldGap),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: responsive.font(15.5,
                                            min: 14.5, max: 16.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _darkFieldDecoration(
                                        hintText: 'Password',
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if ((value ?? '').trim().length < 6) {
                                          return 'Use at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (!_createAccountMode) ...[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _handleForgotPassword,
                                          style: TextButton.styleFrom(
                                            foregroundColor: palette.accent,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: responsive.value(4,
                                                  min: 4, max: 8),
                                              vertical: 0,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(
                                      height: responsive.value(
                                        ultraCompact
                                            ? 6
                                            : shortHeight
                                                ? 8
                                                : 10,
                                        min: 6,
                                        max: 10,
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: ultraCompact
                                          ? responsive.value(48,
                                              min: 46, max: 50)
                                          : responsive.minButtonHeight,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: palette.accent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              responsive
                                                  .radius(AppRadii.control),
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            _isSubmitting ? null : _submit,
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _createAccountMode
                                                    ? 'Create account'
                                                    : 'Sign in',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: responsive.font(
                                                        17,
                                                        min: 16,
                                                        max: 18,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(height: sectionGap),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(color: AppColors.line),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: responsive.value(
                                              10,
                                              min: 8,
                                              max: 12,
                                            ),
                                          ),
                                          child: Text(
                                            _createAccountMode
                                                ? 'OR CREATE WITH'
                                                : 'OR CONTINUE WITH',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: palette.textSoft,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.6,
                                                  fontSize: responsive.font(
                                                    ultraCompact ? 11 : 13,
                                                    min: 11,
                                                    max: 13.5,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(color: AppColors.line),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: responsive.value(
                                        ultraCompact
                                            ? 8
                                            : shortHeight
                                                ? 12
                                                : 14,
                                        min: 8,
                                        max: 14,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _SocialButton(
                                            icon: Image.asset(
                                              'assets/images/google_logo.png',
                                              width: responsive.value(18,
                                                  min: 17, max: 20),
                                              height: responsive.value(18,
                                                  min: 17, max: 20),
                                              filterQuality: FilterQuality.high,
                                            ),
                                            label: 'Google',
                                            onTap: () => _handleSocialSignIn(
                                              widget.onGoogleSignIn,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: responsive.value(12,
                                              min: 10, max: 14),
                                        ),
                                        Expanded(
                                          child: _SocialButton(
                                            icon: Icon(
                                              Icons.apple_rounded,
                                              size: responsive.value(20,
                                                  min: 18, max: 21),
                                            ),
                                            label: 'Apple',
                                            onTap: () => _handleSocialSignIn(
                                              widget.onAppleSignIn,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: sectionGap),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(
                                        responsive.value(
                                          ultraCompact
                                              ? 10
                                              : shortHeight
                                                  ? 12
                                                  : 14,
                                          min: 10,
                                          max: 14,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: ultraCompact
                                            ? palette.surfaceMuted
                                                .withValues(alpha: 0.72)
                                            : palette.successSoft,
                                        borderRadius: BorderRadius.circular(
                                          responsive.radius(16),
                                        ),
                                        border: ultraCompact
                                            ? Border.all(color: palette.border)
                                            : null,
                                      ),
                                      child: Text(
                                        _createAccountMode
                                            ? 'Your account and habit data stay linked to this device.'
                                            : 'Your data stays on this device.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ultraCompact
                                                  ? palette.textSoft
                                                  : palette.success,
                                              fontSize: responsive.font(
                                                ultraCompact ? 11.5 : 12,
                                                min: 11,
                                                max: 12.5,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              height: 1.35,
                                            ),
                                        maxLines: ultraCompact
                                            ? 2
                                            : shortHeight
                                                ? 3
                                                : 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!keyboardOpen)
                                SizedBox(
                                  height: responsive.value(
                                    ultraCompact ? 18 : 28,
                                    min: 16,
                                    max: 32,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: responsive.value(14, min: 12, max: 16),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.inkText : Colors.transparent,
          borderRadius:
              BorderRadius.circular(responsive.radius(AppRadii.control)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? Colors.white : AppColors.slate,
                fontSize: responsive.font(14.5, min: 13.5, max: 15.5),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkText,
        side: const BorderSide(color: AppColors.line),
        backgroundColor: Colors.white.withValues(alpha: 0.82),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(responsive.radius(AppRadii.control)),
        ),
        minimumSize: Size.fromHeight(
          responsive.value(44, min: 42, max: 48),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.value(12, min: 10, max: 14),
          vertical: responsive.value(10, min: 9, max: 12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: responsive.value(8, min: 8, max: 10)),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.inkText,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.font(15, min: 14, max: 16),
                ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDot extends StatelessWidget {
  const _BackgroundDot({this.size = 6});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFCCBC),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TopWaveLine extends StatelessWidget {
  const _TopWaveLine({required this.offset});

  final double offset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, offset),
        child: CustomPaint(
          size: const Size(double.infinity, 32),
          painter: _WavePainter(),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFDCCF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.15,
        size.width * 0.5,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.92,
        size.width,
        size.height * 0.35,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
