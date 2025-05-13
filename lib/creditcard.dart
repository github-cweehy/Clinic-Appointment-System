import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mainpage.dart';
import 'paymentSuccess.dart';

class CardPaymentPage extends StatefulWidget {
  final String userId;
  final String appointmentId;
  final double price;

  CardPaymentPage({required this.appointmentId, required this.userId, required this.price});

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardHolderNameController = TextEditingController(); 


  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _cardHolderNameController.dispose(); 
    super.dispose();
  }

  Future<void> _saveTransactionToFirebase() async {
  try {
    // Generate unique ID for card payments (e.g., cp001, cp002, etc.)
    CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
    QuerySnapshot snapshot = await transactions.where(FieldPath.documentId, isGreaterThanOrEqualTo: 'cp001').get();
    int idCounter = snapshot.size + 1;
    String transactionId = 'cp${idCounter.toString().padLeft(3, '0')}';

    await transactions.doc(transactionId).set({
      'userId': widget.userId,
      'cardHolderName': _cardHolderNameController.text,
      'cardNumber': _cardNumberController.text,
      'expiryDate': _expiryDateController.text,
      'cvc': _cvcController.text,
      'amount': widget.price, 
      'appointmentId': widget.appointmentId,
      'timestamp': FieldValue.serverTimestamp(),
      'paymentMethod': 'Card',
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


  //card number : 16-19 digits
  bool _validateCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
    if (!RegExp(r'^\d+$').hasMatch(cardNumber)) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber .length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  bool _validateExpiryDate(String value) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) return false;

    final components = value.split('/');
    final int month = int.parse(components[0]);
    final int year = int.parse('20${components[1]}');
    final now = DateTime.now();

    final expiryDate = DateTime(year, month);
    return expiryDate.isAfter(now);
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
                  SnackBar(content: Text('Error deleting data. Please try again.')) ,
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

              // Card Name
              TextFormField(
                controller: _cardHolderNameController, 
                decoration: InputDecoration(
                  labelText: 'Name on Card',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name on the card';
                  }
                  else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'Name can only contain letters and spaces';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Card Number Input
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                  CardNumberInputFormatter(), 
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your card number';
                  } else if (!_validateCardNumber(value)) {
                    return 'Invalid card number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Expiry Date Input
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date (MM/YY)',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the expiry date';
                  }
                  if (!_validateExpiryDate(value)) {
                    return 'Invalid expiry date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // CVC Input
              TextFormField(
                controller: _cvcController,
                decoration: InputDecoration(
                  labelText: 'CVC',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the CVC';
                  }
                  if (value.length != 3 && value.length != 4) {
                    return 'Invalid CVC';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
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
                  onPressed: () {
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
            ],
          ),
        ),
      ),
    );
  }
}

// Custom input formatter for formatting card number input
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
