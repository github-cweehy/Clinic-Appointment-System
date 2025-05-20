import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adminCustomerList.dart';
import 'adminEditAppointment.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'adminprofile.dart';
import 'login.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String? adminId;

  TransactionHistoryPage({required this.adminId});

  @override
  _TransactionHistoryPage createState() => _TransactionHistoryPage();
}

class _TransactionHistoryPage extends State<TransactionHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String admin_username = '';

  Timestamp? startTimestamp;
  Timestamp? endTimestamp;

  final Map<String, String> _usernameCache = {};

  @override
  void initState() {
    super.initState();
    fetchAdminUsername();
    fetchAllUsernames();
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    startTimestamp = Timestamp.fromDate(startDate);
    endTimestamp = Timestamp.fromDate(endDate);
    searchController.addListener((){
      setState(() {
        searchText = searchController.text.trim().toLowerCase();
      });
    });
  }

  // Fetch admin username from Firebase
  void fetchAdminUsername() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('admins').doc(widget.adminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          admin_username = snapshot['admin_username'];
        });
      }
    } catch (e) {
      print("Error fetching admin username: $e");
    }
  }

  //Load all user data at once
  void fetchAllUsernames() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        _usernameCache.addEntries(
          snapshot.docs.map((doc) => MapEntry(doc.id, doc['username'] ?? 'Unknown User')),
        );
      });
    } catch (e) {
      print("Error fetching usernames: $e");
    }
  }

  Stream<QuerySnapshot> getFilteredData() {
    if (startTimestamp != null && endTimestamp != null) {
      return _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .snapshots();
    } 
    else {
      return _firestore.collection('transactions').snapshots();
    }
  }

  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('transactions').get();
      List<DateTime> availableDates = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        return DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      }).toList();
      return availableDates.toSet().toList();
    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  Widget buildDateSelector(String label, DateTime? selectedDate, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
        if (date != null) onPick(date);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(DateFormat('dd MMMM yyyy').format(selectedDate ?? DateTime.now())),
            Spacer(),
            Icon(Icons.calendar_month, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void logout(BuildContext context) async{
    try {
      // Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();
      
      // Navigate to LoginPage and replace the current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle any errors that occur during sign-out
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  } 

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Image.asset(
          'assets/cliniclogo.jpg',
          height: 60,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              underline: SizedBox(),
              icon: Row(
                children: [
                  Text(
                    admin_username,
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
              items: <String>['Profile', 'Logout'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == 'Logout') {
                  logout(context);
                } else if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(adminId: widget.adminId),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/cliniclogo.jpg',
                    height: 60,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Good Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text('Home Page', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminMainPage(
                      adminId: widget.adminId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_sharp, color: Colors.blue,),
              title: const Text('Clients List', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerListPage(
                      adminId: widget.adminId,),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month_outlined, color: Colors.blue),
              title: Text('Appointments', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsPage(
                      adminId: widget.adminId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.monetization_on_outlined, color: Colors.blue),
              title: Text('Transactions', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionHistoryPage(
                      adminId: widget.adminId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline_sharp, color: Colors.blue),
              title: Text('Help Center', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserHelpPage(
                      adminId: widget.adminId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: buildDateSelector("Start Date", startDate, (val) => setState(() => startDate = val))),
                SizedBox(width: 10),
                Expanded(child: buildDateSelector("End Date", endDate, (val) => setState(() => endDate = val))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by client\'s name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No transactions found.'));
                }

                var transactions = snapshot.data!.docs;

                var filteredTransactions = transactions.where((transaction) {
                  var userId = transaction['userId'];
                  var username = _usernameCache[userId]?.toLowerCase() ?? '';
                  return username.contains(searchText);
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    var transaction = filteredTransactions[index];
                    var userId = transaction['userId'];
                    var username = _usernameCache[userId] ?? 'Unknown User';
                    var transactionId = transaction.id;
                    Timestamp timestamp = transaction['timestamp'];
                    String formattedDate = DateFormat('d MMM yyyy').format(timestamp.toDate());
                    String formattedTime = DateFormat('hh:mm a').format(timestamp.toDate());
                    String paymentMethod = transaction['paymentMethod'];
                    double amount = transaction['amount']?.toDouble() ?? 0.0;

                    if (filteredTransactions.isEmpty) {
                      return Center(child: Text('No matching records.'));
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('@$username', style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
                              Text(transactionId, style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(formattedDate),
                          ]),
                          SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(formattedTime),
                          ]),
                          SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(paymentMethod),
                          ]),
                          SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('RM ${amount.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}