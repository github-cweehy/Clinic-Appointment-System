// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'adminProfile.dart';
import 'login.dart';
import 'superadminManageAccount.dart';

class CustomerListPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  CustomerListPage({required this.superadminId, required this.adminId});

  @override
  _CustomerListPage createState() => _CustomerListPage();
}

class _CustomerListPage extends State<CustomerListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';
  String searchQuery = '';

  List<Map<String, dynamic>> usersData = [];
  List<Map<String, dynamic>> allUserRecord = [];
  List<Map<String, dynamic>> filterUser = [];

  final Map<String, String> _usernameCache = {};

  Future<String> fetchUsername(String userId) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }

    try {
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if (userSnapshot.exists) {
        String username = userSnapshot['username'] ?? 'Unknown User';
        setState(() {
          _usernameCache[userId] = username;
        });

        return username;
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching username for userId $userId: $e');
      return 'Unknown User';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSuperAdminUsername();
    fetchAdminUsername();
    fetchUserData();
  }

  // Fetch superadmin username from Firebase
  void fetchSuperAdminUsername() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('superadmin').doc(widget.superadminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          admin_username = snapshot['superadmin_username'];
        });
      }
    } catch (e) {
      print("Error fetching superadmin username: $e");
    }
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

  //Load all user data at once
  void fetchUserData() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        usersData = snapshot.docs.map((doc) {
          return {
            'username': doc['username'] ?? 'Unknown User',
            'email': doc['email'] ?? 'Unknown Email',
            'phone_number': doc['phone_number'] ?? 'Unknown PhoneNumber',
          };
        }).toList();

        allUserRecord = List<Map<String, dynamic>>.from(usersData);
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  //Search user function
  void searchUser(String query) {
    setState(() {
      searchQuery = query;
      filterUser = allUserRecord.where((record) {
        final username = record['username']?.toLowerCase() ?? '';
        final email = record['email']?.toLowerCase() ?? '';
        final phoneNum = record['phone_number']?.toLowerCase() ?? '';

        return username.contains(searchQuery) || email.contains(searchQuery) || phoneNum.contains(searchQuery);
      }).toList();
    });
  }

  void logout(BuildContext context) async {
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
              underline: Container(),
              icon: Row(
                children: [
                  Text(admin_username, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
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
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(superadminId: widget.superadminId, adminId: widget.adminId),
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
              mainAxisAlignment: MainAxisAlignment.start,
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
                      builder: (context) => AdminMainPage(
                        superadminId: widget.superadminId,
                        adminId: widget.adminId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.blue,),
                title: Text('Manage Admin Account', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageAccountPage(
                        superadminId: widget.superadminId,
                        adminId: widget.adminId,),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.blue,),
                title: Text('Customer List', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerListPage(
                        superadminId: widget.superadminId,
                        adminId: widget.adminId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.blue),
                title: Text('Edit Appointment Slot', style: TextStyle(color: Colors.blue)),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => FavouritePage(userId: widget.userId),
                //     ),
                //   );
                // },
              ),
              ListTile(
                leading: Icon(Icons.local_hospital_rounded, color: Colors.blue),
                title: Text('Appointments', style: TextStyle(color: Colors.blue)),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => CheckUpPage(userId: widget.userId),
                //     ),
                //   );
                // },
              ),
              ListTile(
                leading: Icon(Icons.celebration_rounded, color: Colors.blue),
                title: Text('History', style: TextStyle(color: Colors.blue)),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => FreeCheckUpRewardsPage(userId: widget.userId),
                //     ),
                //   );
                // },
              ),
              ListTile(
                leading: Icon(Icons.help_outline_sharp, color: Colors.blue),
                title: Text('Transactions', style: TextStyle(color: Colors.blue)),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => UserHelpPage(
                //         adminId: widget.adminId,
                //         superadminId: widget.superadminId
                //       ),
                //     ),
                //   );
                // },
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
                        superadminId: widget.superadminId
                      ),
                    ),
                  );
                },
              ),
        ],
      )),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  "Users List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Column(
              children: [
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: searchUser,
                    decoration: InputDecoration(
                      labelText: 'Search by username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Expanded(
                child: ListView.builder(
              itemCount: searchQuery.isEmpty ? usersData.length : filterUser.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final user = searchQuery.isEmpty ? usersData[index] : filterUser[index];
                final username = user['username'];
                final email = user['email'];
                final phonenum = user['phone_number'];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 7),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(username, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(email, style: TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(phonenum, style: TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 3),
                      ],
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
