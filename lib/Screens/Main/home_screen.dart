import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

import 'package:vasool_diary/Screens/Main/BulkInsert/IndividualCollectionScreen.dart';
import 'package:vasool_diary/Screens/Main/LineScreen.dart';
import 'package:vasool_diary/Screens/UtilScreens/Backuppage.dart';

import 'package:vasool_diary/Utilities/AppBar.dart';
import 'package:vasool_diary/Utilities/Reports/CustomerReportScreen.dart';
import 'package:vasool_diary/Utilities/Reports/PendingReport/PartyPendingDetailsScreen.dart';
import 'package:vasool_diary/Utilities/drawer.dart';
import 'package:vasool_diary/Utilities/FloatingActionButtonWithText.dart';
import 'package:vasool_diary/Screens/Main/linedetailScreen.dart';
import '../../finance_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _ModernDashboardState createState() => _ModernDashboardState();
}

class _ModernDashboardState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  List<String> lineNames = [];
  List<String> originalLineNames = [];
  double totalAmtGiven = 0.0;
  double totalProfit = 0.0;
  double totalAmtRecieved = 0.0;
  Map<String, Map<String, dynamic>> lineDetailsMap = {};
  double todaysTotalDrAmt = 0.0;
  double todaysTotalCrAmt = 0.0;
  double totalexpense = 0.0;
  DateTime selectedDate = DateTime.now();
  bool _isFinancialExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadLineNames(),
      loadLineDetails(),
      loadCollectionAndGivenByDate(selectedDate),
    ]);
  }

  Future<void> loadLineNames() async {
    final names = await dbline.getLineNames();
    final details =
        await Future.wait(names.map((name) => dbline.getLineDetails(name)));
    setState(() {
      originalLineNames = names;
      lineNames = names;
      for (int i = 0; i < names.length; i++) {
        lineDetailsMap[names[i]] = details[i];
      }
    });
  }

  Future<void> loadLineDetails() async {
    final details = await dbline.allLineDetails();
    setState(() {
      totalAmtGiven = details['totalAmtGiven'] ?? 0.0;
      totalProfit = details['totalProfit'] ?? 0.0;
      totalAmtRecieved = details['totalAmtRecieved'] ?? 0.0;
      totalexpense = details['totalexpense'] ?? 0.0;
    });
  }

  Future<void> loadCollectionAndGivenByDate(DateTime date) async {
    String queryDate = DateFormat('yyyy-MM-dd').format(date);
    final result = await CollectionDB.getCollectionAndGivenByDate(queryDate);
    setState(() {
      todaysTotalDrAmt = result['totalDrAmt'] ?? 0.0;
      todaysTotalCrAmt = result['totalCrAmt'] ?? 0.0;
    });
  }

  void handleLineSelected(String lineName) {
    ref.read(currentLineNameProvider.notifier).state = lineName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LineDetailScreen()),
    );
  }

  Widget _buildQuickStatsCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFinancialExpanded = !_isFinancialExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Financial Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _isFinancialExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isFinancialExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total Amount',
                            '₹${NumberFormat("#,##,###").format(totalAmtGiven + totalProfit)}',
                            Icons.trending_up,
                            Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Received',
                            '₹${NumberFormat("#,##,###").format(totalAmtRecieved)}',
                            Icons.download,
                            Colors.lightBlueAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance,
                              color: Colors.white, size: 26),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Outstanding Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '₹${NumberFormat("#,##,###").format(totalAmtGiven - totalAmtRecieved + totalProfit)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Smaller padding
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.today,
                    color: Colors.orange, size: 20), // Smaller icon
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Activity',
                style: TextStyle(
                  fontSize: 18, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12), // Smaller padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.purple.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        loadCollectionAndGivenByDate(pickedDate);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 14, // Smaller font
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDailyStatItem(
                        'Collections',
                        '₹${NumberFormat("#,##,###").format(todaysTotalDrAmt)}',
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40, // Smaller height
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildDailyStatItem(
                        'Given',
                        '₹${NumberFormat("#,##,###").format(todaysTotalCrAmt)}',
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20), // Smaller icon
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12, // Smaller font
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // Smaller font
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Collection Entry',
                  Icons.upload_file,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const IndividualCollectionScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  'Backup',
                  Icons.backup,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DownloadDBScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Pending\nFollow up',
                  Icons.restore,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PartyPendingDetailsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  'Reports',
                  Icons.assessment,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ViewReportsPage()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search lines...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            lineNames = originalLineNames
                .where((lineName) =>
                    lineName.toLowerCase().contains(value.toLowerCase()))
                .toList();
          });
        },
      ),
    );
  }

  Widget _buildLinesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Your Lines',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineNames.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final lineName = lineNames[index];
              final lineDetails = lineDetailsMap[lineName] ?? {};
              final amtGiven = lineDetails['Amtgiven'] ?? 0.0;
              final profit = lineDetails['Profit'] ?? 0.0;
              final expense = lineDetails['expense'] ?? 0.0;
              final amtRecieved = lineDetails['Amtrecieved'] ?? 0.0;
              final calculatedValue = amtGiven + profit - expense - amtRecieved;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      lineName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    lineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Balance: ₹${NumberFormat.currency(symbol: '', decimalDigits: 0).format(calculatedValue)}',
                    style: TextStyle(
                      color: calculatedValue >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String value) async {
                      if (value == 'Update') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LineScreen(entry: lineDetails),
                          ),
                        );
                      } else if (value == 'Delete') {
                        _showDeleteDialog(lineName);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return {'Update', 'Delete'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  ),
                  onTap: () => handleLineSelected(lineName),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteDialog(String lineName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this line? All parties inside will be deleted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final lenIds = await dbLending.getLenIdsByLineName(lineName);
                await dbline.deleteLine(lineName);
                await dbLending.deleteLendingByLineName(lineName);
                for (final lenId in lenIds) {
                  await CollectionDB.deleteEntriesByLenId(lenId);
                }
                loadData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeName = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: financeName,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () => _showUpdateFinanceNameDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadData(),
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildQuickStatsCard(),
                _buildDailyActivityCard(),
                _buildQuickActionsCard(),
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildLinesList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const FloatingActionButtonWithText(
        label: 'Add New Line',
        navigateTo: LineScreen(),
        icon: Icons.add,
      ),
    );
  }

  void _showUpdateFinanceNameDialog(BuildContext context) {
    final TextEditingController financeNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Your Name'),
          content: TextField(
            controller: financeNameController,
            decoration: const InputDecoration(hintText: 'Enter Your Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final newFinanceName = financeNameController.text;
                if (newFinanceName.isNotEmpty) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('financeName', newFinanceName);
                  ref.read(financeProvider.notifier).state = newFinanceName;
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
