import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'help.dart';
import 'mainpage.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Function to pick image from gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      uploadProfilePicture(image);
    }
  }

  // Function to upload image to Firebase Storage
  Future<void> uploadProfilePicture(XFile image) async {
    try {
      String fileName = path.basename(image.path);
      FirebaseStorage storage = FirebaseStorage.instance;

      // Create a reference to Firebase Storage location
      Reference storageRef = storage.ref().child('profile_pictures/$fileName');

      // Upload the image to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(File(image.path));

      // Get the download URL of the uploaded image
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      //store URL in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profile_picture': downloadUrl});

      setState(() {
        profileImageUrl = downloadUrl;  // Update the UI with the new image URL
      });

      showSnackBar("Profile picture updated successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
      showSnackBar("Failed to upload profile picture.");
    }
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          userData = data;
          profileImageUrl = data['profile_picture'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
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
                        .collection('users')
                        .doc(widget.userId)
                        .update({field: newValue});
                    setState(() {
                      if (field == 'first_name') {
                        userData?['first_name'] = newValue;
                      } else if (field == 'last_name') {
                        userData?['last_name'] = newValue;
                      } else if (field == 'phone_number'){
                        userData?['phone_number'] = newValue;
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

  Future<bool> isPhoneNumberDuplicate(String phoneNumber) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for duplicate phone number: $e");
      return false;
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
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['password'] == currentPassword) {
          // Update the password in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => AppointmentHistory(userId: widget.userId),
                //     ),
                //   );
                // },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.blue),
                title: Text('Favorite', style: TextStyle(color: Colors.blue)),
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
            TabBar(
              indicatorColor: Colors.blue,
              tabs: [
                Tab(child: Text("Profile", style: TextStyle(color: Colors.black))),
                Tab(child: Text("Body Details", style: TextStyle(color: Colors.black))),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl == null
                                ? Icon(Icons.person, color: Colors.black, size: 50)
                                : null,
                          ),
                        ),
                        SizedBox(height: 10),

                        Text(
                          userData?['username'] ?? "User's Name",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // First Name
                        buildEditableTextField('First Name', userData?['first_name'],(){
                          edit('first_name', userData?['first_name'] ?? '');
                        }),
                        const SizedBox(height: 10),

                        // Last Name
                        buildEditableTextField('Last Name', userData?['last_name'], () {
                          edit('last_name', userData?['last_name'] ?? '');
                        }),
                        const SizedBox(height: 10),

                        // Username
                        buildReadOnlyTextField('Username', userData?['username']),
                        const SizedBox(height: 10),

                        // Email
                        buildReadOnlyTextField('Email', userData?['email']),
                        const SizedBox(height: 10),

                        // Phone Number
                        buildEditableTextField('Phone Number', userData?['phone_number'], () {
                          edit('phone_number', userData?['phone_number'] ?? '');
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

                  // Body Details Tab
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Body Details",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
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
                      
