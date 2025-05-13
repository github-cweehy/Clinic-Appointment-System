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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add your payment information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              //Bank Name
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
                      )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value;
                  });
                },
                validator: (value){
                  if(value == null || value.isEmpty){
                    return 'Please select a bank';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              //Account Number
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
                validator: (value){
                  if (value == null || value.isEmpty) {
                    return 'Please enter your account number';
                  }
                  if ( _selectedBank == 'Public Bank' && value.length != 10) {
                    return 'Public Bank account number must be 10 digits';
                  }
                  if (_selectedBank == 'CIMB Bank' && value.length != 12) {
                    return 'CIMB Bank account number must be 12 digits';
                  }
                  if (_selectedBank == 'Maybank' && value.length != 12) {
                    return 'CIMB Bank account number must be 12 digits';
                  }
                  if (_selectedBank == 'OCBC Bank' && value.length != 10) {
                    return 'CIMB Bank account number must be 12 digits';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Account number must contain only digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              //Account Name
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Holder Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )
                ),
                validator: (value){
                  if (value == null || value.isEmpty) {
                    return 'Please enter your account holder name';
                  }
                  else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'Name can only contain letters and spaces';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Confirm Payment button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (){
                    if (_formKey.currentState!.validate()) {
                      _saveTransactionToFirebase();
                    }
                  },
                  child: Text(
                    'Confirm Payment : RM ${widget.price}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ]
          )
        )
      )
    );
  }
}
