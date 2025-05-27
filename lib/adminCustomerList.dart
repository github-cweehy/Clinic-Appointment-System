// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminEditAppointment.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'adminprofile.dart';
import 'adminTransaction.dart';
import 'login.dart';

class CustomerListPage extends StatefulWidget {
  final String? adminId;

  CustomerListPage({required this.adminId});

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
    fetchAdminUsername();
    fetchUserData();
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

  void showUserDetails(BuildContext context, String username, String email, String phone) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'User Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(thickness: 1),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Username'),
                subtitle: Text(username),
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text(email),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone Number'),
                subtitle: Text(phone),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white),
                label: Text('Close', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        );
      },
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue, size: 30.0),
                SizedBox(width: 20),
                Text(
                  "Clients List",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Column(
              children: [
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: searchUser,
                    decoration: InputDecoration(
                      hintText: 'Search name',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                      ),
                    ),
                  )
                ),
              ],
            ),
            SizedBox(height: 6),
            Expanded(
              child: usersData.isEmpty
              ? Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: searchQuery.isEmpty ? usersData.length : filterUser.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = searchQuery.isEmpty ? usersData[index] : filterUser[index];
                    final username = user['username'];
                    final email = user['email'];
                    final phonenum = user['phone_number'];

                    return InkWell(
                      onTap: () => showUserDetails(context, username, email, phonenum),
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade200,
                                child: Text(username[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 18)),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(username, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            )
          ],
        ),
      ),
    );
  }
}
