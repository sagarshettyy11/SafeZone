import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safezone/constants/app_colors.dart';
import 'package:safezone/services/admin_services.dart';
import 'package:safezone/services/auth_services.dart';
import 'package:safezone/widgets/admin_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _adminService = AdminService();
  final _authService = AuthService();

  int _selectedTabIndex = 0; // 0: Pending, 1: Approved, 2: Declined, 3: All
  String _searchQuery = "";
  bool _isLoading = false;

  List<Map<String, dynamic>> _allComplaints = [];
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'declined': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final complaints = await _adminService.fetchAllComplaints();
    final stats = await _adminService.fetchStats();

    if (!mounted) return;
    setState(() {
      _allComplaints = complaints;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _handleStatusUpdate(dynamic id, String newStatus) async {
    final success = await _adminService.updateComplaintStatus(id, newStatus);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Report #$id marked as ${newStatus.toUpperCase()}",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: newStatus == 'approved'
              ? AppColors.success
              : AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadDashboardData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status for report #$id"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    List<Map<String, dynamic>> list;

    switch (_selectedTabIndex) {
      case 0:
        list = _allComplaints.where((c) {
          final s = (c['status'] ?? 'pending').toString().toLowerCase();
          return s == 'pending';
        }).toList();
        break;
      case 1:
        list = _allComplaints.where((c) {
          final s = (c['status'] ?? '').toString().toLowerCase();
          return s == 'approved';
        }).toList();
        break;
      case 2:
        list = _allComplaints.where((c) {
          final s = (c['status'] ?? '').toString().toLowerCase();
          return s == 'declined' || s == 'rejected';
        }).toList();
        break;
      default:
        list = _allComplaints;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final cat = (c['category'] ?? '').toString().toLowerCase();
        final desc = (c['description'] ?? '').toString().toLowerCase();
        final id = (c['id'] ?? '').toString().toLowerCase();
        return cat.contains(q) || desc.contains(q) || id.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              "Admin Console",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: "Refresh Data",
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Statistics Overview
              Text(
                "Overview",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdminStatCard(
                      title: "Pending",
                      count: _stats['pending'] ?? 0,
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminStatCard(
                      title: "Approved",
                      count: _stats['approved'] ?? 0,
                      icon: Icons.verified_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AdminStatCard(
                      title: "Declined",
                      count: _stats['declined'] ?? 0,
                      icon: Icons.cancel_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminStatCard(
                      title: "Total Reports",
                      count: _stats['total'] ?? 0,
                      icon: Icons.folder_copy_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Box
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "Search by ID, category, or keyword...",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabChip(index: 0, label: "Pending (${_stats['pending'] ?? 0})"),
                    const SizedBox(width: 8),
                    _buildTabChip(index: 1, label: "Approved (${_stats['approved'] ?? 0})"),
                    const SizedBox(width: 8),
                    _buildTabChip(index: 2, label: "Declined (${_stats['declined'] ?? 0})"),
                    const SizedBox(width: 8),
                    _buildTabChip(index: 3, label: "All Reports (${_stats['total'] ?? 0})"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Complaints List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredComplaints.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        "No Reports Found",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "There are currently no reports in this category.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredComplaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _filteredComplaints[index];
                    final id = complaint['id'];

                    return AdminComplaintTile(
                      complaint: complaint,
                      onApprove: () => _handleStatusUpdate(id, 'approved'),
                      onDecline: () => _handleStatusUpdate(id, 'declined'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip({required int index, required String label}) {
    final isSelected = _selectedTabIndex == index;

    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.surface : AppColors.textBody,
        ),
      ),
      selectedColor: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
        ),
      ),
      onSelected: (_) => setState(() => _selectedTabIndex = index),
    );
  }
}
