import 'dart:async';
import 'package:flutter/material.dart';

import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        seconds: 2,
      ),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    Timer(
      const Duration(
        seconds: 3,
      ),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MainNavigation(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(
                0xff4f46e5,
              ),
              Color(
                0xff6366f1,
              ),
              Color(
                0xff818cf8,
              ),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      28,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .black12,
                        blurRadius:
                            20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 70,
                    color:
                        Color(
                      0xff4f46e5,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              FadeTransition(
                opacity: _fadeAnim,
                child: const Text(
                  "Debt Manager",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.white,
                    letterSpacing:
                        1,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                "Kelola Hutang Lebih Mudah",
                style: TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              const SizedBox(
                width: 28,
                height: 28,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                  color:
                      Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}