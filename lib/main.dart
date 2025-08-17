import 'package:flutter/material.dart';
import 'provider_screen.dart';
import 'user_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Charging App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SelectionScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/user': (context) => const EVChargingScreen(),
        '/provider': (context) => const EVProviderScreen(),
        '/booking': (context) => const EVChargingScreen(),
      },
    );
  }
}

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to EV Charging',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF706DC7),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/user');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF706DC7),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Search for nearest charging provider',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/provider');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF706DC7)),
                  ),
                ),
                child: const Text(
                  'Want to share charge and earn?',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF706DC7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}