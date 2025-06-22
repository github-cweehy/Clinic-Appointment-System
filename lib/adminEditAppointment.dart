import 'adminTransaction.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'adminCustomerList.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'login.dart';
import 'adminprofile.dart';

class AppointmentsPage extends StatefulWidget {
  final String? adminId;

  AppointmentsPage({required this.adminId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  late TabController tabController;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? selectedDate;
  String searchQuery = '';
  List<Map<String, dynamic>> allAppointments = [];
  List<Map<String, dynamic>> filteredAppointments = [];
  final Map<String, String> _usernameCache = {};
  final Set<String> availableDates = {};

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchAvailableDates();
    tabController = TabController(length: 3, vsync: this);
    startDate = DateTime.now();
    endDate = DateTime.now();
  }

  Future<void> fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('admins').doc(widget.adminId).get();
      setState(() {
        username = userDoc.data()?['admin_username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> fetchAvailableDates() async {
    final querySnapshot = await _firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: widget.adminId)
        .get();

    availableDates.clear();
    for (var doc in querySnapshot.docs) {
      final date = doc['date'];
      if (date != null) {
        availableDates.add(date);
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(String status) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('doctorId', isEqualTo: widget.adminId)
        .where('status', isEqualTo: status)
        .get();

    List<Map<String, dynamic>> appointments = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final date = data['date'];
      if (date != null) availableDates.add(date);
      final userId = data['userId'];
      String username = 'Unknown';
      if (_usernameCache.containsKey(userId)) {
        username = _usernameCache[userId]!;
      } else {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          username = userDoc['username'] ?? 'Unknown';
          _usernameCache[userId] = username;
        }
      }

      data['username'] = username;
      data['id'] = doc.id;
      appointments.add(data);
    }

    // Sort by date + time
    appointments.sort((a, b) {
      try {
        final dateTimeA = DateFormat('yyyy-MM-dd hh:mm a').parse('${a['date']} ${a['timeSlot'] ?? a['time']}');
        final dateTimeB = DateFormat('yyyy-MM-dd hh:mm a').parse('${b['date']} ${b['timeSlot'] ?? b['time']}');
        return dateTimeA.compareTo(dateTimeB);
      } catch (e) {
        return 0;
      }
    });

    return appointments;
  }

  Widget buildAppointmentCard(Map<String, dynamic> appointment) {
    String client = appointment['name'] ?? 'Unknown';
    String date = appointment['date'] ?? '';
    String time = appointment['timeSlot'] ?? appointment['time'] ?? '';
    String id = appointment['id'];
    String symptom = appointment['symptom'] ?? 'Unknown';
    double price = appointment['price']?.toDouble() ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.person_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text("Client Name: $client", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          ]),
          SizedBox(height: 10),
          Row(children: [
            Icon(Icons.calendar_today, color: Colors.grey),
            SizedBox(width: 8),
            Text("Date: $date"),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Icon(Icons.access_time, color: Colors.grey),
            SizedBox(width: 8),
            Text("Time: $time"),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Icon(Icons.sick_rounded, color: Colors.grey),
            SizedBox(width: 8),
            Text("Symptom: $symptom"),
          ]),
          SizedBox(height: 10),
          Row(
            children: [
              if (appointment['status'] == 'upcoming') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Complete Appointment?"),
                          content: Text("Are you sure you want to mark this appointment as completed?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("No"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await FirebaseFirestore.instance
                                    .collection('Appointments')
                                    .doc(appointment['id'])
                                    .update({'status': 'completed'});
                                setState(() {});                                                       
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Complete", style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Cancel Appointment?"),
                          content: Text("Are you sure you want to cancel this appointment?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("No"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await FirebaseFirestore.instance
                                    .collection('Appointments')
                                    .doc(appointment['id'])
                                    .update({'status': 'cancelled'});
                                setState(() {});                                                       
                              },
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget buildAppointmentList(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAppointments(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return Center(child: Text("No $status appointments"));

        List<Map<String, dynamic>> appointments = snapshot.data!;
        appointments = appointments.where((appointment) {
          final username = appointment['username'].toLowerCase();
          final matchesSearch = username.contains(searchQuery);

          final dateStr = appointment['date'] ?? '';
          if (selectedDate != null) {
            try {
              final apptDate = DateFormat('yyyy-MM-dd').parse(dateStr);
              final matchesDate = apptDate.year == selectedDate!.year &&
                                  apptDate.month == selectedDate!.month &&
                                  apptDate.day == selectedDate!.day;
              return matchesSearch && matchesDate;
            } catch (_) {
              return false;
            }
          }

          return matchesSearch;
        }).toList();

        return ListView(
          padding: EdgeInsets.all(16),
          children: appointments.map((data) => buildAppointmentCard(data)).toList(),
        );
      },
    );
  }

  void logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    username,
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
          SizedBox(height: 10),
          TabBar(
            controller: tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Completed'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Cancelled'),
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by patient name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                  selectableDayPredicate: (DateTime day) {
                    String formatted = DateFormat('yyyy-MM-dd').format(day);
                    return availableDates.contains(formatted);
                  },
                );
                if (picked != null) {
                  final pickedStr = DateFormat('yyyy-MM-dd').format(picked);
                  if (!availableDates.contains(pickedStr)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No appointments on selected date.')),
                    );
                    return;
                  }
                  setState(() {
                    selectedDate = picked;
                  });
                }
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
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Filter by Date'
                            : DateFormat('dd MMM yyyy').format(selectedDate!),
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Icon(Icons.calendar_month, color: Colors.grey.shade600),
                    
                    if (selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                buildAppointmentList("completed"),
                buildAppointmentList("upcoming"),
                buildAppointmentList("cancelled"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}