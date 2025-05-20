import 'adminHelp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'adminCustomerList.dart';
import 'adminEditAppointment.dart';
import 'adminMainPage.dart';
import 'adminTransaction.dart';
import 'login.dart';
import 'dart:io';

class AdminProfilePage extends StatefulWidget {
  final String? adminId;

  AdminProfilePage({required this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Map<String, dynamic>? adminData;
  String? adminProfilePicture;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.adminId)
        .get();
      Map<String, dynamic>? data = adminDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          adminData = data;
          adminProfilePicture = data['admin_profilePicture'] ?? ''; 
        });
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  //Function to pick image from gallery
  void pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      uploadProfilePicture(image);
    }
  }

  //Function to upload image to Firebase Storage
  Future<void> uploadProfilePicture(XFile image) async {
    try {
      String fileName = path.basename(image.path);
      final Reference storageRef = FirebaseStorage.instance.ref().child('admin_profilePicture/${widget.adminId}/$fileName');

      UploadTask uploadTask = storageRef.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({
        'admin_profilePicture': downloadUrl,
      });

      setState(() {
        adminProfilePicture = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture updated successfully!')));
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed.')));
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> edit(String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                String newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  if (field == 'phone_number') {                    
                    if (!RegExp(r'^01\d{8,9}$').hasMatch(newValue)) {
                      showSnackBar('Invalid phone number. It must start with 01 and be 10-11 digits long.');
                      return;
                    }
                    if (await isPhoneNumberDuplicate(newValue)) {
                      showSnackBar("This phone number is already in use.");
                      return;
                    }
                  }
                  
                  if ((field == 'first_name' || field == 'last_name') && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(newValue)) {
                      showSnackBar('$field must contain only letters.');
                      return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('admins')
                        .doc(widget.adminId)
                        .update({field: newValue});
                    setState(() {
                      if (field == 'first_name') {
                        adminData?['first_name'] = newValue;
                      } else if (field == 'last_name') {
                        adminData?['last_name'] = newValue;
                      } else if (field == 'phone_number'){
                        adminData?['phone_number'] = newValue;
                      }
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Error updating $field: $e");
                    showSnackBar("Failed to update $field.");
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  //change password
  void showPasswordChangeDialog(){
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isNewPasswordVisible = false;

    showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: false,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 12 || value.length > 15) {
                      return 'at least 12-15 characters';
                    }
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{12,15}$').hasMatch(value)) {
                      return 'at least 1 uppercase & lowercase,\n'
                             '1 number, and 1 special character';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await changePassword(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                    );
                  }
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      // Fetch the current password from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['password'] == currentPassword) {
          // Update the password in Firestore
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(widget.adminId)
              .update({'password': newPassword});

          showSnackBar("Password updated successfully.");
          Navigator.pop(context); 
        } else {
          showSnackBar("Current password is incorrect.");
        }
      }
    } catch (e) {
      print("Error changing password: $e");
      showSnackBar("Failed to update password.");
    }
  }

  //avoid duplicate phone number
  Future<bool> isPhoneNumberDuplicate(String phoneNumber) async {
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
        .collection('admins')
        .where('phone_number', isEqualTo: phoneNumber)
        .get();
      return adminSnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for duplicate phone number: $e");
      return false;
    }
  }

  void logout(BuildContext context) async {
    try {
      //Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      //Handle error when during sign out
      print("Erro sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again.')),
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
            icon: const Icon(Icons.menu, color: Colors.black),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  backgroundImage: adminProfilePicture != null
                      ? NetworkImage(adminProfilePicture!)
                      : null,
                  child: adminProfilePicture == null
                      ? Icon(Icons.person, color: Colors.black, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 10),

              Text(
                adminData?['admin_username'] ?? "Admin's Userame",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // First Name
              buildEditableTextField('First Name', adminData?['first_name'],(){
                edit('first_name', adminData?['first_name'] ?? '');
              }),
              const SizedBox(height: 10),

              // Last Name
              buildEditableTextField('Last Name', adminData?['last_name'], () {
                edit('last_name', adminData?['last_name'] ?? '');
              }),
              const SizedBox(height: 10),

              // Username
              buildReadOnlyTextField('Username', adminData?['admin_username']),
              const SizedBox(height: 10),

              // Email
              buildReadOnlyTextField('Email', adminData?['email']),
              const SizedBox(height: 10),

              // Phone Number
              buildEditableTextField('Phone Number', adminData?['phone_number'], () {
                edit('phone_number', adminData?['phone_number'] ?? '');
              }),                        
              const SizedBox(height: 20),

              // Return Button
              buildActionButton('Return', () {
                Navigator.pop(context);
              }),

              const SizedBox(height: 20),

              // Change Password Button
              buildActionButton('Change Password', () {
                showPasswordChangeDialog();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditableTextField(String label, String? value, VoidCallback onEdit) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
        ),
      ),
      controller: TextEditingController(text: value ?? ''),
    );
  }

  Widget buildReadOnlyTextField(String label, String? value) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      controller: TextEditingController(text: value ?? ''),
    );
  }

  Widget buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      child: Text(
        label,
        style: 
          TextStyle(
            color: Colors.white,), 
        ),
    );
  }
}
