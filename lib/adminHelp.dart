// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adminEditAppointment.dart';
import 'adminTransaction.dart';
import 'adminCustomerList.dart';
import 'adminMainPage.dart';
import 'adminprofile.dart';
import 'login.dart';

class UserHelpPage extends StatefulWidget {
  final String? adminId;

  UserHelpPage({required this.adminId});

  @override
  _UserHelpPage createState() => _UserHelpPage();
}

class _UserHelpPage extends State<UserHelpPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';
  bool isDateFilterApplied = false;

  DateTime? selectedDate;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  List<Map<String, dynamic>> helpMessages = [];
  List<Map<String, dynamic>> usersData = [];

  final Map<String, String> _usernameCache = {};

  Future<String> _fetchUsername(String userId) async{
    if(_usernameCache.containsKey(userId)){
      return _usernameCache[userId]!;
    }

     try{
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if(userSnapshot.exists){
        String username = userSnapshot['username'] ?? 'Unknown User';
        setState(() {
          _usernameCache[userId] = username;
        });
        
        return username;
      }
      else{
        return 'Unknown User';
      }
    }catch(e){
      print('Error fetching username for userId $userId: $e');
      return 'Unknown User';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAdminUsername();
    fetchUserData();
    fetchHelpMessages();
  }

  // Fetch admin username from Firebase
  void fetchAdminUsername() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('admins').doc(widget.adminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          admin_username = snapshot['admin_username'];
        });
      }
    } catch (e) {
      print("Error fetching admin username: $e");
    }
  }

  //get filter data
  Stream<QuerySnapshot> getFilteredData() {
    if (startDate != null && endDate != null) {
      return _firestore
        .collection('help')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();
    } 
    else {
      return _firestore.collection('help').snapshots();
    }
  }

  //selected date
  void selectDate(BuildContext context, bool isStartDate) async {
    List<DateTime> availableDates = await getAvailableDates();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No available dates to select.")),
      );
      return;
    }

    DateTime minDate = availableDates.reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxDate = availableDates.reduce((a, b) => a.isAfter(b) ? a : b);

    DateTime initialDate = isStartDate ? startDate : endDate;
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, 
      firstDate: minDate,
      lastDate: maxDate,
      selectableDayPredicate: (date) {
        return availableDates.contains(DateTime(date.year, date.month, date.day));
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = DateTime(picked.year, picked.month, picked.day); 
          if (endDate.isBefore(startDate)) {
            endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59); 
          }
        }
        else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); 
          if (startDate.isAfter(endDate)) {
            startDate = DateTime(endDate.year, endDate.month, endDate.day); 
          }
        }
        isDateFilterApplied = true;
      });
      fetchHelpMessages();
    }
  }

  //get availabledates
  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('help').get();

      List<DateTime> availableDates = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        return DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      }).toList();

      if (availableDates.isEmpty) {
        availableDates.add(DateTime.now());
      }

      return availableDates;

    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  //Load all user data at once
  void fetchUserData() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
        setState(() {
          usersData = snapshot.docs.map((doc){ 
            return{
              'id': doc.id, 
              'email': doc['email'] ?? 'Unknown Email',
            };
          }).toList();
        });
    }catch (e) {
        print("Error fetching user data: $e");
      }
  }

  //fetch Help Messages 
  void fetchHelpMessages() async {
    try {
      QuerySnapshot snapshot = await _firestore
      .collection('help')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .get();

      List<Map<String, dynamic>> messages = [];

      for(var doc in snapshot.docs) {
        String userId = doc['userId']; 
        String username = await _fetchUsername(userId);
        String problem = doc['problem'] ?? 'No problem description';
        Timestamp timestamp = doc['timestamp'] ?? Timestamp.now();
        String email = usersData.firstWhere(
          (user) => user['id'] == userId, orElse: () => {'email': 'Unknown Email'}
        )['email'];

        DateTime dateTime = timestamp.toDate().toLocal();
        String formatDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

        messages.add({
          'username': username,
          'email': email,
          'problem': problem,
          'timestamp': formatDate,
        });

        setState(() {
          helpMessages = messages;
        });
      }
    }catch(e) {
      print('Error fetching messages: $e');
    }
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

  Widget buildHelpCard(Map<String, dynamic> message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['username'] ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            message['email'] ?? 'N/A',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                (message['timestamp'] as String?) ?? 'N/A',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, size: 30, color: Colors.deepPurple),
              SizedBox(width: 20),
              Expanded(
                child: Text( "Problem: \n" + message['problem'] ?? 'No message',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color:  Colors.black),
            onPressed: (){
              Scaffold.of(context).openDrawer();
            }
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
              underline: Container(),
              icon: Row(
                children: [
                  Text(admin_username, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
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
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/cliniclogo.jpg',
                    height: 60,
                  ),
                  SizedBox(height: 10),
                  const Text(
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
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_center_rounded, 
                  color: Colors.blue,
                  size: 30,
                ),
                SizedBox(width: 15),
                Text(
                  "Help Messages",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Start Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Start Date", style: TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => selectDate(context, true),
                      child: Container(
                        width: 185,
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                            const SizedBox(width: 5),
                            //Text
                            Text(
                                "${startDate.day} ${_monthName(startDate.month)} ${startDate.year}",
                                style: TextStyle(color: Colors.black, fontSize: 13.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                //End Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("End Date", style: TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => selectDate(context, false),
                      child: Container(
                        width: 185,
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                            const SizedBox(width: 5),
                            //Text
                            Text(
                                "${endDate.day} ${_monthName(endDate.month)} ${endDate.year}",
                                style: TextStyle(color: Colors.black, fontSize: 13.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]
            ),
            const SizedBox(height: 15),
            Expanded(
              child: isDateFilterApplied
                  ? (helpMessages.isEmpty
                      ? Center(child: Text("No help messages for the selected date range."))
                      : ListView.builder(
                          itemCount: helpMessages.length,
                          itemBuilder: (context, index) {
                            final message = helpMessages[index];
                            return buildHelpCard(message);
                          },
                        ))
                  : Center(child: Text("Please select a date range to view help messages.")),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}