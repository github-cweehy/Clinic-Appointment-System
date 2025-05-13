import 'package:clinic_appointment_system_project/appointmentHistory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'favourite.dart';
import 'help.dart';
import 'login.dart';
import 'selectdoctor.dart';
import 'userprofile.dart';

class MainPage extends StatefulWidget {
  final String userId;

  MainPage({required this.userId});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  List<Map<String, dynamic>> appointmentHistory = [];

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchAppointmentHistory();
  }

  Future<void> fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> fetchAppointmentHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('Appointments')
          .where('userId', isEqualTo: widget.userId) 
          .get();

      final List<Map<String, dynamic>> fetchedHistory = [];

      for (var doc in querySnapshot.docs) {
        final appointmentData = doc.data() as Map<String, dynamic>;

        final dateStr = appointmentData['date'];
        final timeStr = appointmentData['timeSlot'] ?? appointmentData['time'];

        try {
          // Use DateFormat to parse "yyyy-MM-dd hh:mm a"
          final DateFormat format = DateFormat('yyyy-MM-dd hh:mm a');
          final DateTime appointmentStart = format.parse('$dateStr $timeStr');

          final DateTime appointmentEnd = appointmentStart.add(Duration(hours: 1));

          if (appointmentEnd.isBefore(DateTime.now())) {
            print("Skipping expired appointment ID: ${doc.id}");
            continue;
          }

          fetchedHistory.add({
            'id': doc.id,
            ...appointmentData,
          });
        } catch (e) {
          print("Error parsing appointment datetime for document ${doc.id}: $e");
          continue;
        }
      }

      setState(() {
        appointmentHistory = fetchedHistory;
      });
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }

  void _logout(BuildContext context) async {
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

  Widget buildAppointmentCard(Map<String, dynamic> appointmentData) {
    String doctor = appointmentData['doctorName'] ?? 'Unknown Doctor';
    String date = appointmentData['date'] ?? 'Unknown Date';
    String time = appointmentData['timeSlot'] ?? appointmentData['time'] ?? 'Unknown Time';

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
            doctor,
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
        ],
      ),
    );
  }


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
          height: 72,
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
                  _logout(context);
                } else if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: widget.userId),
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
              leading: Icon(Icons.home, color: Colors.blue),
              title: Text('Home Page', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainPage(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue,),
              title: Text('Appointment History', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.blue),
              title: Text('Favorite', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavouritePage(userId: widget.userId),
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
                    builder: (context) => HelpPage(userId: widget.userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),  
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back to Good Health Clinic,",
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        username.toUpperCase(),
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 25),
              Text(
                'Your Active Appointment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              appointmentHistory.isEmpty
                  ? Center(child: Text(''))
                  : ListView.builder(
                      shrinkWrap: true,  
                      itemCount: appointmentHistory.length,
                      itemBuilder: (context, index) {
                        return buildAppointmentCard(appointmentHistory[index]);
                      },
                    ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectDoctor(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.date_range_rounded, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Book An Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60),

              Text(
                'Your Active Check Up',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // userPackages.isEmpty
              //   ? Center(child: Container(
              //       width: double.infinity,
              //       padding: EdgeInsets.symmetric(vertical: 15),
              //       margin: EdgeInsets.symmetric(vertical: 5),
              //       decoration: BoxDecoration(
              //         color: Colors.red,
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       child: Center(
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Icon(Icons.not_interested_rounded, color: Colors.white),
              //             SizedBox(width: 10),
              //             Text(
              //               'No packages bought.',
              //               style: TextStyle(
              //                 color: Colors.white,
              //                 fontSize: 15,
              //                 ),
              //               ),
              //           ],
              //         ),
              //       )))
              //   : ListView.builder(
              //       shrinkWrap: true,
              //       physics: NeverScrollableScrollPhysics(),
              //       itemCount: userPackages.length,
              //       itemBuilder: (context, index) {
              //         return _buildPackageCard(userPackages[index]);
              //       },
              //     ),
            ],
          ),
        ),
      ),
    );
  }
}