import 'package:flutter/material.dart';
import '../chat/chat_page.dart';
import '../contact/add_contact_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final pages = [
    const ChatPage(),
    const AddContactPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: NavigationBar(
            backgroundColor: theme.brightness == Brightness.dark 
                ? Colors.grey.shade900 
                : Colors.white,
            elevation: 0, 
            selectedIndex: currentIndex,
            height: 70, 
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 500),
            indicatorColor: theme.primaryColor.withOpacity(0.12), 
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey.shade600),
                selectedIcon: Icon(Icons.chat_bubble_rounded, color: theme.primaryColor),
                label: "Chats",
              ),
              NavigationDestination(
                icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.grey.shade600),
                selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: theme.primaryColor),
                label: "Add",
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade600),
                selectedIcon: Icon(Icons.person_rounded, color: theme.primaryColor),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}