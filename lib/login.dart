import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adminMainPage.dart';
import 'mainpage.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  const LoginPage({Key? key, this.superadminId, this.adminId}): super(key: key);
  
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Search in 'admins' collection 
      QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .where('admin_username', isEqualTo: username)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        var adminDoc = adminSnapshot.docs[0];
        String storedPassword = adminDoc['password'];
        String adminId = adminDoc.id;

        if (storedPassword == password) {
          // Navigate to the admin page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMainPage(adminId: adminId),
            ),
          );
          return; 
        } else {
          _showErrorDialog('Incorrect password');
          return;
        }
      }

      // Search in 'users' collection
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userDoc = userSnapshot.docs[0];
        String storedPassword = userDoc['password'];
        String userId = userDoc.id; 

        if (storedPassword == password) {
          // Navigate to the main page 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(userId: userId),
            ),
          );
        } else {
          // Show error if password is incorrect
          _showErrorDialog('Incorrect password');
        }
      } else {
        // Show error if username is not found
        _showErrorDialog('Account not found');
      }
    } catch (e) {
      // Show error for any other issues
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void showPasswordChangeDialog(){
    TextEditingController newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
          title: Text('Forgot Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value){
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: newPasswordController,
                  obscureText: isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your new password';
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
                    String username = _usernameController.text.trim();
                    String newPassword = newPasswordController.text.trim();
                    bool updated = false;

                    try {
                      QuerySnapshot userSnapshot = await _firestore
                          .collection('users')
                          .where('username', isEqualTo: username)
                          .get();

                      if (userSnapshot.docs.isNotEmpty) {
                        String userId = userSnapshot.docs[0].id;
                        await _firestore
                            .collection('users')
                            .doc(userId)
                            .update({'password': newPassword});
                          updated = true;
                        Navigator.pop(context);
                        _showSnackBar('Password updated successfully!');
                      }
                    } catch (e) {
                      _showSnackBar('Error: ${e.toString()}');
                    }

                    try {
                      QuerySnapshot userSnapshot = await _firestore
                          .collection('admin')
                          .where('username', isEqualTo: username)
                          .get();

                      if (userSnapshot.docs.isNotEmpty) {
                        String userId = userSnapshot.docs[0].id;
                        await _firestore
                            .collection('admins')
                            .doc(userId)
                            .update({'password': newPassword});
                        Navigator.pop(context);
                        _showSnackBar('Password updated successfully!');
                      }
                    } catch (e) {
                      _showSnackBar('Error: ${e.toString()}');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/cliniclogo.jpg',
                  height: 150,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Good Health',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter username and password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: (){
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    showPasswordChangeDialog();
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: const Text(
                        'Sign up here',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
