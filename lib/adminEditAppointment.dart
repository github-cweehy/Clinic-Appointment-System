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


  @override
  void initState() {
    super.initState();
    fetchUsername();
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

  Future<List<Map<String, dynamic>>> fetchAppointments(String status) async {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctorId', isEqualTo: widget.adminId)
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate ?? DateTime.now()),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15),
              ),
            ),
            Icon(Icons.calendar_month, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
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
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No $status appointments"));

        return ListView(
          padding: EdgeInsets.all(16),
          children: snapshot.data!.map((data) => buildAppointmentCard(data)).toList(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: buildDateSelector("Start Date", startDate, (val) => setState(() => startDate = val))),
                SizedBox(width: 10),
                Expanded(
                    child: buildDateSelector("End Date", endDate, (val) => setState(() => endDate = val))),
              ],
            ),
          ),
          SizedBox(height: 10),
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