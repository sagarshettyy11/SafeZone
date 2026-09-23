import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/components/custom_appbar.dart';
import 'package:safezone/components/custom_bottomnav.dart';
import 'package:safezone/screens/users/chatbot.dart';
import 'package:safezone/screens/users/complaint_page.dart';
import 'package:safezone/screens/users/emergency_page.dart';
import 'package:safezone/screens/users/google_maps.dart';
import 'package:safezone/screens/users/my_account.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/services/user_services.dart';
import 'package:safezone/widgets/user_widgets.dart';

class UserDashboard extends StatefulWidget {
  final int initialTab;
  const UserDashboard({super.key, this.initialTab = 0});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late int _selectedIndex;
  final _userService = UserService();
  final _authService = AuthService();

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _loadProfile();
    _saveFCM();
  }

  Future<void> _loadProfile() async {
    final uid = _authService.currentUserId;
    if (uid != null) {
      final profile = await _userService.fetchUserProfile(uid);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    }
  }

  Future<void> _saveFCM() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _userService.saveFCMToken(token);
      }
    } catch (e) {
      debugPrint("FCM token note: $e");
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboardTab(
        userProfile: _userProfile,
        onJumpToTab: _onTabTapped,
      ),
      const SafetyMapPage(),
      const EmergencyPage(),
      const ComplaintPage(),
      const MyAccountPage(),
    ];

    final String title;
    switch (_selectedIndex) {
      case 0:
        title = "SafeZone";
        break;
      case 1:
        title = "Safety Map";
        break;
      case 2:
        title = "Emergency SOS";
        break;
      case 3:
        title = "File Complaint";
        break;
      case 4:
        title = "My Account";
        break;
      default:
        title = "SafeZone";
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SafeZoneAppBar(
        title: title,
        subtitle: _selectedIndex == 0 ? "Real-time Guardian" : null,
        profileImageUrl: _userProfile?['profile_url'] as String?,
        onProfileTap: () => _onTabTapped(4),
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No new emergency alerts")),
          );
        },
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: SafeZoneBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              tooltip: "AI Safety Assistant",
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
            )
          : null,
    );
  }
}

/// Home dashboard content tab
class HomeDashboardTab extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final ValueChanged<int> onJumpToTab;

  const HomeDashboardTab({
    super.key,
    required this.userProfile,
    required this.onJumpToTab,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userProfile?['display_name'] as String? ?? "Friend";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Safety Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $displayName 👋",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "You are protected under SafeZone",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "PROTECTED",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Central SOS Trigger Banner
          Center(
            child: SOSPulseButton(
              onTap: () => onJumpToTab(2), // jump to Emergency Page
            ),
          ),

          const SizedBox(height: 32),

          // Emergency Services One-Touch Direct Dial
          Text(
            "Emergency Helplines",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const EmergencyDialRow(),

          const SizedBox(height: 28),

          // Quick Action Cards Grid
          Text(
            "Quick Actions",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              QuickActionCard(
                title: "Report Incident",
                subtitle: "Crime, fire, hazard",
                icon: Icons.report_problem_rounded,
                iconColor: AppColors.orange,
                iconBgColor: AppColors.orangeLight,
                onTap: () => onJumpToTab(3),
              ),
              QuickActionCard(
                title: "Safety Map",
                subtitle: "View danger spots",
                icon: Icons.map_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primaryLight,
                onTap: () => onJumpToTab(1),
              ),
              QuickActionCard(
                title: "AI Assistant",
                subtitle: "Ask safety guidance",
                icon: Icons.smart_toy_rounded,
                iconColor: AppColors.purple,
                iconBgColor: AppColors.purpleLight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                  );
                },
              ),
              QuickActionCard(
                title: "Emergency Contacts",
                subtitle: "Manage guardians",
                icon: Icons.contact_phone_rounded,
                iconColor: AppColors.success,
                iconBgColor: AppColors.successLight,
                onTap: () => onJumpToTab(4),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
