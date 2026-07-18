import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chapri/features/chat/chat_page.dart';
import 'package:chapri/features/profile/profile_page.dart';
import 'package:chapri/features/contact/add_contact_page.dart';
import 'package:chapri/features/reels/reels_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  DateTime? lastBackPressTime;

  final List<Widget> _pages = [
    const ChatPage(),
    const AddContactPage(),
    const ReelsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tekan sekali lagi untuk keluar"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
        }
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person_add), label: "Add Contact"),
            BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: "Reels"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
