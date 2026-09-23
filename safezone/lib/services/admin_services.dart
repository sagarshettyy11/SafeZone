import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all complaints ordered by creation/ID descending
  Future<List<Map<String, dynamic>>> fetchAllComplaints() async {
    try {
      final response = await _supabase
          .from('complaints')
          .select()
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService.fetchAllComplaints error: $e');
      return [];
    }
  }

  /// Update the status of a specific complaint ('approved', 'declined', 'pending')
  Future<bool> updateComplaintStatus(dynamic complaintId, String status) async {
    try {
      await _supabase
          .from('complaints')
          .update({'status': status})
          .eq('id', complaintId);

      return true;
    } catch (e) {
      debugPrint('AdminService.updateComplaintStatus error: $e');
      return false;
    }
  }

  /// Fetch aggregated counts for the dashboard
  Future<Map<String, int>> fetchStats() async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('status');

      final list = List<Map<String, dynamic>>.from(response);

      int total = list.length;
      int pending = 0;
      int approved = 0;
      int declined = 0;

      for (var row in list) {
        final status = (row['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'approved') {
          approved++;
        } else if (status == 'declined' || status == 'rejected') {
          declined++;
        } else {
          pending++;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'declined': declined,
      };
    } catch (e) {
      debugPrint('AdminService.fetchStats error: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'declined': 0,
      };
    }
  }

  /// Delete a complaint record
  Future<bool> deleteComplaint(dynamic complaintId) async {
    try {
      await _supabase.from('complaints').delete().eq('id', complaintId);
      return true;
    } catch (e) {
      debugPrint('AdminService.deleteComplaint error: $e');
      return false;
    }
  }
}
