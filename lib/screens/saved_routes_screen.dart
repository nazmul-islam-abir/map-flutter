import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  // Mock data - replace with actual database later
  final List<Map<String, dynamic>> _savedRoutes = [
    {
      'from': 'Chunafactory',
      'to': 'New Market',
      'date': 'Today',
      'transports': 'CNG, Bus, Rickshaw',
    },
    {
      'from': 'GEC',
      'to': 'Agrabad',
      'date': 'Yesterday',
      'transports': 'Bus, CNG',
    },
    {
      'from': 'Airport',
      'to': 'Patenga',
      'date': '2 days ago',
      'transports': 'Taxi, Bus',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Routes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _savedRoutes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved routes yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save routes to access them quickly',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedRoutes.length,
              itemBuilder: (context, index) {
                final route = _savedRoutes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.route, color: Colors.blue),
                    ),
                    title: Text(
                      '${route['from']} → ${route['to']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('🚌 ${route['transports']}'),
                        const SizedBox(height: 4),
                        Text(
                          'Saved: ${route['date']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showRouteOptions(context);
                      },
                    ),
                    onTap: () {
                      // Navigate to route details
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRouteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions),
                title: const Text('Use this route'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to route with this route
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share route'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Delete route
                },
              ),
            ],
          ),
        );
      },
    );
  }
}