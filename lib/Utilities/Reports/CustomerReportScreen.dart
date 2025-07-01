import 'package:vasool_diary/Utilities/Reports/PendingReport/PartyPendingDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:vasool_diary/Utilities/Reports/CusFullTrans/ReportScreen2.dart';
import 'package:vasool_diary/Utilities/Reports/Custrans/ReportScreen1.dart';
import 'package:vasool_diary/Utilities/Reports/chartreport/ReportFilterScreen.dart';
import 'package:vasool_diary/Utilities/Reports/Dailyreport/PartyReportPage.dart';

class ViewReportsPage extends StatelessWidget {
  const ViewReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Reports"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Customer Reports",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report 1
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: "Customer Transactions Report",
              subtitle: "Summary of all customer transactions",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen2()),
              ),
            ),

            const SizedBox(height: 12),

            // Report 2
            _buildReportCard(
              context: context,
              icon: Icons.picture_as_pdf,
              iconColor: Colors.deepPurple,
              title: "Customer List PDF",
              subtitle: "List of all customers",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen1()),
              ),
            ),
            // ...existing code...
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: "Daily Transaction Report",
              subtitle: "Summary of all Daily transactions",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportFilterScreen()),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: "Pending Transaction Report",
              subtitle: "Summary of all Party pending transactions",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PartyPendingDetailsScreen()),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.blue,
              title: "Active Parties Report",
              subtitle: "Summary of all Party transactions-Your Diary",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartyReportPage()),
              ),
            ),
// ...existing code...
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
