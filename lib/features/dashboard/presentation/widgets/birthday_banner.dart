import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:sexta_app/services/auth_service.dart';

class BirthdayBanner extends StatefulWidget {
  const BirthdayBanner({super.key});

  @override
  State<BirthdayBanner> createState() => _BirthdayBannerState();
}

class _BirthdayBannerState extends State<BirthdayBanner> {
  late ConfettiController _confettiController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final firstName = AuthService().currentUser?.firstName ?? '';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC41E3A), Color(0xFF8B0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Text(
                    '🎂 ¡Feliz Cumpleaños, $firstName! 🎉',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toda la Sexta Compañía te desea un día extraordinario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Positioned(
                right: -10,
                top: -10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _isVisible = false;
                    });
                    _confettiController.stop();
                  },
                ),
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          maxBlastForce: 20,
          minBlastForce: 5,
          colors: const [
            Colors.red,
            Colors.amber,
            Colors.white,
            Colors.orange,
          ],
        ),
      ],
    );
  }
}
