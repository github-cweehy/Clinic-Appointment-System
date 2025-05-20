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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(userId: widget.userId),
      ),
      (route) => false,
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Card Payment',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Text(
                'Please enter your card details',
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
                      _buildTextField(_cardHolderNameController, 'Name on Card', TextInputType.text),
                      _buildTextField(_cardNumberController, 'Card Number', TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          CardNumberInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter card number';
                          if (!_validateCardNumber(value)) return 'Invalid card number';
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_expiryDateController, 'Expiry Date (MM/YY)', TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter expiry date';
                                if (!_validateExpiryDate(value)) return 'Invalid expiry date';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_cvcController, 'CVC', TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter CVC';
                                if (value.length != 3 && value.length != 4) return 'Invalid CVC';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              _buildPriceSummary(),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.monetization_on_outlined, color: Colors.white),
                  label: Text(
                    'Pay RM ${widget.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type, {
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Total", style: TextStyle(fontSize: 16, color: Colors.green[700])),
          Text("RM ${widget.price.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
        ],
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
