import 'dart:math';
import 'package:flutter/material.dart';

class ChangeOfferCard extends StatefulWidget {
  final int recommendedFare;
  final Widget? innerContent;
  final VoidCallback? onBack;
  final Function(int)? onSendOffer;
  final Function(int)? onFareChanged;
  final bool showBackButton;
  final bool showSendOfferButton;
  final bool isNegotiation;
  final TextEditingController? messageController;

  const ChangeOfferCard({
    Key? key,
    required this.recommendedFare,
    this.innerContent,
    this.onBack,
    this.onSendOffer,
    this.onFareChanged,
    this.showBackButton = true,
    this.showSendOfferButton = true,
    this.isNegotiation = false,
    this.messageController,
  }) : super(key: key);

  @override
  State<ChangeOfferCard> createState() => _ChangeOfferCardState();
}

class _ChangeOfferCardState extends State<ChangeOfferCard>
    with TickerProviderStateMixin {
  late int _currentFare;
  late int _maxFare;
  late int _minFare;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Quick message options for negotiation
  final List<String> _quickMessages = [
    'Final offer',
    'My best price',
    'Let\'s agree',
  ];

  int get currentFare => _currentFare;

  @override
  void initState() {
    super.initState();
    _initializeFare();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  void _initializeFare() {
    _currentFare = widget.recommendedFare;
    _maxFare = (widget.recommendedFare * 1.15).toInt(); // 15% above recommended
    _minFare = (widget.recommendedFare * 0.85).toInt(); // 15% below recommended
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFareChanged?.call(_currentFare);
    });
  }

  @override
  void didUpdateWidget(ChangeOfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendedFare != widget.recommendedFare) {
      _initializeFare();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _increaseFare() {
    if (_currentFare < _maxFare) {
      setState(() {
        _currentFare = min(_maxFare, _currentFare + 10);
      });
      widget.onFareChanged?.call(_currentFare);
    }
  }

  void _decreaseFare() {
    if (_currentFare > _minFare) {
      setState(() {
        _currentFare = max(_minFare, _currentFare - 10);
      });
      widget.onFareChanged?.call(_currentFare);
    }
  }

  bool get _canIncrease => _currentFare < _maxFare;
  bool get _canDecrease => _currentFare > _minFare;

  void _handleBack() {
    if (widget.onBack != null) {
      _slideController.reverse().then((_) {
        widget.onBack!();
      });
    }
  }

  void _handleSendOffer() {
    if (widget.onSendOffer != null) {
      widget.onSendOffer!(_currentFare);
      if (!widget.isNegotiation) {
        _handleBack();
      }
    }
  }

  void _onQuickMessageTap(String message) {
    if (widget.messageController != null) {
      widget.messageController!.text = message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showBackButton) _buildHeader(),
            _buildMainCard(),
            if (widget.isNegotiation) _buildQuickMessages(),
            if (widget.showSendOfferButton) _buildSendOfferButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 4),
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Change Offer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          // Inner content (existing or negotiation message input)
          if (widget.innerContent != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: widget.innerContent!,
            ),
            const SizedBox(height: 6),
          ] else if (widget.isNegotiation &&
              widget.messageController != null) ...[
            // Message input for negotiation mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.messageController,
                      decoration: const InputDecoration(
                        hintText: 'Add a message',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, color: Colors.grey[500], size: 18),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Fare adjustment section
          Row(
            children: [
              // Minus button
              GestureDetector(
                onTap: _canDecrease ? _decreaseFare : null,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        _canDecrease
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _canDecrease ? Colors.red : Colors.grey[500],
                    size: 20,
                  ),
                ),
              ),

              // Fare display
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '₹${_currentFare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Plus button
              GestureDetector(
                onTap: _canIncrease ? _increaseFare : null,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        _canIncrease
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _canIncrease ? Colors.green : Colors.grey[500],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Recommended fare: ₹${widget.recommendedFare.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessages() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _quickMessages.map((message) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onQuickMessageTap(message),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSendOfferButton() {
    return Container(
      padding: const EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _handleSendOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Send Offer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
