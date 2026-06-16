import 'package:swappro/barrel.dart';

class FtuOnboardingPage extends StatefulWidget {
  const FtuOnboardingPage({super.key});

  @override
  State<FtuOnboardingPage> createState() => _FtuOnboardingPageState();
}

class _FtuOnboardingPageState extends State<FtuOnboardingPage> {
  static const _bg = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF787676);
  static const _gold = Color(0xFFC3B649);

  final _controller = PageController();
  final _service = OnboardingService();

  var _index = 0;
  var _busy = false;

  List<_OnboardingStep> get _steps => const [
        _OnboardingStep(
          title: 'Add a property',
          subtitle:
              'Start by adding a property you own. This is what you’ll swap with.',
          primaryLabel: 'Add property',
        ),
        _OnboardingStep(
          title: 'Search for a property',
          subtitle:
              'Find items you’d like to swap for using search and categories.',
          primaryLabel: 'Search',
        ),
        _OnboardingStep(
          title: 'View & swap a property',
          subtitle:
              'Open a listing, then tap “Swap This” to send a swap request.',
          primaryLabel: 'Open listings',
        ),
        _OnboardingStep(
          title: 'Pay transaction fee',
          subtitle:
              'When a swap is accepted, pay the transaction fee to unlock details.',
          primaryLabel: 'Open Swap Bay (Accepted)',
        ),
        _OnboardingStep(
          title: 'Go for swap',
          subtitle:
              'After payment, your swap moves to “Ready Swap”. Open it to see meetup details.',
          primaryLabel: 'Open Ready Swap tab',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncPageIndex);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPageIndex);
    _controller.dispose();
    super.dispose();
  }

  void _syncPageIndex() {
    if (!_controller.hasClients) return;
    final page = _controller.page?.round();
    if (page == null || page == _index || !mounted) return;
    setState(() => _index = page);
  }

  int get _currentStepIndex {
    if (_controller.hasClients) {
      final page = _controller.page?.round();
      if (page != null) return page.clamp(0, _steps.length - 1);
    }
    return _index.clamp(0, _steps.length - 1);
  }

  Future<void> _goToStepDestination(int stepIndex) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (stepIndex) {
        case 0:
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBelongingPage()),
          );
          break;
        case 1:
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchPropertiesPage()),
          );
          break;
        case 2:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SearchPropertiesPage(),
            ),
          );
          break;
        case 3:
          await Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeftWithFade,
              duration: const Duration(milliseconds: 350),
              reverseDuration: const Duration(milliseconds: 300),
              child: const SwapBayPage(initialTab: SwapBayTab.accepted),
            ),
          );
          break;
        case 4:
          await Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeftWithFade,
              duration: const Duration(milliseconds: 350),
              reverseDuration: const Duration(milliseconds: 300),
              child: const SwapBayPage(initialTab: SwapBayTab.readySwaps),
            ),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    final current = _currentStepIndex;
    if (current >= _steps.length - 1) {
      await _finish();
      return;
    }
    await _controller.animateToPage(
      current + 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.markCompleted();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        context.showAppSnackBar(
          'Could not save onboarding progress. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final currentIndex = _currentStepIndex;
    final step = _steps[currentIndex];
    final isLast = currentIndex >= _steps.length - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                'Getting started',
                style: AppTypography.style(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _ProgressDots(
                count: _steps.length,
                index: currentIndex,
                active: _gold,
                inactive: const Color(0xFFECECF3),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                    child: _StepCard(
                      number: i + 1,
                      title: s.title,
                      subtitle: s.subtitle,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 14 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _goToStepDestination(currentIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              step.primaryLabel,
                              style: AppTypography.style(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : (isLast ? _finish : _next),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Finish' : 'Next',
                        style: AppTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isLast ? _ink : _muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String subtitle;
  final String primaryLabel;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
  });
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F4F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $number',
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF787676),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTypography.style(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: AppTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF787676),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECECF3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can come back anytime from Home.',
                        style: AppTypography.style(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.index,
    required this.active,
    required this.inactive,
  });

  final int count;
  final int index;
  final Color active;
  final Color inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 8,
            width: i == index ? 22 : 8,
            decoration: BoxDecoration(
              color: i == index ? active : inactive,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          if (i != count - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

