import 'package:flutter/material.dart';
import 'add_card_details_screen.dart';
import '../../models/payment_method.dart';
import '../../services/data_service.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  String _selected = 'credit_card'; // 'credit_card' or 'nida'
  List<PaymentMethodDetails> _savedCards = [];
  bool _isLoadingCards = true;
  String? _selectedCardId; // ID of the currently selected card

  static const Color _brand = Color(0xFF0B2D5B);

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    if (!mounted) return;
    
    setState(() => _isLoadingCards = true);
    
    try {
      final cards = await DataService.getPaymentMethods().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Timeout loading payment methods');
          return <PaymentMethodDetails>[];
        },
      );
      
      if (!mounted) return;
      
      // Get selected payment method
      final selectedPaymentMethod = await DataService.getSelectedPaymentMethod();
      
      setState(() {
        _savedCards = cards.where((card) => card.type == 'credit_card').toList();
        _selectedCardId = selectedPaymentMethod?.id;
        _isLoadingCards = false;
      });
    } catch (e) {
      print('Error loading saved cards: $e');
      if (!mounted) return;
      setState(() {
        _savedCards = [];
        _isLoadingCards = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Payment Method',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Credit & Debit Card',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _optionTile(
                    id: 'credit_card',
                    icon: Icons.credit_card,
                    iconBackground: _brand.withOpacity(0.08),
                    iconColor: _brand,
                    title: 'Add New Card',
                  ),

                  // Saved Cards List
                  if (_isLoadingCards)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_savedCards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'No cards yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 16),
                    ..._savedCards.map((card) => _buildSavedCard(card)),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'More Payment Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _optionTile(
                    id: 'nida',
                    icon: Icons.badge_outlined,
                    iconBackground: Colors.black.withOpacity(0.06),
                    iconColor: Colors.black,
                    title: 'NIDA',
                  ),
                ],
              ),
            ),
          
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required String id,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
  }) {
    final bool selected = _selected == id;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? _brand : Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCardDetailsScreen(paymentType: id),
            ),
          );
          if (result == true) {
            await _loadSavedCards(); // Reload cards after adding new one
            // Don't pop - let user see the newly added card
          }
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildSavedCard(PaymentMethodDetails card) {
    final bool isSelected = _selectedCardId == card.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _brand : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.credit_card, color: _brand),
        ),
        title: Text(
          card.displayName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: card.cardHolderName != null
            ? Text(
                card.cardHolderName!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.isDefault)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 11,
                    color: _brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Radio<String>(
              value: card.id,
              groupValue: _selectedCardId,
              activeColor: _brand,
              onChanged: (String? value) async {
                if (value != null) {
                  setState(() => _selectedCardId = value);
                  // Set as selected payment method
                  await DataService.setSelectedPaymentMethod(value);
                }
              },
            ),
          ],
        ),
        onTap: () async {
          // Select this card
          setState(() => _selectedCardId = card.id);
          await DataService.setSelectedPaymentMethod(card.id);
        },
      ),
    );
  }
}


