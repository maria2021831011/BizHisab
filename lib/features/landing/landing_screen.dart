import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scroll;
  late final AnimationController _floatController;
  late final Animation<double> _float;
  bool _scrolled = false;
  int? _openFaqIndex;

  final _featuresKey = GlobalKey();
  final _aiKey = GlobalKey();
  final _howKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _contactKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _float = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );
  }

  void _onScroll() {
    final s = _scroll.hasClients ? _scroll.offset : 0;
    final next = s > 8;
    if (next != _scrolled) setState(() => _scrolled = next);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _goAuth() {
    context.push('/auth/mobile');
  }

  void _toggleFaq(int i) {
    setState(() {
      _openFaqIndex = _openFaqIndex == i ? null : i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isTablet = width >= 720 && width < 1100;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: LandingColors.bg,
      body: Container(
        color: LandingColors.bg,
        child: Stack(
          children: [
            const Positioned.fill(child: _AmbientBackdrop()),
            SingleChildScrollView(
              controller: _scroll,
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topInset > 0 ? topInset + 6 : 12),
                  _NavBar(
                    scrolled: _scrolled,
                    isMobile: isMobile,
                    onFeatures: () => _scrollTo(_featuresKey),
                    onAi: () => _scrollTo(_aiKey),
                    onHow: () => _scrollTo(_howKey),
                    onPricing: () => _scrollTo(_pricingKey),
                    onFaq: () => _scrollTo(_faqKey),
                    onContact: () => _scrollTo(_contactKey),
                    onLogin: _goAuth,
                  ),
                  const SizedBox(height: 24),
                  _Hero(
                    isMobile: isMobile,
                    floatAnim: _float,
                    onCta: _goAuth,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    key: _featuresKey,
                    child: _FeaturesSection(
                        isMobile: isMobile, isTablet: isTablet),
                  ),
                  Container(
                    key: _aiKey,
                    child: _AiSection(isMobile: isMobile),
                  ),
                  Container(
                    key: _howKey,
                    child: _HowItWorksSection(
                        isMobile: isMobile, isTablet: isTablet),
                  ),
                  Container(
                    key: _pricingKey,
                    child: _SubscriptionSection(onCta: _goAuth),
                  ),
                  Container(
                    key: _faqKey,
                    child: _FaqSection(
                        openIndex: _openFaqIndex, onToggle: _toggleFaq),
                  ),
                  Container(
                    key: _contactKey,
                    child: _ContactSection(onCta: _goAuth),
                  ),
                  const SizedBox(height: 24),
                  _Footer(onCta: _goAuth),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Palette
// ===========================================================================

class LandingColors {
  LandingColors._();

  static const green950 = Color(0xFF06281A);
  static const green900 = Color(0xFF0F3D2A);
  static const green800 = Color(0xFF145538);
  static const green700 = Color(0xFF1E7A4F);
  static const green600 = Color(0xFF27955E);
  static const green500 = Color(0xFF34B273);
  static const green400 = Color(0xFF65CC8E);
  static const green300 = Color(0xFFA6E3B7);
  static const green200 = Color(0xFFD1F0D9);
  static const green100 = Color(0xFFE7F6EB);
  static const green50 = Color(0xFFF1FBF4);

  static const ink = Color(0xFF0E1A14);
  static const slate700 = Color(0xFF33453B);
  static const slate600 = Color(0xFF4D6359);
  static const slate500 = Color(0xFF73877D);
  static const slate400 = Color(0xFF9BAAA2);
  static const slate200 = Color(0xFFD7E0DB);
  static const slate100 = Color(0xFFEBF0ED);
  static const rose = Color(0xFFE76F6F);

  static const bg = Color(0xFFFBFDFC);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green700, green500],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green950, green900, green800],
  );

  static const softMintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [green50, Colors.white],
  );

  static const aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green900, green800, green700],
  );
}

// ===========================================================================
// Ambient backdrop
// ===========================================================================

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -160,
            left: -100,
            child:
                _blob(380, LandingColors.green200.withValues(alpha: 0.55)),
          ),
          Positioned(
            top: 320,
            right: -160,
            child:
                _blob(460, LandingColors.green100.withValues(alpha: 0.45)),
          ),
          Positioned(
            bottom: -160,
            left: 100,
            child:
                _blob(420, LandingColors.green200.withValues(alpha: 0.40)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

// ===========================================================================
// Navbar
// ===========================================================================

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.scrolled,
    required this.isMobile,
    required this.onFeatures,
    required this.onAi,
    required this.onHow,
    required this.onPricing,
    required this.onFaq,
    required this.onContact,
    required this.onLogin,
  });

  final bool scrolled;
  final bool isMobile;
  final VoidCallback onFeatures;
  final VoidCallback onAi;
  final VoidCallback onHow;
  final VoidCallback onPricing;
  final VoidCallback onFaq;
  final VoidCallback onContact;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 16.0 : 32.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scrolled
                ? LandingColors.green200
                : LandingColors.green100,
          ),
          boxShadow: [
            BoxShadow(
              color: scrolled
                  ? LandingColors.green900.withValues(alpha: 0.10)
                  : Colors.transparent,
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const _Logo(),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(label: 'Features', onTap: onFeatures),
              _NavLink(label: 'AI', onTap: onAi),
              _NavLink(label: 'How it works', onTap: onHow),
              _NavLink(label: 'Pricing', onTap: onPricing),
              _NavLink(label: 'FAQ', onTap: onFaq),
              const SizedBox(width: 8),
            ],
            _PrimaryButton(label: 'Login', onPressed: onLogin),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LandingColors.brandGradient,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: LandingColors.green600.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_graph_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'BizHisab AI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: LandingColors.ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            foregroundColor: _hover
                ? LandingColors.green700
                : LandingColors.slate700,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _hover
                  ? LandingColors.green700
                  : LandingColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LandingColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: LandingColors.green600.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 14 : 18,
                vertical: 10,
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Section wrap + eyebrow
// ===========================================================================

class _SectionWrap extends StatelessWidget {
  const _SectionWrap({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final hPad = isMobile ? 20.0 : 32.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _Eyebrow(text: eyebrow),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.ink,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15.5,
                  height: 1.5,
                  color: LandingColors.slate600,
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 14 : 18),
          child,
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LandingColors.green50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LandingColors.green100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: LandingColors.green600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: LandingColors.green700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Hero
// ===========================================================================

class _Hero extends StatelessWidget {
  const _Hero({
    required this.isMobile,
    required this.floatAnim,
    required this.onCta,
  });

  final bool isMobile;
  final Animation<double> floatAnim;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 20.0 : 32.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 56,
        vertical: isMobile ? 44 : 72,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LandingColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: LandingColors.green800.withValues(alpha: 0.32),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _blob(220, LandingColors.green400.withValues(alpha: 0.25)),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _blob(260, LandingColors.green500.withValues(alpha: 0.18)),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HeroText(isMobile: true, onCta: onCta),
                      const SizedBox(height: 36),
                      _HeroDashboard(floatAnim: floatAnim, isMobile: true),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _HeroText(isMobile: false, onCta: onCta),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: _HeroDashboard(
                            floatAnim: floatAnim, isMobile: false),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.isMobile, required this.onCta});
  final bool isMobile;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'AI-powered finance for Bangladesh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 22 : 28),
        Text(
          'BizHisab AI',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 36 : 52,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.2,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Smart Business Finance Assistant',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 16 : 19,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'স্মার্ট ব্যবসায়িক আর্থিক সহকারী',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14.5,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        SizedBox(height: isMobile ? 26 : 32),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _trust(Icons.shield_outlined, 'Secure data'),
            _trust(Icons.bolt_outlined, 'Real-time AI'),
            _trust(Icons.phone_iphone, 'Mobile first'),
          ],
        ),
        SizedBox(height: isMobile ? 26 : 34),
        _HeroCta(onPressed: onCta),
      ],
    );
  }

  Widget _trust(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroCta extends StatefulWidget {
  const _HeroCta({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_HeroCta> createState() => _HeroCtaState();
}

class _HeroCtaState extends State<_HeroCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Flexible(
                    child: Text(
                      'Start Managing Your Business Smarter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LandingColors.green800,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      color: LandingColors.green800, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDashboard extends StatelessWidget {
  const _HeroDashboard({required this.floatAnim, required this.isMobile});
  final Animation<double> floatAnim;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery directly so the dashboard never gets unbounded width
    // (which can happen when this widget is placed inside a non-positioned
    // child of an outer Stack). Falls back to a sensible default.
    final screenW = MediaQuery.sizeOf(context).width;
    final targetSide = isMobile ? 260.0 : 320.0;
    // Account for both the hero's outer margin AND its inner padding so the
    // dashboard mock always fits comfortably inside the hero card on every
    // device width. mobile: margin 20+20 + padding 20+20 = 80.
    // desktop: margin 32+32 + padding 56+56 = 176.
    final heroOuterMargin = isMobile ? 40.0 : 64.0;
    final heroInnerPadding = isMobile ? 40.0 : 112.0;
    final horizontalPadding = heroOuterMargin + heroInnerPadding;
    final maxAllowed = (screenW - horizontalPadding).clamp(180.0, targetSide);
    final side = maxAllowed;
    final glowSize = side;
    // Keep floating chips fully inside the dashboard card so the hero's
    // rounded corners never clip them.
    final chipRightInset = isMobile ? 4.0 : 8.0;
    final chipLeftInset = isMobile ? 4.0 : 8.0;
    final chipTopInset = isMobile ? 12.0 : 24.0;
    final chipBottomInset = isMobile ? 12.0 : 24.0;
    final mockScale = isMobile ? 0.86 : 0.86;
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (context, _) {
        final t = floatAnim.value;
        final lift1 = -8 + (t * 12 - 6);
        final lift2 = 6 - (t * 12 - 6);
        final rotate1 = -0.02 + (t * 0.04 - 0.02);
        return Center(
          child: SizedBox(
            width: side,
            height: side + 12, // extra room for floating chips below
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        LandingColors.green400.withValues(alpha: 0.45),
                        LandingColors.green400.withValues(alpha: 0.0),
                      ]),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, lift1),
                    child: Transform.rotate(
                      angle: rotate1,
                      child: Align(
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          widthFactor: mockScale,
                          child: const _DashboardMock(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: chipRightInset,
                  top: chipTopInset,
                  child: Transform.translate(
                    offset: Offset(0, lift2),
                    child: const _FloatingTxCard(),
                  ),
                ),
                Positioned(
                  left: chipLeftInset,
                  bottom: chipBottomInset,
                  child: Transform.translate(
                    offset: Offset(0, -lift2),
                    child: const _FloatingAiChip(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardMock extends StatelessWidget {
  const _DashboardMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: LandingColors.green500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'This month',
                style: TextStyle(
                  fontSize: 12,
                  color: LandingColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Net Profit',
            style: TextStyle(
              fontSize: 12,
              color: LandingColors.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '৳ 84,250',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: LandingColors.ink,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 14, color: LandingColors.green600),
                    SizedBox(width: 2),
                    Text(
                      '+12.4%',
                      style: TextStyle(
                        fontSize: 12,
                        color: LandingColors.green600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparkPainter(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  value: '৳ 1.42L',
                  color: LandingColors.green600,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Expense',
                  value: '৳ 58K',
                  color: LandingColors.rose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x553FCB99), Color(0x00000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final stroke = Paint()
      ..color = LandingColors.green500
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final fillPath = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.3, size.height * 0.62),
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.75, size.height * 0.22),
      Offset(size.width * 0.9, size.height * 0.28),
      Offset(size.width, size.height * 0.12),
    ];
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, stroke);

    canvas.drawCircle(points.last, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        points.last, 3, Paint()..color = LandingColors.green600);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: LandingColors.green50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: LandingColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTxCard extends StatelessWidget {
  const _FloatingTxCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LandingColors.green50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                color: LandingColors.green700, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sale received',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Customer • Today',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: LandingColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '+৳ 4,500',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: LandingColors.green700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAiChip extends StatelessWidget {
  const _FloatingAiChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: LandingColors.green700.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: LandingColors.green100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome_rounded,
              size: 14, color: LandingColors.green700),
          SizedBox(width: 6),
          Text(
            'AI: Sales up 18% this week',
            style: TextStyle(
              fontSize: 12,
              color: LandingColors.green800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Features
// ===========================================================================

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({required this.isMobile, required this.isTablet});
  final bool isMobile;
  final bool isTablet;

  static const List<_FeatureItem> _items = [
    _FeatureItem(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Daily Transactions',
      desc:
          'Record sales, expenses, dues, and transfers in seconds — built for busy shop owners.',
    ),
    _FeatureItem(
      icon: Icons.receipt_long_outlined,
      title: 'Smart Invoicing',
      desc:
          'Generate clean invoices and share via WhatsApp or SMS in one tap.',
    ),
    _FeatureItem(
      icon: Icons.inventory_2_outlined,
      title: 'Inventory Tracking',
      desc:
          'Track stock in real time, get low-stock alerts, and avoid surprise shortages.',
    ),
    _FeatureItem(
      icon: Icons.groups_2_outlined,
      title: 'Customer & Supplier Ledger',
      desc:
          'See exactly who owes you, and whom you owe — with full transaction history.',
    ),
    _FeatureItem(
      icon: Icons.insights_outlined,
      title: 'AI Business Insights',
      desc:
          'Plain-language reports that tell you what changed, why, and what to do next.',
    ),
    _FeatureItem(
      icon: Icons.cloud_off_outlined,
      title: 'Offline-First',
      desc:
          'Works without internet. Your data syncs automatically when you reconnect.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cross = isMobile ? 1 : (isTablet ? 2 : 3);
    return _SectionWrap(
      key: const Key('section-features'),
      eyebrow: 'Why BizHisab AI',
      title: 'Everything you need to run your business',
      subtitle:
          'Simple, fast tools designed for shop owners in Bangladesh — with AI doing the hard thinking for you.',
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final spacing = 16.0;
          final itemWidth =
              (width - spacing * (cross - 1)) / cross;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _items
                .map((f) => SizedBox(
                      width: itemWidth.clamp(220, 480),
                      child: _FeatureCard(item: f),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item});
  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LandingColors.green100,
        ),
        boxShadow: [
          BoxShadow(
            color: LandingColors.green900.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LandingColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon,
                color: Colors.white, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: LandingColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.desc,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: LandingColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// AI Section
// ===========================================================================

class _AiSection extends StatelessWidget {
  const _AiSection({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      key: const Key('section-ai'),
      eyebrow: 'AI-Powered Features',
      title: 'Your business numbers, explained by AI.',
      subtitle:
          'BizHisab AI turns raw transactions into clear answers — in English or Bangla.',
      child: isMobile
          ? Column(
              children: const [
                _AiFlow(),
                SizedBox(height: 14),
                _AiInsightChat(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 6, child: _AiFlow()),
                SizedBox(width: 14),
                Expanded(flex: 5, child: _AiInsightChat()),
              ],
            ),
    );
  }
}

class _AiFlow extends StatelessWidget {
  const _AiFlow();

  static const List<_FlowNodeData> _nodes = [
    _FlowNodeData(
      icon: Icons.point_of_sale_outlined,
      label: 'Business Data',
      sub: 'Sales, expenses, stock',
    ),
    _FlowNodeData(
      icon: Icons.analytics_outlined,
      label: 'Analysis',
      sub: 'Patterns & trends',
    ),
    _FlowNodeData(
      icon: Icons.auto_awesome_rounded,
      label: 'AI Insight',
      sub: 'Actionable advice',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LandingColors.green100),
        boxShadow: [
          BoxShadow(
            color: LandingColors.green900.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'How BizHisab AI Thinks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LandingColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final isRow = c.maxWidth >= 520;
              if (isRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _nodes.length; i++) ...[
                      Expanded(child: _FlowNode(data: _nodes[i])),
                      if (i != _nodes.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: LandingColors.green500, size: 18),
                        ),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < _nodes.length; i++) ...[
                    _FlowNode(data: _nodes[i]),
                    if (i != _nodes.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Icon(Icons.arrow_downward_rounded,
                            color: LandingColors.green500, size: 18),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const _AiFeatureList(),
        ],
      ),
    );
  }
}

class _FlowNodeData {
  const _FlowNodeData({
    required this.icon,
    required this.label,
    required this.sub,
  });
  final IconData icon;
  final String label;
  final String sub;
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.data});
  final _FlowNodeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        gradient: LandingColors.softMintGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.green100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LandingColors.brandGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LandingColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              color: LandingColors.slate500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeatureList extends StatelessWidget {
  const _AiFeatureList();

  @override
  Widget build(BuildContext context) {
    final features = const [
      'Natural-language answers in Bangla & English',
      'Auto-generated weekly business summaries',
      'Profit, expense, and cash-flow forecasts',
      'Smart suggestions to cut costs and grow sales',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: features
          .map(
            (f) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: LandingColors.green50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LandingColors.green100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: LandingColors.green700),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: LandingColors.green800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AiInsightChat extends StatelessWidget {
  const _AiInsightChat();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LandingColors.aiGradient,
        boxShadow: [
          BoxShadow(
            color: LandingColors.green700.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final w = MediaQuery.of(context).size.width;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w * 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _ChatHeader(),
                  SizedBox(height: 16),
                  _ChatBubble(
                    who: 'user',
                    text: 'এই সপ্তাহে ব্যবসা কেমন চলছে?',
                  ),
                  SizedBox(height: 10),
                  _ChatBubble(
                    who: 'ai',
                    text:
                        'এই সপ্তাহে বিক্রি আগের সপ্তাহের তুলনায় 18% বেড়েছে। সবচেয়ে বেশি বিক্রি হয়েছে শুক্রবার বিকেলে।',
                  ),
                  SizedBox(height: 10),
                  _ChatBubble(
                    who: 'user',
                    text: 'How can I reduce my expenses?',
                  ),
                  SizedBox(height: 10),
                  _ChatBubble(
                    who: 'ai',
                    text:
                        'Top 3 cost-saving moves: 1) renegotiate supplier A, 2) cut idle rent hours, 3) bundle slow stock with fast movers.',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BizHisab AI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  _LiveDot(),
                  SizedBox(width: 6),
                  Text(
                    'Online • answers in your language',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF34D399),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.who, required this.text});
  final String who;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isAi = who == 'ai';
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isAi
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isAi ? 4 : 14),
              bottomRight: Radius.circular(isAi ? 14 : 4),
            ),
            border: Border.all(
                color: Colors.white.withValues(alpha: isAi ? 0.18 : 0.0)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isAi ? Colors.white : LandingColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// How It Works
// ===========================================================================

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.isMobile, required this.isTablet});
  final bool isMobile;
  final bool isTablet;

  static const List<_StepData> _steps = [
    _StepData(
      icon: Icons.download_rounded,
      title: 'Install the App',
      desc: 'Download BizHisab AI from Google Play.',
    ),
    _StepData(
      icon: Icons.phone_android_rounded,
      title: 'Verify with Mobile',
      desc: 'Sign in securely with your mobile number.',
    ),
    _StepData(
      icon: Icons.store_mall_directory_outlined,
      title: 'Set Up Your Business',
      desc: 'Add your shop name and basic details.',
    ),
    _StepData(
      icon: Icons.add_business_outlined,
      title: 'Add Daily Transactions',
      desc: 'Record sales, expenses, and dues instantly.',
    ),
    _StepData(
      icon: Icons.auto_graph_rounded,
      title: 'See AI Insights',
      desc: 'Get smart insights about your business.',
    ),
    _StepData(
      icon: Icons.trending_up_rounded,
      title: 'Grow Your Business',
      desc: 'Make better decisions and earn more profit.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      key: const Key('section-how'),
      eyebrow: 'How It Works',
      title: 'Get started in minutes',
      subtitle:
          'No accounting knowledge needed. Just open the app and start tracking.',
      child: isMobile || isTablet
          ? _StepsColumn(steps: _steps)
          : _StepsRow(steps: _steps),
    );
  }
}

class _StepData {
  const _StepData({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.steps});
  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Connector line aligned with the bottom of each step icon (icon is
          // 56 tall). Use a small inset so the line doesn't touch the card
          // edges when tiles wrap to multiple lines.
          Positioned(
            left: 24,
            right: 24,
            top: 56,
            child: Container(
              height: 2,
              color: LandingColors.green100,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++)
                Expanded(
                  child: _StepTile(
                    step: steps[i],
                    index: i + 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsColumn extends StatelessWidget {
  const _StepsColumn({required this.steps});
  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StepTile(
              step: steps[i],
              index: i + 1,
              vertical: true,
            ),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.index,
    this.vertical = false,
  });
  final _StepData step;
  final int index;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final tile = Column(
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LandingColors.green200),
            boxShadow: [
              BoxShadow(
                color: LandingColors.green700.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(step.icon, color: LandingColors.green700, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          'Step $index',
          style: const TextStyle(
            fontSize: 11.5,
            color: LandingColors.green600,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.title,
          textAlign: vertical ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: LandingColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.desc,
          textAlign: vertical ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: LandingColors.slate600,
          ),
        ),
      ],
    );
    if (!vertical) return tile;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [tile]));
  }
}

// ===========================================================================
// Subscription / Pricing
// ===========================================================================

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      key: const Key('section-pricing'),
      eyebrow: 'Subscription',
      title: 'One simple premium plan',
      subtitle:
          'Everything unlocked. No hidden fees. Cancel anytime with BdApps.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: _PricingCard(onCta: onCta),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final perks = const [
      'Unlimited transactions',
      'AI-powered business insights',
      'Inventory & customer ledgers',
      'Daily, weekly & monthly reports',
      'Priority customer support',
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LandingColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: LandingColors.green700.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Premium plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: LandingColors.green800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Full access to every feature. Subscribe easily with your mobile operator via BdApps.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 22),
          for (final p in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onCta,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Premium Plan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LandingColors.green800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: LandingColors.green800, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FAQ
// ===========================================================================

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.openIndex, required this.onToggle});
  final int? openIndex;
  final ValueChanged<int> onToggle;

  static const List<Map<String, String>> _items = [
    {
      'q': 'What is BizHisab AI?',
      'a':
          'BizHisab AI is a smart business finance assistant for small shop owners in Bangladesh. It helps you record daily transactions, track profit, and understand your business in plain language.'
    },
    {
      'q': 'How do I subscribe to the Premium plan?',
      'a':
          'After signing in, tap the Premium plan card and confirm subscription with your mobile operator. Charges appear on your mobile bill through BdApps — no card required.'
    },
    {
      'q': 'Is my data safe and private?',
      'a':
          'Yes. Your business data is encrypted and stored securely with Firebase. Only you can access it with your verified mobile number.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      key: const Key('section-faq'),
      eyebrow: 'FAQ',
      title: 'Frequently asked questions',
      subtitle:
          'Everything you need to know before getting started.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            for (int i = 0; i < _items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FaqItem(
                  question: _items[i]['q']!,
                  answer: _items[i]['a']!,
                  isOpen: openIndex == i,
                  onTap: () => onToggle(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.isOpen ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _FaqItem old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      if (widget.isOpen) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.isOpen
                ? LandingColors.green300
                : LandingColors.green100),
        boxShadow: [
          BoxShadow(
            color: widget.isOpen
                ? LandingColors.green700.withValues(alpha: 0.14)
                : LandingColors.green900.withValues(alpha: 0.04),
            blurRadius: widget.isOpen ? 18 : 10,
            offset: Offset(0, widget.isOpen ? 10 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LandingColors.ink,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: widget.isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isOpen
                            ? LandingColors.green700
                            : LandingColors.slate500,
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: _c,
                    curve: Curves.easeOutCubic,
                  ),
                  // ignore: deprecated_member_use
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _c,
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 8),
                      child: Text(
                        widget.answer,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: LandingColors.slate600,
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
}

// ===========================================================================
// Contact
// ===========================================================================

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return _SectionWrap(
      key: const Key('section-contact'),
      eyebrow: 'Contact Us',
      title: 'We are here to help',
      subtitle:
          'Reach out anytime — our team replies quickly during Bangladesh business hours.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: LandingColors.green100),
          boxShadow: [
            BoxShadow(
              color: LandingColors.green900.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, c) {
            final stacked = c.maxWidth < 640;
            
            final leftPart = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'support@bizhisab.ai',
                ),
                SizedBox(height: 14),
                _ContactRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: 'Dhaka, Bangladesh',
                ),
                SizedBox(height: 14),
                _ContactRow(
                  icon: Icons.access_time_rounded,
                  label: 'Support hours',
                  value: 'Sun – Thu, 10:00 AM – 8:00 PM',
                ),
              ],
            );

            final rightPart = Container(
              decoration: BoxDecoration(
                gradient: LandingColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ready to get started?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set up your business in minutes and let AI handle the rest.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'Get Started',
                    onPressed: onCta,
                  ),
                ],
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftPart,
                  const SizedBox(height: 20),
                  rightPart,
                ],
              );
            }
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: leftPart),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: rightPart),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: LandingColors.green50,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: LandingColors.green700, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: LandingColors.slate500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: LandingColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Footer
// ===========================================================================

class _Footer extends StatelessWidget {
  const _Footer({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2A1F), Color(0xFF13261F), Color(0xFF0A1E15)],
        ),
        boxShadow: [
          BoxShadow(
            color: LandingColors.green900.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 720;
              final leftPart = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LandingColors.brandGradient,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.auto_graph_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BizHisab AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Smart Business Finance Assistant',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Helping small businesses in Bangladesh grow with AI.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded,
                            color: Color(0xFF34D399), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Made in Bangladesh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final rightPart = Container(
                margin: EdgeInsets.only(
                    top: stacked ? 18 : 0, left: stacked ? 0 : 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to start?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'support@bizhisab.ai',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PrimaryButton(
                      label: 'Get Started',
                      onPressed: onCta,
                      compact: true,
                    ),
                  ],
                ),
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [leftPart, rightPart],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: leftPart),
                  Expanded(flex: 4, child: rightPart),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 540;
              const left = Text(
                '© 2026 BizHisab AI. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              );
              final right = Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _FooterLink(label: 'support@bizhisab.ai'),
                  const _FooterLink(label: 'Privacy'),
                  const _FooterLink(label: 'Terms'),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(height: 10), right],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [left, right],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.78),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Keep AppColors referenced so the existing import stays valid.
// ignore: unused_element
const Color _kKeepAppColors = AppColors.primary;


