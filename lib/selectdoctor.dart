// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterDoctor,
              decoration: InputDecoration(
                labelText: 'Search by Doctor Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.blue.shade50,
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Doctor info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${data['first_name']} ${data['last_name']}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      color: Colors.blue
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      data['email'] ?? '',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_iphone,
                                      color: Colors.blue
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      data['phone_number'] ?? '',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Heart icon and Book button
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    favouriteDoctorIds.contains(data['id'] ?? data['email']) 
                                      ? Icons.favorite 
                                      : Icons.favorite_border,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => toggleFavourite(data),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => AppointmentSlotPage(
                                    //       doctorData: data,
                                    //       usreId: widget.userId
                                    //     ),
                                    //   ),
                                    // );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )
                                  ),
                                  child: Text(
                                    'Book',
                                    style: TextStyle(
                                      color: Colors.white
                                    ),
                                  ),
                                )
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
