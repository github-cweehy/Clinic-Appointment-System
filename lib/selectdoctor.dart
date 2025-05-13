// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'appointmentslot.dart';
import 'mainpage.dart';

class SelectDoctor extends StatefulWidget {
  final String userId;

  SelectDoctor({ required this.userId});

  @override
  SelectDoctorState createState() => SelectDoctorState();
}

class SelectDoctorState extends State<SelectDoctor> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  String searchQuery = '';
  String username = '';
  Set <String> favouriteDoctorIds = {};
  String doctorName = '';

  @override
  void initState() {
    super.initState();
    fetchDoctor().then((doctors){
      setState(() {
        allDoctors = doctors;
        filteredDoctors = allDoctors;
      });
    });
    fetchFavourites();
  }

  // Fetch records from `admins` collection where `position` field matches
  Future<List<Map<String, dynamic>>> fetchDoctor() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('position', isEqualTo: 'doctor')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching");
      return [];
    }
  }

  Future<void> fetchFavourites() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('favourite')
        .doc(widget.userId)
        .collection('admins')
        .get();

    setState(() {
      favouriteDoctorIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  void filterDoctor(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredDoctors = allDoctors.where((doctor) {
        final fullName = '${doctor['first_name']} ${doctor['last_name']}'.toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> toggleFavourite(Map<String, dynamic> doctorData) async {
    String doctorId = doctorData['id'];
    final favRef = FirebaseFirestore.instance
        .collection('favourite')
        .doc(widget.userId);

    if (favouriteDoctorIds.contains(doctorId)) {
      await favRef.delete();
      setState(() {
        favouriteDoctorIds.remove(doctorId);
      });
    } else {
      await favRef.set({
        'userId': widget.userId,
        'doctor_id': doctorId,
        'first_name': doctorData['first_name'],
        'last_name': doctorData['last_name'],
        'email': doctorData['email'],
        'phone_number': doctorData['phone_number'],
      });
      setState(() {
        favouriteDoctorIds.add(doctorId);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
              // Navigate back to the main page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainPage(userId: widget.userId),
                ),
              );
            } 
          ),
        title: Image.asset(
          'assets/cliniclogo.jpg', 
          height: 60,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Available Doctors',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: filterDoctor,
              decoration: InputDecoration(
                hintText: 'Search for a doctor...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String,dynamic>>>(
              future: fetchDoctor(),
              builder: (context, snapshot){
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Card(
                      margin: EdgeInsets.all(20),
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Text(
                          'No such doctor.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                final doctorDocs = snapshot.data!;

                return ListView.builder(
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    var data = filteredDoctors[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, size: 30, color: Colors.blue),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. ${data['first_name']} ${data['last_name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.mail_outline, size: 16, color: Colors.grey),
                                      SizedBox(width: 5),
                                      Flexible(child: Text(data['email'] ?? '', style: TextStyle(fontSize: 14))),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_android, size: 16, color: Colors.grey),
                                      SizedBox(width: 5),
                                      Text(data['phone_number'] ?? '', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    favouriteDoctorIds.contains(data['id']) ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => toggleFavourite(data),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Appointmentslot(
                                          userId: widget.userId,
                                          doctorName: 'Dr. ${data['first_name']} ${data['last_name']}',
                                          doctorId: data['id'],
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: 
                                    Text(
                                      'Book',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                  },
                );
              }
            )
          )
        ],
      ),
    );
  }
}
