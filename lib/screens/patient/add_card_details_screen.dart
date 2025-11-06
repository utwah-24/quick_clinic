import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_method.dart';
import '../../services/data_service.dart';

class AddCardDetailsScreen extends StatefulWidget {
  final String paymentType; // 'credit_card' or 'nida'

  const AddCardDetailsScreen({super.key, required this.paymentType});

  @override
  State<AddCardDetailsScreen> createState() => _AddCardDetailsScreenState();
}

class _AddCardDetailsScreenState extends State<AddCardDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nidaController = TextEditingController();
  
  String? _selectedBank;

  static const Color _brand = Color(0xFF0B2D5B);

  // List of major banks in Tanzania
  static const List<String> _tanzanianBanks = [
    'CRDB Bank',
    'NMB Bank',
    'ABSA Bank Tanzania',
    'SELCOM',
    'National Bank of Commerce (NBC)',
    'Bank of Africa Tanzania',
    'Azania Bank',
    'Exim Bank Tanzania',
    "People's Bank of Zanzibar",
    'TPB Bank',
    'Akiba Commercial Bank',
    'Mwalimu Commercial Bank',
    'Bank M (Tanzania)',
    'UBL Bank',
    'KCB Bank Tanzania',
    'Equity Bank Tanzania',
    'Stanbic Bank Tanzania',
    'Standard Chartered Bank Tanzania',
    'Diamond Trust Bank',
    'I&M Bank Tanzania',
    'BancABC Tanzania',
    'Access Bank Tanzania',
    'Ecobank Tanzania',
    'Tanzania Postal Bank',
    'DCB Commercial Bank',
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nidaController.dispose();
    super.dispose();
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    if (value.replaceAll(' ', '').length < 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Format: MM/YY';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length < 3) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  String? _validateNIDA(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter NIDA number';
    }
    return null;
  }

  String? _validateBank(String? value) {
    // Only validate bank for credit card, not for NIDA
    if (widget.paymentType != 'nida') {
      if (value == null || value.isEmpty) {
        return 'Please select a bank';
      }
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create payment method details
        final paymentMethod = PaymentMethodDetails(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.paymentType,
          bankName: widget.paymentType == 'credit_card' ? _selectedBank : null,
          cardNumber: widget.paymentType == 'credit_card' 
              ? _cardNumberController.text.replaceAll(' ', '') 
              : null,
          cardHolderName: widget.paymentType == 'credit_card' 
              ? _cardHolderController.text 
              : null,
          expiryDate: widget.paymentType == 'credit_card' 
              ? _expiryController.text 
              : null,
          cvv: widget.paymentType == 'credit_card' 
              ? _cvvController.text 
              : null,
          nidaNumber: widget.paymentType == 'nida' 
              ? _nidaController.text 
              : null,
          createdAt: DateTime.now(),
          isDefault: true, // Set as default payment method
        );

        // Save payment method
        await DataService.savePaymentMethod(paymentMethod);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving payment method: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNIDA = widget.paymentType == 'nida';

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
        title: Text(
          isNIDA ? 'Add NIDA' : 'Add Card Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isNIDA) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/illustrations/Health_insurance_card .png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      // errorBuilder: (context, error, stackTrace) {
                      //   print('Error loading image: $error');
                      //   return Container(
                      //     height: 200,
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey[100],
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Icon(Icons.health_and_safety, size: 64, color: Colors.grey[400]),
                      //         const SizedBox(height: 8),
                      //         Text(
                      //           'Health Insurance Card',
                      //           style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      //         ),
                      //       ],
                      //     ),
                      //   );
                      // },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nidaController,
                  decoration: InputDecoration(
                    labelText: 'NIDA Number',
                    hintText: 'Enter your NIDA number',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brand, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateNIDA,
                ),
              ] else ...[
                const SizedBox(height: 24),
                // Card Preview
                // Container(
                //   height: 200,
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [_brand, _brand.withOpacity(0.8)],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   padding: const EdgeInsets.all(20),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           const Icon(Icons.credit_card, color: Colors.white, size: 32),
                //           Text(
                //             'VISA',
                //             style: TextStyle(
                //               color: Colors.white.withOpacity(0.9),
                //               fontSize: 24,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             _cardNumberController.text.isEmpty
                //                 ? 'XXXX XXXX XXXX XXXX'
                //                 : _cardNumberController.text,
                //             style: const TextStyle(
                //               color: Colors.white,
                //               fontSize: 20,
                //               fontWeight: FontWeight.w600,
                //               letterSpacing: 2,
                //             ),
                //           ),
                //           const SizedBox(height: 20),
                //           Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             children: [
                //               Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     'CARD HOLDER',
                //                     style: TextStyle(
                //                       color: Colors.white.withOpacity(0.7),
                //                       fontSize: 10,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 4),
                //                   Text(
                //                     _cardHolderController.text.isEmpty
                //                         ? 'YOUR NAME'
                //                         : _cardHolderController.text.toUpperCase(),
                //                     style: const TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 14,
                //                       fontWeight: FontWeight.w600,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //               Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     'EXPIRES',
                //                     style: TextStyle(
                //                       color: Colors.white.withOpacity(0.7),
                //                       fontSize: 10,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 4),
                //                   Text(
                //                     _expiryController.text.isEmpty
                //                         ? 'MM/YY'
                //                         : _expiryController.text,
                //                     style: const TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 14,
                //                       fontWeight: FontWeight.w600,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ],
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                
                Center(
                  child: Image.asset(
                    'assets/illustrations/add_card_details.png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Card Illustration',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                // Bank Selection Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: InputDecoration(
                    labelText: 'Select Bank',
                    hintText: 'Choose your bank',
                    prefixIcon: const Icon(Icons.account_balance),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brand, width: 2),
                    ),
                  ),
                  items: _tanzanianBanks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBank = newValue;
                    });
                  },
                  validator: _validateBank,
                ),
                const SizedBox(height: 16),
                // Card Number
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brand, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberFormatter(),
                  ],
                  validator: _validateCardNumber,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Card Holder Name
                TextFormField(
                  controller: _cardHolderController,
                  decoration: InputDecoration(
                    labelText: 'Cardholder Name',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brand, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cardholder name';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Expiry and CVV Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'MM/YY',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _brand, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          ExpiryDateFormatter(),
                        ],
                        validator: _validateExpiry,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _brand, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: _validateCVV,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSubmit,
                  child: const Text(
                    'Add Payment Method',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom formatter for card number (adds spaces every 4 digits)
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom formatter for expiry date (MM/YY format)
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 && text.length > 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

