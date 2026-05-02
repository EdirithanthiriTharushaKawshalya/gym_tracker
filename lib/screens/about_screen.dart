import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF121212), size: 16),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF121212),
                child: Icon(Icons.fitness_center, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Gym Tracker',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Text(
              'The App',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gym Tracker is a premium, minimalist workout tracking application designed for those who value simplicity and efficiency. Built with a focus on high-contrast design and intuitive user experience, it helps you stay focused on your gains without the clutter.',
              style: TextStyle(height: 1.6, color: Color(0xFF121212)),
            ),
            const SizedBox(height: 32),
            Text(
              'The Developer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Edirithanthiri Tharusha Kawshalya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121212)),
            ),
            const SizedBox(height: 8),
            const Text(
              'A passionate software engineer dedicated to building high-performance, aesthetically pleasing mobile applications. Our goal is to bridge the gap between powerful functionality and beautiful design.',
              style: TextStyle(height: 1.6, color: Color(0xFF121212)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'tharusha.k.dev@gmail.com',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
