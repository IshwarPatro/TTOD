import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _verificationId;
  bool _isPhoneMode = false;
  bool _isEmailMode = false;
  bool _isSignUpMode = false;
  bool _isOtpSent = false;
  bool _isLoading = false;

  String _selectedCountryCode = "+91";
  String _selectedFlag = "🇮🇳";

  static const List<Map<String, String>> _countries = [
    {"name": "India", "code": "+91", "flag": "🇮🇳"},
    {"name": "United States", "code": "+1", "flag": "🇺🇸"},
    {"name": "United Kingdom", "code": "+44", "flag": "🇬🇧"},
    {"name": "Canada", "code": "+1", "flag": "🇨🇦"},
    {"name": "Australia", "code": "+61", "flag": "🇦🇺"},
    {"name": "Germany", "code": "+49", "flag": "🇩🇪"},
    {"name": "France", "code": "+33", "flag": "🇫🇷"},
    {"name": "Singapore", "code": "+65", "flag": "🇸🇬"},
    {"name": "United Arab Emirates", "code": "+971", "flag": "🇦🇪"},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Country",
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.outline, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return ListTile(
                        leading: Text(country["flag"]!, style: const TextStyle(fontSize: 22)),
                        title: Text(
                          country["name"]!,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                        ),
                        trailing: Text(
                          country["code"]!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCountryCode = country["code"]!;
                            _selectedFlag = country["flag"]!;
                          });
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
      fillColor: AppColors.cardBackground,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        if (state is AuthCodeSent) {
          setState(() {
            _isOtpSent = true;
            _verificationId = state.verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verification code sent to your phone.")),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 6),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome to TTOD",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your simple, private cycle & wellness tracker.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primaryAccent),
                      ),
                    )
                  else if (!_isPhoneMode && !_isEmailMode) ...[
                    // Primary privacy-first offline option
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthContinueOffline());
                      },
                      icon: const Icon(Icons.lock_outline, size: 20),
                      label: Text(
                        "Continue Offline (Private)",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.outline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "or sign in for community",
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.outline)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthSignInWithGoogle());
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 26, color: AppColors.onBackground),
                      label: Text(
                        "Continue with Google",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.onBackground,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.cardBackground,
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEmailMode = true;
                                _isSignUpMode = false;
                              });
                            },
                            icon: const Icon(Icons.email_outlined, size: 18, color: AppColors.onBackground),
                            label: Text(
                              "Email",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.onBackground,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.cardBackground,
                              side: const BorderSide(color: AppColors.outline),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _isPhoneMode = true);
                            },
                            icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.onBackground),
                            label: Text(
                              "Phone",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.onBackground,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.cardBackground,
                              side: const BorderSide(color: AppColors.outline),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_isEmailMode) ...[
                    _buildEmailForm(),
                  ] else ...[
                    _buildPhoneForm(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSignUpMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isSignUpMode ? AppColors.primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sign In",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isSignUpMode ? AppColors.onPrimary : AppColors.onBackground,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSignUpMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isSignUpMode ? AppColors.primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Create Account",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isSignUpMode ? AppColors.onPrimary : AppColors.onBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_isSignUpMode) ...[
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
            decoration: _inputDecoration("Your Name"),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
          decoration: _inputDecoration("Email address"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
          decoration: _inputDecoration("Password"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();
            if (email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter your email and password.")),
              );
              return;
            }
            if (_isSignUpMode) {
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your name.")),
                );
                return;
              }
              context.read<AuthBloc>().add(AuthSignUpRequested(
                    email: email,
                    password: password,
                    displayName: name,
                  ));
            } else {
              context.read<AuthBloc>().add(AuthSignInRequested(
                    email: email,
                    password: password,
                  ));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            _isSignUpMode ? "Create Account" : "Sign In",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _isEmailMode = false;
              _emailController.clear();
              _passwordController.clear();
              _nameController.clear();
            });
          },
          child: Text(
            "Back to sign-in options",
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isOtpSent) ...[
          Row(
            children: [
              GestureDetector(
                onTap: _showCountryCodePicker,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "$_selectedFlag $_selectedCountryCode",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.onBackground),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                  decoration: _inputDecoration("Phone number"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              final phone = _phoneController.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a phone number.")),
                );
                return;
              }
              final fullPhone = phone.startsWith('+') ? phone : "$_selectedCountryCode$phone";
              context.read<AuthBloc>().add(AuthVerifyPhoneNumber(fullPhone));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              "Send Verification Code",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ] else ...[
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onBackground, letterSpacing: 2),
            decoration: _inputDecoration("Enter 6-digit code"),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              final code = _otpController.text.trim();
              if (code.isNotEmpty && _verificationId != null) {
                context.read<AuthBloc>().add(AuthConfirmOTP(
                      verificationId: _verificationId!,
                      smsCode: code,
                    ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter the verification code.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              "Verify Code",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _isPhoneMode = false;
              _isOtpSent = false;
              _phoneController.clear();
              _otpController.clear();
            });
          },
          child: Text(
            "Back to sign-in options",
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
