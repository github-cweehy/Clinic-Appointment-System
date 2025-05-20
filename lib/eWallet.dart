import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'mainpage.dart';
import 'paymentSuccess.dart';

class EWalletPaymentPage extends StatefulWidget {
  final String userId;
  final String appointmentId;
  final double price;

  EWalletPaymentPage({required this.appointmentId, required this.userId, required this.price});

  @override
  State<EWalletPaymentPage> createState() => _EWalletPaymentPageState();
}

class _EWalletPaymentPageState extends State<EWalletPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedEWallet; 

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEWalletTransactionToFirebase() async {
    try {
      CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
      QuerySnapshot snapshot = await transactions.where(FieldPath.documentId, isGreaterThanOrEqualTo: 'ew001').get();
      int idCounter = snapshot.size + 1;
      String transactionId = 'ew${idCounter.toString().padLeft(3, '0')}';

      await transactions.doc(transactionId).set({
        'userId': widget.userId,
        'phone': _phoneController.text,
        'selectedEWallet': _selectedEWallet,
        'amount': widget.price,
        'timestamp': FieldValue.serverTimestamp(),
        'paymentMethod': 'E-Wallet',
        'appointmentId': widget.appointmentId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-wallet transaction successful')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage(userId: widget.userId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-wallet transaction failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async{
              try {
                await FirebaseFirestore.instance
                  .collection('Appointments')
                  .doc(widget.appointmentId)
                  .delete();
                
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => MainPage(userId: widget.userId),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting data. Please try again.')),
                );
              }
            },
          ),
        title: Image.asset(
          'assets/cliniclogo.jpg', 
          height: 60,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'E-Wallet Payment',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Text(
                'Please enter your e-wallet details',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600]
                ),
              ),
              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedEWallet,
                        decoration: InputDecoration(
                          labelText: 'Select E-Wallet',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ["PayNet", "Boost", "Touch 'n Go", "GrabPay"]
                            .map((wallet) => DropdownMenuItem(
                                  value: wallet,
                                  child: Text(wallet),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedEWallet = value),
                        validator: (value) => value == null || value.isEmpty ? 'Please select an e-wallet' : null,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter your phone number';
                          if (!RegExp(r'^01\d{8,9}$').hasMatch(value))
                            return 'Phone number must start with 01 and be 10-11 digits';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: TextStyle(fontSize: 16, color: Colors.green[700])),
                    Text("RM ${widget.price.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
                  ],
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.monetization_on_outlined, color: Colors.white),
                  label: Text(
                    "Pay RM ${widget.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveEWalletTransactionToFirebase();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
