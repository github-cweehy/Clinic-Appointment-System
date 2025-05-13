import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'eWallet.dart';
import 'onlinebanking.dart';
import 'creditcard.dart';
import 'mainpage.dart';

class PaymentMethodPage extends StatefulWidget {
  final String userId;
  final String appointmentId;

  PaymentMethodPage({
    required this.appointmentId,
    required this.userId,
  });

  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {

  Future<void> confirmPayment(String method, Widget paymentPage) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('Appointments')
          .doc(widget.appointmentId);

      await docRef.update({
        'payment method': method,
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => paymentPage));
    } catch (e) {
      print("Error confirming payment: $e");
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
          onPressed: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('Appointments')
                  .doc(widget.appointmentId)
                  .delete();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage(userId: widget.userId)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error cancelling appointment.')),
              );
            }
          },
        ),
        title: Image.asset('assets/cliniclogo.jpg', height: 60),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Your Payment Method",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Select how you'd like to pay for your appointment.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),

            buildPaymentCard(
              method: 'Card Payment',
              icon: Icons.credit_card,
              onTap: () => confirmPayment(
                'Card Payment',
                CardPaymentPage(
                  appointmentId: widget.appointmentId,
                  price: 50.0,
                  userId: widget.userId,
                ),
              ),
            ),
            buildPaymentCard(
              method: 'Online Banking',
              icon: Icons.account_balance,
              onTap: () => confirmPayment(
                'Online Banking',
                OnlineBankingPage(
                  appointmentId: widget.appointmentId,
                  price: 50.0,
                  userId: widget.userId,
                ),
              ),
            ),
            buildPaymentCard(
              method: 'E-wallet',
              icon: Icons.phone_android,
              onTap: () => confirmPayment(
                'E-wallet',
                EWalletPaymentPage(
                  appointmentId: widget.appointmentId,
                  price: 50.0,
                  userId: widget.userId,
                ),
              ),
            ),

            SizedBox(height: 60),

            CancelButton(
              userId: widget.userId,
              appointmentId: widget.appointmentId,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentCard({required String method, required IconData icon, required VoidCallback onTap,}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                method,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final String appointmentId;
  final String userId;

  CancelButton({required this.appointmentId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.red.shade300),
      ),
      icon: Icon(Icons.cancel_outlined, color: Colors.red),
      label: Text(
        'Cancel Payment',
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
      onPressed: () async {
        try {
          await FirebaseFirestore.instance
              .collection('Appointments')
              .doc(appointmentId)
              .delete();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
          );
        } catch (e) {
          print("Error canceling appointment: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel appointment.')),
          );
        } 
      }),
    );
  }
}
