import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'favourite.dart';
import 'help.dart';
import 'appointmentReceipt.dart';
import 'mainpage.dart';
import 'userprofile.dart';
import 'login.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  HistoryPage({required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  late TabController tabController;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? selectedDate;
  final Set<String> availableDates = {};
  
  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchAvailableDates();
    tabController = TabController(length: 3, vsync: this);
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


  Future<void> fetchAvailableDates() async {
    final snapshot = await _firestore
        .collection('Appointments')
        .where('userId', isEqualTo: widget.userId)
        .get();

    availableDates.clear();
    for (var doc in snapshot.docs) {
      final date = doc['date'];
      if (date != null) availableDates.add(date);
    }
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(String status) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: status)
        .get();

    List<Map<String, dynamic>> appointments = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    if (selectedDate != null) {
      appointments = appointments.where((appt) {
        try {
          final apptDate = DateFormat('yyyy-MM-dd').parse(appt['date']);
          return apptDate.year == selectedDate!.year &&
                apptDate.month == selectedDate!.month &&
                apptDate.day == selectedDate!.day;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Sort by datetime
    appointments.sort((a, b) {
      try {
        final dateTimeA = DateFormat('yyyy-MM-dd hh:mm a')
            .parse('${a['date']} ${a['timeSlot'] ?? a['time']}');
        final dateTimeB = DateFormat('yyyy-MM-dd hh:mm a')
            .parse('${b['date']} ${b['timeSlot'] ?? b['time']}');
        return dateTimeA.compareTo(dateTimeB);
      } catch (_) {
        return 0;
      }
    });

    return appointments;
  }


  Widget buildAppointmentCard(Map<String, dynamic> appointment) {
    String doctor = appointment['doctorName'] ?? 'Unknown';
    String date = appointment['date'] ?? '';
    String time = appointment['timeSlot'] ?? appointment['time'] ?? '';
    String id = appointment['id'];
    double price = appointment['price']?.toDouble() ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            Expanded(child: Text("Doctor: $doctor", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
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
          Text("RM ${price.toStringAsFixed(2)}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                          title: Text("Cancel Appointment"),
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
                SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => AppointmentReceiptPage(
                          doctor: doctor,
                          date: date,
                          time: time,
                          price: price,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Receipt", style: TextStyle(color: Colors.white)),
                ),
              ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No $status appointments."));
        }

        return ListView(
          padding: EdgeInsets.only(bottom: 16),
          children: snapshot.data!.map(buildAppointmentCard).toList(),
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

  DateTime getInitialSelectableDate() {
    if (selectedDate != null &&
        availableDates.contains(DateFormat('yyyy-MM-dd').format(selectedDate!))) {
      return selectedDate!;
    }

    for (String dateStr in availableDates) {
      try {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {}
    }

    return DateTime.now();
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
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: widget.userId),
                    ),
                  );
                } else if (value == 'Logout') {
                  logout(context);
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
            child: InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: getInitialSelectableDate(),
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