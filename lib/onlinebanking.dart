import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mainpage.dart';
import 'paymentSuccess.dart';

class OnlineBankingPage extends StatefulWidget {
  final String userId;
  final String appointmentId;
  final double price;


  OnlineBankingPage({required this.appointmentId, required this.userId, required this.price});

  @override
  State<OnlineBankingPage> createState() => _OnlineBankingPageState();
}

class _OnlineBankingPageState extends State<OnlineBankingPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBank; 
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  Future<void> _saveTransactionToFirebase() async {
  try {
    // Generate unique ID 
    CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
    QuerySnapshot snapshot = await transactions.where(FieldPath.documentId, isGreaterThanOrEqualTo: 'cp001').get();
    int idCounter = snapshot.size + 1;
    String transactionId = 'ob${idCounter.toString().padLeft(3, '0')}';

    await transactions.doc(transactionId).set({
      'userId': widget.userId,
      'bankName': _bankNameController.text,
      'accountNumber': _accountNumberController.text,
      'accountNameHolder': _accountNameController.text,
      'amount': widget.price,
      'timestamp': FieldValue.serverTimestamp(),
      'paymentMethod': 'Online Banking',
      'appointmentId': widget.appointmentId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction successfully')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentSuccessPage(userId: widget.userId)));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction failed')),
    );}
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
                  Icon(Icons.account_balance, color: Colors.blue, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Online Banking Payment',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Text(
                'Please enter your online-banking details',
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
                        value: _selectedBank,
                        decoration: InputDecoration(
                          labelText: 'Select Bank',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['Public Bank', 'CIMB Bank', 'Maybank', 'OCBC Bank']
                            .map((bank) => DropdownMenuItem<String>(
                                  value: bank,
                                  child: Text(bank),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedBank = value),
                        validator: (value) => value == null || value.isEmpty ? 'Please select a bank' : null,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your account number';
                          if (!RegExp(r'^\d+$').hasMatch(value)) return 'Account number must contain only digits';

                          if (_selectedBank == 'Public Bank' && value.length != 10)
                            return 'Public Bank account number must be 10 digits';
                          if ((_selectedBank == 'CIMB Bank' || _selectedBank == 'Maybank') && value.length != 12)
                            return '${_selectedBank} account number must be 12 digits';
                          if (_selectedBank == 'OCBC Bank' && value.length != 10)
                            return 'OCBC account number must be 10 digits';

                          return null;
                        }
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _accountNameController,
                        decoration: InputDecoration(
                          labelText: 'Account Holder Name',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter account holder name';
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Name can only contain letters and spaces';
                          }
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
                      _saveTransactionToFirebase();
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
