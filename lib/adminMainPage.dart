import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminCustomerList.dart';
import 'adminEditAppointment.dart';
import 'adminHelp.dart';
import 'adminTransaction.dart';
import 'adminprofile.dart';
import 'login.dart';

class AdminMainPage extends StatefulWidget {
  final String? adminId;

  AdminMainPage({required this.adminId});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String admin_username = '';
  String adminRole = '';
  List<Map<String, dynamic>> appointmentHistory = [];
  int totalAppointmentsToday = 0;
  int totalUpcomingAppointments = 0;

  @override
  void initState() {
    super.initState();
    fetchAdminUsername();
    fetchTodayAppointments();
  }

  @override
  void didChangeDependencies() 
  {
    super.didChangeDependencies();
  }

  // Fetch admin username from Firebase
  void fetchAdminUsername() async {
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).get();

      if(adminDoc.exists) {
        final role = adminDoc.data()?['role'] ?? 'admins';

        if(role == 'admins') {
          setState(() {
            admin_username = adminDoc.data()?['admin_username'] ?? 'Admin Username';
          });
        }

        if (role == 'doctor' || role == 'nurse') {
          setState(() {
            adminRole = role;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void logout(BuildContext context) async {
    try {
      // Sign out from firebase authentication
      await FirebaseAuth.instance.signOut();

      // Navigate to LoginPage and replace current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle any errors that occur during sign-out
      print("Error sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again')),
      );
    }
  }

  Future<void> fetchTodayAppointments() async {
    try {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctorId', isEqualTo: widget.adminId)
          .where('status', isEqualTo: 'upcoming')
          .get();

      List<Map<String, dynamic>> filteredToday = [];
      int upcomingCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateString = data['date'];
        if (dateString == null) continue;

        try {
          final parsedDate = DateTime.parse(dateString);
          if (parsedDate.year == today.year &&
              parsedDate.month == today.month &&
              parsedDate.day == today.day) {
            filteredToday.add(data);
          }
          upcomingCount++; // count every upcoming
        } catch (_) {
          continue;
        }
      }

      setState(() {
        appointmentHistory = filteredToday;
        totalAppointmentsToday = filteredToday.length;
        totalUpcomingAppointments = upcomingCount;
      });
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }


  Widget buildAppointmentCard(Map<String, dynamic> appointmentData) {
    String patient = appointmentData['name'] ?? 'Unknown Patient';
    String date = appointmentData['date'] ?? 'Unknown Date';
    String time = appointmentData['timeSlot'] ?? appointmentData['time'] ?? 'Unknown Time';
    String symptom = appointmentData['symptom'] ?? 'Unknown Sympton';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
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
          Text(
            "Patient: $patient",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: Colors.black54),
              SizedBox(width: 6),
              Text("Date: $date", style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.black54),
              SizedBox(width: 6),
              Text("Time: $time", style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.sick_rounded, size: 18, color: Colors.black54),
              SizedBox(width: 6),
              Text("Symptom: $symptom", style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDashboardCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 6),
          Text(title, style: TextStyle(color: Colors.blue.shade700)),
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
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }),
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
              underline: const SizedBox(),
              icon: Row(
                children: [
                  Text(
                    admin_username,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
              items: <String>[
                'Profile',
                'Logout'
              ].map((String value) {
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
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 16,
                children: [
                  buildDashboardCard('Appointments \nToday', totalAppointmentsToday.toString(), Icons.calendar_today, Colors.lightBlue),
                  buildDashboardCard('Appointments Scheduled', totalUpcomingAppointments.toString(), Icons.schedule, Colors.green),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Today’s Appointments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              appointmentHistory.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade900),
                          SizedBox(width: 8),
                          Text('No appointments scheduled today'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: appointmentHistory.length,
                      itemBuilder: (context, index) {
                        return buildAppointmentCard(appointmentHistory[index]);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}



