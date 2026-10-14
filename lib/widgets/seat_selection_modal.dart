import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class SeatSelectionModal extends StatefulWidget {
  final int initialSeats;
  final Function(int) onSeatSelected;

  const SeatSelectionModal({
    Key? key,
    this.initialSeats = 1,
    required this.onSeatSelected,
  }) : super(key: key);

  @override
  State<SeatSelectionModal> createState() => _SeatSelectionModalState();
}

class _SeatSelectionModalState extends State<SeatSelectionModal> {
  late int _selectedSeats;

  @override
  void initState() {
    super.initState();
    _selectedSeats = widget.initialSeats;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Car image with seat visualization
          SizedBox(
            width: 400,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Car image
                Image.asset(
                  'assets/images/Suv car.png',
                  width: 150,
                  height: 100,
                  fit: BoxFit.contain,
                ),

                // Seats highlight overlay
                // This is a simplified visual representation
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Number of seats text
          const Text(
            'Number of Seats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // Seat selection options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final seatNumber = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeats = seatNumber;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          _selectedSeats == seatNumber
                              ? const Color(0xFF777777)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        seatNumber.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              _selectedSeats == seatNumber
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Note about seat position
          const Text(
            '* Selection is not for seat position',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onSeatSelected(_selectedSeats);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
