import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 20.0),
      child: Text(
        'Mau pergi atau\nkirim barang hari\nini? 👋',
        style: TextStyle(
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

