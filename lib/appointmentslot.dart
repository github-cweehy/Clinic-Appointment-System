import 'package:table_calendar/table_calendar.dart';
import 'confirmationBooking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'mainpage.dart';

class Appointmentslot extends StatefulWidget{
  final String userId;
  final String doctorName;
  final String doctorId;

  Appointmentslot({required this.userId, required this.doctorName, required this.doctorId});

  @override
  AppointmentslotState createState() => AppointmentslotState();
}

class AppointmentslotState extends State <Appointmentslot> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<String> bookedSlots = []; 

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  final List<String> allSlots = [
    '10:00 AM', '11:00 AM', '12:00 PM',
    '03:00 PM', '04:00 PM', '05:00 PM',
    '08:00 PM', '09:00 PM', '10:00 PM'
  ];
  String? selectedSlot;

  Future<void> fetchBookedSlotsForDate(DateTime date) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final snapshot = await firestore
        .collection('Appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: formattedDate)
        .where('status', isEqualTo: 'upcoming') // adjust if needed
        .get();

    final slots = snapshot.docs.map((doc) => doc['time']).toList().cast<String>();

    setState(() {
      bookedSlots = slots;
    });
  }

  @override
  Widget build (BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(userId: widget.userId),
              ),
            );
          },
        ),
        title: Image.asset(
          'assets/cliniclogo.jpg',
          height: 60,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking with", style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text(widget.doctorName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 6),
              child: Text(
                'Select a Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 60)),
              focusedDay: focusedDay,
              calendarFormat: CalendarFormat.month,

              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
                fetchBookedSlotsForDate(selected);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (selectedDay != null) ...[
              SizedBox(height: 16),
              Text(
                'Select a Time Slot',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allSlots.map((slot) {
                    final isBooked = bookedSlots.contains(slot);
                    final isSelected = slot == selectedSlot;
                
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: isBooked ? null : (_) {
                        setState(() => selectedSlot = slot);
                      },
                      selectedColor: Colors.blue,
                      disabledColor: Colors.grey.shade400,
                      labelStyle: TextStyle(
                        color: isBooked 
                            ? Colors.white 
                            : (isSelected ? Colors.white : Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]
            else
              SizedBox(height: 5),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top:16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedSlot == null ? null : () async {
                      try {
                        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
                        final String formattedDate = dateFormatter.format(selectedDate);
                        final String slotToSend = selectedSlot!;
                
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ConfirmationBooking(
                              doctorName: widget.doctorName,
                              date: formattedDate, 
                              time: slotToSend,
                              userId: widget.userId,
                              doctorId: widget.doctorId,
                            ),
                          ),
                        );
                
                        setState(() {
                          selectedSlot = null;
                        });
                
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error booking appointment: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Set Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

