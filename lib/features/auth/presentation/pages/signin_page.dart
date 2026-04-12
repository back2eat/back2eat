import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView>
    with SingleTickerProviderStateMixin {
  final _mobileCtrl = TextEditingController();
  final _otpCtrls   = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());
  String? _otpSentTo;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0.03, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  void _transition() {
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _requestOtp(BuildContext context) {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) {
      _snack(context, 'Enter a valid 10-digit mobile number');
      return;
    }
    context.read<AuthBloc>().add(AuthRequestOtpEvent(mobile));
  }

  void _verifyOtp(BuildContext context) {
    if (_otpValue.length != 6) {
      _snack(context, 'Enter the complete 6-digit OTP');
      return;
    }
    context.read<AuthBloc>()
        .add(AuthVerifyOtpEvent(mobile: _otpSentTo!, otp: _otpValue));
  }

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNewUserDetected) {
          context.push('/signup', extra: state.mobile);
          return;
        }
        if (state is AuthOtpSent || state is AuthOtpResent) {
          setState(() {
            _otpSentTo = state is AuthOtpSent
                ? (state).mobile
                : (state as AuthOtpResent).mobile;
          });
          _transition();
          Future.delayed(const Duration(milliseconds: 380),
                  () { if (mounted) _otpFocuses[0].requestFocus(); });
        }
        if (state is AuthAuthenticated) {
          // Register FCM token now that user is authenticated
          NotificationService.instance.registerTokenAfterLogin();
          context.go('/home');
        }
        if (state is AuthError) _snack(context, state.message);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F7F7),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18.sp, color: Colors.black87),
            onPressed: () {
              if (_otpSentTo != null) {
                setState(() {
                  _otpSentTo = null;
                  for (final c in _otpCtrls) c.clear();
                });
                _transition();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8.h),

                // ── Header ──
                SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: _otpSentTo == null
                        ? const _WelcomeHeader()
                        : _OtpHeader(mobile: _otpSentTo!),
                  ),
                ),

                SizedBox(height: 28.h),

                // ── Form card ──
                SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          if (_otpSentTo != null) {
                            return _OtpForm(
                              ctrls: _otpCtrls,
                              focuses: _otpFocuses,
                              isLoading: isLoading,
                              onVerify: () => _verifyOtp(context),
                              onResend: () => context
                                  .read<AuthBloc>()
                                  .add(AuthResendOtpEvent(_otpSentTo!)),
                            );
                          }
                          return _MobileForm(
                            ctrl: _mobileCtrl,
                            isLoading: isLoading,
                            onSubmit: () => _requestOtp(context),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // ── Sign up link ──
                if (_otpSentTo == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No account? ',
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text('Sign Up',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            )),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Welcome header ────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final logoStyle = GoogleFonts.nunito(
      fontSize: 34.sp,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.5,
      color: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome,',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: logoStyle,
            children: [
              const TextSpan(text: 'Back'),
              TextSpan(
                text: '2',
                style: logoStyle.copyWith(color: AppColors.primary),
              ),
              const TextSpan(text: 'Eat'),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Enter your mobile number to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── OTP header ────────────────────────────────────────────────────────────────

class _OtpHeader extends StatelessWidget {
  const _OtpHeader({required this.mobile});
  final String mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify\nYour Number',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: '+91 $mobile',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile form ───────────────────────────────────────────────────────────────

class _MobileForm extends StatelessWidget {
  const _MobileForm({
    required this.ctrl,
    required this.isLoading,
    required this.onSubmit,
  });
  final TextEditingController ctrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Mobile number',
            hintStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black26),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                  left: 14.w, right: 10.w, top: 14.h, bottom: 14.h),
              child: Text(
                '+91',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
            ),
            prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
              BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
              BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
              BorderSide(color: AppColors.primary, width: 1.8),
            ),
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
        ),
        SizedBox(height: 16.h),
        PrimaryButton(
          text: isLoading ? 'Sending OTP…' : 'Send OTP',
          onTap: isLoading ? () {} : onSubmit,
          loading: isLoading,
        ),
        SizedBox(height: 10.h),
        Text(
          'We\'ll send a one-time password to verify you',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11.5.sp,
              color: AppColors.muted,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── OTP form ──────────────────────────────────────────────────────────────────

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.ctrls,
    required this.focuses,
    required this.isLoading,
    required this.onVerify,
    required this.onResend,
  });
  final List<TextEditingController> ctrls;
  final List<FocusNode> focuses;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
                (i) => _OtpBox(
              controller: ctrls[i],
              focusNode: focuses[i],
              onChanged: (val) {
                if (val.length == 1 && i < 5) {
                  focuses[i + 1].requestFocus();
                } else if (val.isEmpty && i > 0) {
                  focuses[i - 1].requestFocus();
                }
                if (i == 5 && val.length == 1) onVerify();
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
        PrimaryButton(
          text: isLoading ? 'Verifying…' : 'Verify OTP',
          onTap: isLoading ? () {} : onVerify,
          loading: isLoading,
        ),
        SizedBox(height: 14.h),
        Divider(color: Colors.black.withOpacity(0.07)),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: onResend,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(
                'Resend OTP',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── OTP box ───────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46.w,
      height: 54.h,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
            BorderSide(color: Colors.black.withOpacity(0.09)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
            BorderSide(color: Colors.black.withOpacity(0.09)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}