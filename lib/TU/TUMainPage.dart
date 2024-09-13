import 'package:flutter/material.dart';
import 'ManageSiswa.dart';
import 'ManageSPP.dart';
import 'ProfileTUPage.dart';

class TUMainPage extends StatefulWidget {
  final String email;

  TUMainPage({required this.email});

  @override
  _TUMainPageState createState() => _TUMainPageState();
}

class _TUMainPageState extends State<TUMainPage> {
  int _selectedIndex = 0;

  List<Widget> _getPages() {
    return [
      HomePage(email: widget.email), // Pass email to HomePage
      ProfileTUPage(email: widget.email), // Profile page with email
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login page
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tata Usaha Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _getPages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: (index) {
          if (index == 2) {
            _showLogoutDialog(context); // Handle logout separately
          } else {
            _onItemTapped(index); // Navigate between Home and Profile
          }
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String email;

  HomePage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, Tata Usaha!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          DashboardCard(
            icon: Icons.people,
            title: 'Manage Students',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageStudentsPage(email: email)),
              );
            },
          ),
          SizedBox(height: 10),
          DashboardCard(
            icon: Icons.attach_money,
            title: 'Manage SPP',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageSPPPage(email: email)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  const DashboardCard({
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontSize: 18)),
        onTap: onPressed,
      ),
    );
  }
}
