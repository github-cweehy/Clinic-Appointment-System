import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminCustomerList.dart';
import 'adminHelp.dart';
import 'superadminManageAccount.dart';
import 'adminProfile.dart';
import 'login.dart';

class AdminMainPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  AdminMainPage({required this.superadminId, required this.adminId});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String admin_username = '';

  @override
  void initState() {
    super.initState();
    fetchSuperAdminUsername();
    fetchAdminUsername();
  }

  //avoid back from other page occure error
  //ScaffoldMessenger can be safely used
  @override
  void didChangeDependencies() 
  {
    super.didChangeDependencies();
  }

  // Fetch superadmin username from Firebase
  void fetchSuperAdminUsername() async {
    try {
      final superadminDoc = await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).get();
      if (superadminDoc.exists) {
        final role = superadminDoc.data()?['role']??'superadmin';

        if(role == 'superadmin') {
          setState(() {
            admin_username = superadminDoc.data()?['superadmin_username'] ?? 'Superadmin Username';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching superadmin data: $e')),
      );
    }
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
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(
                        superadminId: widget.superadminId, 
                        adminId: widget.adminId,
                      ),
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
                    superadminId: widget.superadminId,
                    adminId: widget.adminId,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue,),
            title: const Text('Manage Admin Account', style: TextStyle(color: Colors.blue)),
            onTap: () {
              if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAccountPage(superadminId: widget.superadminId, adminId: widget.adminId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Access Denied: Superadmin Only!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue,),
            title: const Text('Customer List', style: TextStyle(color: Colors.blue)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerListPage(
                    superadminId: widget.superadminId,
                    adminId: widget.adminId,),
                ),
              );
            },
          ),
          const ListTile(
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
          const ListTile(
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
          const ListTile(
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
          const ListTile(
            leading: Icon(Icons.help_outline_sharp, color: Colors.blue),
            title: Text('Transactions', style: TextStyle(color: Colors.blue)),
            // onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => HelpPage(userId: widget.userId),
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
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text("Testing")
              ]
            ),
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}



