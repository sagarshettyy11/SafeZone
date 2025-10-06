import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

final logger = Logger();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _fetchComplaints();
  }

  Future<List<Map<String, dynamic>>> _fetchComplaints() async {
    try {
      final response = await supabase
          .from('complaints') // Query the view
          .select()
          .eq('status', 'pending') // fetch only pending complaints
          .order('id', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      logger.i("Fetched ${list.length} complaints");
      return list;
    } catch (e) {
      logger.e("Error fetching complaints: $e");
      return [];
    }
  }

  Future<void> _updateStatus(int complaintId, String status) async {
    try {
      await supabase
          .from('complaints')
          .update({'status': status})
          .eq('id', complaintId);

      setState(() {
        _complaintsFuture = _fetchComplaints();
      });

      logger.i("Updated complaint $complaintId to status $status");
    } catch (e) {
      logger.e("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return const Center(child: Text("No complaints found."));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final id = complaint['id'];
              final category = complaint['category'] ?? '';
              final description = complaint['description'] ?? '';
              final urgency = complaint['urgency']?.toString() ?? '';
              final mediaUrl = complaint['media_url'] ?? '';
              final username = complaint['profile_username'] ?? 'Unknown';
              final status = complaint['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "User: $username",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Category: $category"),
                      Text("Description: $description"),
                      Text("Urgency: $urgency"),
                      if (mediaUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            mediaUrl,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'declined'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _updateStatus(id, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _updateStatus(id, 'declined'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Decline"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
