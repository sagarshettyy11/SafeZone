import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your actual pages
import 'map_page.dart';
import '../chatbot.dart'; // ✅ Import chatbot screen
import 'emergency_page.dart';
import 'complaint_page.dart';
import 'user_profile.dart'; // assumes class SettingsPage (your current naming)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  List<Widget> get _pages => [
    HomeDashboardTab(onJumpToTab: _onItemTapped),
    const MapPage(),
    const EmergencyPage(),
    const ComplaintPage(),
    const SettingsPage(),
  ];

  /// ✅ Fetch user profile image URL
  Future<Map<String, dynamic>?> _fetchProfileData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    final response = await supabase
        .from('profiles')
        .select('profile_image_url')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final imagePath = response['profile_image_url'] as String?;

    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        response['profile_url'] = imagePath;
      } else {
        final imageUrl = supabase.storage
            .from('profile-images')
            .getPublicUrl(imagePath);
        response['profile_url'] = imageUrl;
      }
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                "SafeZone",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  iconSize: 32,
                  onPressed: () {},
                ),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchProfileData(),
                  builder: (context, snapshot) {
                    String? profileUrl;

                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      profileUrl = snapshot.data!['profile_url'];
                    }

                    return GestureDetector(
                      onTap: () => _onItemTapped(4), // jump to Profile tab
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (profileUrl != null && profileUrl.isNotEmpty)
                              ? NetworkImage(profileUrl)
                              : null,
                          onBackgroundImageError: (_, _) {
                            // Fallback to default icon if image fails
                            setState(() {
                              profileUrl = null;
                            });
                          },
                          child: (profileUrl == null || profileUrl.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,

      body: IndexedStack(index: _selectedIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/icon/home.png")),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/icon/location.png")),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/icon/emergency.png")),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/icon/complaint.png")),
            label: 'Complaint',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/icon/profile.png")),
            label: 'Profile',
          ),
        ],
      ),

      // ✅ Floating AI Assistant Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        tooltip: "AI Assistant",
        shape: const CircleBorder(),
        child: const Icon(
          CupertinoIcons.chat_bubble_2_fill,
          size: 28,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
      ),
    );
  }
}

class HomeDashboardTab extends StatelessWidget {
  final void Function(int) onJumpToTab;
  const HomeDashboardTab({super.key, required this.onJumpToTab});

  /// ✅ Fetch user full name from Supabase `profiles` table
  Future<String?> _fetchDisplayName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response = await Supabase.instance.client
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return response['display_name'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Greeting dynamically fetched
          FutureBuilder<String?>(
            future: _fetchDisplayName(),
            builder: (context, snapshot) {
              String greeting;
              if (snapshot.connectionState == ConnectionState.waiting) {
                greeting = "Hello 👋"; // temporary while loading
              } else if (snapshot.hasError) {
                greeting = "Hello 👋"; // fallback if errorgit a
              } else {
                greeting = "Hello, ${snapshot.data ?? 'User'} 👋";
              }
              return Text(
                greeting,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            "Stay safe today!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Emergency Button -> jumps to SOS tab
          GestureDetector(
            onTap: () => onJumpToTab(2),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  Text(
                    "Emergency Help",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Options Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildOptionCard(
                icon: Icons.report_problem,
                label: "Report Complaint",
                color: Colors.orange,
                onTap: () => onJumpToTab(3),
              ),
              _buildOptionCard(
                icon: Icons.map,
                label: "Safety Map",
                color: Colors.blue,
                onTap: () => onJumpToTab(1),
              ),
              _buildOptionCard(
                icon: Icons.list_alt,
                label: "My Reports",
                color: Colors.green,
                onTap: () {},
              ),
              _buildOptionCard(
                icon: Icons.settings,
                label: "Profile / Settings",
                color: Colors.grey,
                onTap: () => onJumpToTab(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8), // ✅ modern API
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
