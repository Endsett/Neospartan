import 'package:flutter/material.dart';
import '../theme.dart';

class StadionScreen extends StatelessWidget {
  const StadionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      appBar: AppBar(
        title: const Text('STADION'),
        backgroundColor: LaconicTheme.deepBlack,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run,
              size: 64,
              color: LaconicTheme.spartanBronze,
            ),
            SizedBox(height: 20),
            Text(
              'EXERCISE LIBRARY',
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
