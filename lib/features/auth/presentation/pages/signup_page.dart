import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignUpPage extends StatelessWidget {
  final String? prefillMobile;
  const SignUpPage({super.key, this.prefillMobile});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: _SignUpView(prefillMobile: prefillMobile),
    );
  }
}

class _SignUpView extends StatefulWidget {
  final String? prefillMobile;
  const _SignUpView({this.prefillMobile});

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _mobileCtrl;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _otpCtrls   = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());

  String? _otpSentTo;
  bool _otpVerified   = false;
  bool _otpRequested  = false;
  bool _agreedToTerms = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _mobileCtrl = TextEditingController(text: widget.prefillMobile ?? '');
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0.03, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefill = widget.prefillMobile ?? '';
    if (!_otpRequested && prefill.length == 10) {
      _otpRequested = true;
      setState(() => _otpSentTo = prefill);
      _transition();
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted) _otpFocuses[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  void _transition() { _animCtrl.reset(); _animCtrl.forward(); }

  void _requestOtp(BuildContext context) {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) { _snack(context, 'Enter a valid 10-digit mobile number'); return; }
    context.read<AuthBloc>().add(AuthRequestOtpEvent(mobile));
  }

  void _verifyOtp(BuildContext context) {
    if (_otpValue.length != 6) { _snack(context, 'Enter the complete 6-digit OTP'); return; }
    context.read<AuthBloc>().add(AuthVerifyOtpEvent(mobile: _otpSentTo!, otp: _otpValue));
  }

  void _saveProfile(BuildContext context) {
    if (!_agreedToTerms) {
      _snack(context, 'Please agree to the Terms & Conditions to continue');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack(context, 'Please enter your name'); return; }
    final email = _emailCtrl.text.trim();
    context.read<AuthBloc>().add(AuthUpdateProfileEvent(
      name: name,
      email: email.isNotEmpty ? email : null,
    ));
  }

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _title {
    if (_otpVerified) return 'Almost\nDone!';
    if (_otpSentTo != null) return 'Verify\nYour Number';
    return 'Create\nAccount';
  }

  String get _subtitle {
    if (_otpVerified) return 'Tell us your name to complete setup';
    if (_otpSentTo != null) return 'OTP sent to +91 $_otpSentTo';
    return 'No password needed — just your mobile';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent || state is AuthOtpResent) {
          setState(() {
            _otpSentTo = state is AuthOtpSent
                ? (state as AuthOtpSent).mobile
                : (state as AuthOtpResent).mobile;
          });
          _transition();
          Future.delayed(const Duration(milliseconds: 380), () {
            if (mounted) _otpFocuses[0].requestFocus();
          });
        }
        if (state is AuthNewUserDetected) { setState(() => _otpSentTo = state.mobile); _transition(); }
        if (state is AuthAuthenticated) {
          if (!_otpVerified) { setState(() => _otpVerified = true); _transition(); }
          else { context.go('/home'); }
        }
        if (state is AuthError) _snack(context, state.message);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F7F7), elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: Colors.black87),
            onPressed: () {
              if (_otpVerified) { setState(() => _otpVerified = false); _transition(); }
              else if (_otpSentTo != null) {
                setState(() { _otpSentTo = null; for (final c in _otpCtrls) c.clear(); });
                _transition();
              } else { context.pop(); }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 32.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: 8.h),

              SlideTransition(position: _slide, child: FadeTransition(opacity: _fade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900,
                      height: 1.1, letterSpacing: -0.4)),
                  SizedBox(height: 8.h),
                  Text(_subtitle, style: TextStyle(fontSize: 14.sp,
                      color: AppColors.muted, fontWeight: FontWeight.w600)),
                ]),
              )),

              SizedBox(height: 28.h),

              SlideTransition(position: _slide, child: FadeTransition(opacity: _fade,
                child: Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.06))],
                  ),
                  child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    // ── Step 3: Profile + T&C ────────────────────────────────
                    if (_otpVerified) {
                      return Column(children: [
                        AppTextField(
                          hint: 'Full Name *',
                          prefix: Icon(Icons.person_outline, color: const Color(0xFF9A9A9A), size: 20.sp),
                          controller: _nameCtrl, textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 12.h),
                        AppTextField(
                          hint: 'Email (optional)',
                          prefix: Icon(Icons.email_outlined, color: const Color(0xFF9A9A9A), size: 20.sp),
                          controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                        ),
                        SizedBox(height: 18.h),

                        // ── T&C Checkbox ──────────────────────────────────────
                        GestureDetector(
                          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22.w, height: 22.w,
                              decoration: BoxDecoration(
                                color: _agreedToTerms ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: _agreedToTerms ? AppColors.primary : AppColors.line,
                                  width: 2,
                                ),
                              ),
                              child: _agreedToTerms
                                  ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                                  : null,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(child: Text.rich(TextSpan(children: [
                              TextSpan(text: 'I agree to the ',
                                  style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(fontSize: 12.sp, color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openUrl('https://back2eat.com/terms'),
                              ),
                              TextSpan(text: ' and ',
                                  style: TextStyle(fontSize: 12.sp, color: AppColors.muted,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(fontSize: 12.sp, color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openUrl('https://back2eat.com/privacy'),
                              ),
                            ]))),
                          ]),
                        ),

                        SizedBox(height: 18.h),

                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _agreedToTerms ? 1.0 : 0.45,
                          child: PrimaryButton(
                            text: isLoading ? 'Saving…' : 'Save & Continue',
                            onTap: isLoading ? () {} : () => _saveProfile(context),
                            loading: isLoading,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text('You can update these details later',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5.sp,
                                color: AppColors.muted, fontWeight: FontWeight.w500)),
                      ]);
                    }

                    // ── Step 2: OTP ──────────────────────────────────────────
                    if (_otpSentTo != null) {
                      return Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) => _OtpBox(
                            controller: _otpCtrls[i], focusNode: _otpFocuses[i],
                            onChanged: (val) {
                              if (val.length == 1 && i < 5) _otpFocuses[i + 1].requestFocus();
                              else if (val.isEmpty && i > 0) _otpFocuses[i - 1].requestFocus();
                              if (i == 5 && val.length == 1) _verifyOtp(context);
                            },
                          )),
                        ),
                        SizedBox(height: 20.h),
                        PrimaryButton(
                          text: isLoading ? 'Verifying…' : 'Verify OTP',
                          onTap: isLoading ? () {} : () => _verifyOtp(context),
                          loading: isLoading,
                        ),
                        SizedBox(height: 14.h),
                        Divider(color: Colors.black.withOpacity(0.07)),
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: () => context.read<AuthBloc>().add(AuthResendOtpEvent(_otpSentTo!)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.refresh, size: 16.sp, color: AppColors.primary),
                            SizedBox(width: 6.w),
                            Text('Resend OTP', style: TextStyle(fontSize: 13.sp,
                                fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ]),
                        ),
                      ]);
                    }

                    // ── Step 1: Mobile ───────────────────────────────────────
                    return Column(children: [
                      TextField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _requestOtp(context),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Mobile number',
                          hintStyle: TextStyle(fontSize: 15.sp,
                              fontWeight: FontWeight.w500, color: Colors.black26),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 14.w, right: 10.w, top: 14.h, bottom: 14.h),
                            child: Text('+91', style: TextStyle(fontSize: 15.sp,
                                fontWeight: FontWeight.w800, color: Colors.black54)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          filled: true, fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      PrimaryButton(
                        text: isLoading ? 'Sending OTP…' : 'Send OTP',
                        onTap: isLoading ? () {} : () => _requestOtp(context),
                        loading: isLoading,
                      ),
                      SizedBox(height: 10.h),
                      Text("We'll send a one-time password to verify you",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5.sp,
                              color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ]);
                  }),
                ),
              )),

              SizedBox(height: 28.h),

              if (!_otpVerified && _otpSentTo == null)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Sign In', style: TextStyle(fontSize: 13.sp,
                        fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 46.w, height: 54.h,
      child: TextFormField(
        controller: controller, focusNode: focusNode,
        textAlign: TextAlign.center, keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.black87),
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.09))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.09))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}