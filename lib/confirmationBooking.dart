import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mainpage.dart';
import 'paymentmethod.dart';

class ConfirmationBooking extends StatefulWidget {
  final String doctorName;
  final String date;
  final String time;
  final String userId;
  final String doctorId;

  const ConfirmationBooking({
    Key? key,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.userId,
    required this.doctorId,
  }) : super(key: key);

  @override
  State<ConfirmationBooking> createState() => _ConfirmationBookingState();
}

class _ConfirmationBookingState extends State<ConfirmationBooking> {
  final _nameController = TextEditingController();
  final _symptomController = TextEditingController();
  String? selectedAge;
  String? selectedGender;

  final List<String> ageRanges = [
    'under 18','18-25', '26-30', '31-40', '41-50', '51+'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation Booking"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(userId: widget.userId),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //doctor infor container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking With", 
                      style: TextStyle(
                        color: Colors.grey[700]
                      )
                    ),
                    SizedBox(height: 4),
                    Text(widget.doctorName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_alarm_rounded, size: 20, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text("${widget.date} at ${widget.time}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              
              //patient details container
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Patient Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 6),
                      child: Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 6),
                      child: Text("Age", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedAge,
                      hint: const Text("Select your age range"),
                      items: ageRanges
                          .map((age) => DropdownMenuItem(
                                value: age,
                                child: Text(age),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAge = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 6),
                      child: Text("Gender", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Male', 'Female'].map((gender) {
                        final isSelected = gender == selectedGender;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => selectedGender = gender);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey[400]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    gender,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 6),
                      child: Text("Describe Your Symptoms", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _symptomController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Describe your symptom",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
              //total price container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Price", style: TextStyle(fontSize: 16, color: Colors.green.shade700)),
                    Text("RM 50", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                  ],
                ),
              ),
              SizedBox(height: 15),
              //confirm booking button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final symptom = _symptomController.text.trim();
                        
                    if (name.isEmpty || selectedAge == null || selectedGender == null || symptom.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please complete all fields")),
                      );
                      return;
                    }
                        
                    try {
                      final bookingRef = await FirebaseFirestore.instance.collection('Appointments').add({
                        'name': name,
                        'age': selectedAge,
                        'gender': selectedGender,
                        'symptom': symptom,
                        'doctorName': widget.doctorName,
                        'doctorId': widget.doctorId,
                        'date': widget.date,
                        'time': widget.time,
                        'userId': widget.userId,
                        'price': 50,
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': 'upcoming',
                      });
                        
                      // Get the auto-generated document ID
                      final appointmentId = bookingRef.id;
                        
                      // Navigate to payment page with required data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodPage(
                            userId: widget.userId,
                            appointmentId: appointmentId,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to book: $e")),
                      );
                    }
                  },
                  icon: Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    "Confirm Booking", 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                    )
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
