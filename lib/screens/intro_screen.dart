import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index > 2) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSkip() {
    Navigator.pushReplacementNamed(context, '/user-type');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top bar with skip
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _IntroPage(
                      imagePath: 'assets/illustrations/effortless_appointment.png',
                      size: size,
                      titleBuilder: (context) => Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Effortless '),
                            TextSpan(
                              text: 'Appointment\n',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                            const TextSpan(text: 'Booking'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      subtitle:
                          'Book, manage, and track your medical visits in just a few taps. '
                          'Stay on top of your health without the waiting-room hassle.',
                    ),
                    _IntroPage(
                      imagePath: 'assets/illustrations/find_nearby_hospitals.png',
                      size: size,
                      titleBuilder: (context) => Text(
                        'Find Nearby Hospitals',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      subtitle:
                          'Quickly discover trusted hospitals around you with accurate location data, '
                          'so you always know where to go when you need care.',
                    ),
                    _IntroPage(
                      imagePath: 'assets/illustrations/get_emergency.png',
                      size: size,
                      titleBuilder: (context) => Text(
                        'Get Emergency Help',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      subtitle:
                          'Reach emergency services in seconds and share your location instantly, '
                          'so help can find you faster when every moment counts.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Navigation arrows + indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 20 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? theme.primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    onPressed: _currentPage < 2 ? () => _goToPage(_currentPage + 1) : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Get started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSkip,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String imagePath;
  final Size size;
  final Widget Function(BuildContext) titleBuilder;
  final String subtitle;

  const _IntroPage({
    required this.imagePath,
    required this.size,
    required this.titleBuilder,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: Image.asset(
              imagePath,
              height: size.height * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        titleBuilder(context),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

