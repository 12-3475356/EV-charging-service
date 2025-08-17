import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EVProviderScreen extends StatefulWidget {
  const EVProviderScreen({super.key});

  @override
  State<EVProviderScreen> createState() => _EVProviderScreenState();
}

class _EVProviderScreenState extends State<EVProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedChargerType;
  String? selectedAvailableHours;
  bool agreeToTerms = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final providerData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'chargerType': selectedChargerType,
      'rate': _rateController.text,
      'availableHours': selectedAvailableHours,
    };

    try {
      final response = await http.post(
       Uri.parse("http://192.168.15.143:8081/api/person"), // for web
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(providerData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully!")),
        );
        _formKey.currentState?.reset();
        setState(() {
          selectedChargerType = null;
          selectedAvailableHours = null;
          agreeToTerms = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF706DC7),
        title: const Text(
          'Become a Provider',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormHeader(),
              const SizedBox(height: 24),
              _buildFormField('Full Name', controller: _nameController),
              const SizedBox(height: 16),
              _buildFormField(
                'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Enter valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildFormField(
                'Complete Address',
                controller: _addressController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                'Charger Type',
                ['Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'Tesla'],
                validator: (value) =>
                    value == null ? 'Please select charger type' : null,
                onChanged: (value) {
                  setState(() {
                    selectedChargerType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildFormField(
                'Charging Rate (₹/kWh)',
                controller: _rateController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter charging rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                'Available Hours',
                ['9AM-10AM', '4PM-8PM', '6PM-10PM', '24/7'],
                validator: (value) =>
                    value == null ? 'Please select available hours' : null,
                onChanged: (value) {
                  setState(() {
                    selectedAvailableHours = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildEarningInfo(),
              const SizedBox(height: 24),
              _buildAgreementCheckbox(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Applications are reviewed within 24-48 hours of submission',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 50, color: Color(0xFF706DC7)),
          const SizedBox(height: 16),
          const Text(
            'Start earning with your EV charger',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Share your home charger and earn money while helping the EV community',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options, {
    String? Function(String?)? validator,
    void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: options
              .map((value) =>
                  DropdownMenuItem<String>(value: value, child: Text(value)))
              .toList(),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEarningInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF706DC7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF706DC7).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Color(0xFF706DC7), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Earning Potential',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF706DC7))),
                const SizedBox(height: 4),
                Text(
                  'Average providers earn ₹3000 to ₹7000 per month by sharing their chargers 4-6 hours daily',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: agreeToTerms,
          onChanged: (value) {
            setState(() {
              agreeToTerms = value ?? false;
            });
          },
        ),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Provider Guidelines',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate() && agreeToTerms) {
            _submitForm();
          } else if (!agreeToTerms) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please agree to terms and conditions'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF706DC7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Submit Application',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}















































// /* with  backend 1 */
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class EVProviderScreen extends StatefulWidget {
//   const EVProviderScreen({super.key});

//   @override
//   State<EVProviderScreen> createState() => _EVProviderScreenState();
// }

// class _EVProviderScreenState extends State<EVProviderScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String? selectedChargerType;
//   String? selectedAvailableHours;
//   bool agreeToTerms = false;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _rateController = TextEditingController();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _rateController.dispose();
//     super.dispose();
//   }

//     Future<void> _submitForm() async {
//     final providerData = {
//       'name': _nameController.text,
//       'phone': _phoneController.text,
//       'address': _addressController.text,
//       'chargerType': selectedChargerType,
//       'rate': _rateController.text,
//       'availableHours': selectedAvailableHours,
//     };

//     try {
//       final response = await http.post(
//         Uri.parse("http://localhost:8081/api/person"), // Change to your backend URL
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(providerData),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Application submitted successfully!')),
//         );
//         _formKey.currentState?.reset();
//         setState(() {
//           selectedChargerType = null;
//           selectedAvailableHours = null;
//           agreeToTerms = false;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to submit: ${response.body}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }






//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF706DC7),
//         title: const Text(
//           'Become a Provider',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Column(
//                   children: [
//                     const Icon(
//                       Icons.lightbulb_outline,
//                       size: 50,
//                       color: Color(0xFF706DC7),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Start earning with your EV charger',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Share your home charger and earn money while helping the EV community',
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               _buildFormField('Full Name', controller: _nameController),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Phone Number',
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter phone number';
//                   }
//                   if (value.length < 10) {
//                     return 'Enter valid phone number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Complete Address',
//                 controller: _addressController,
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter address';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildDropdownField(
//                 'Charger Type',
//                 ['Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'Tesla'],
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select charger type';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     selectedChargerType = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Charging Rate (₹/kWh)',
//                 controller: _rateController,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter charging rate';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Enter valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildDropdownField(
//                 'Available Hours',
//                 ['9AM-10AM', '4PM-8PM', '6PM-10PM', '24/7'],
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select available hours';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     selectedAvailableHours = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 24),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF706DC7).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: const Color(0xFF706DC7).withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.attach_money,
//                       color: Color(0xFF706DC7),
//                       size: 24,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Earning Potential',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Color(0xFF706DC7),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Average providers earn ₹3000 to ₹7000 per month by sharing their chargers 4-6 hours daily',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Checkbox(
//                     value: agreeToTerms,
//                     onChanged: (value) {
//                       setState(() {
//                         agreeToTerms = value ?? false;
//                       });
//                     },
//                   ),
//                   const Expanded(
//                     child: Text.rich(
//                       TextSpan(
//                         children: [
//                           TextSpan(text: 'I agree to the '),
//                           TextSpan(
//                             text: 'Terms & Conditions',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                           TextSpan(text: ' and '),
//                           TextSpan(
//                             text: 'Provider Guidelines',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate() && agreeToTerms) {
//                       _submitForm();
//                     } else if (!agreeToTerms) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Please agree to terms and conditions'),
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF706DC7),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Submit Application',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Center(
//                 child: Text(
//                   'Applications are reviewed within 24-48 hours of submission',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFormField(
//     String label, {
//     TextEditingController? controller,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           validator: validator,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField(
//     String label,
//     List<String> options, {
//     String? Function(String?)? validator,
//     void Function(String?)? onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 12,
//             ),
//           ),
//           items: options.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value),
//             );
//           }).toList(),
//           validator: validator,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   void _submitForm() {
//     final providerData = {
//       'name': _nameController.text,
//       'phone': _phoneController.text,
//       'address': _addressController.text,
//       'chargerType': selectedChargerType,
//       'rate': _rateController.text,
//       'availableHours': selectedAvailableHours,
//     };

//     print('Form submitted: $providerData');

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Application submitted successfully!')),
//     );

//     _formKey.currentState?.reset();
//     setState(() {
//       selectedChargerType = null;
//       selectedAvailableHours = null;
//       agreeToTerms = false;
//     });
//   }
// }








































// /* without backend  */
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class EVProviderScreen extends StatefulWidget {
//   const EVProviderScreen({super.key});

//   @override
//   State<EVProviderScreen> createState() => _EVProviderScreenState();
// }

// class _EVProviderScreenState extends State<EVProviderScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String? selectedChargerType;
//   String? selectedAvailableHours;
//   bool agreeToTerms = false;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _rateController = TextEditingController();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _rateController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF706DC7),
//         title: const Text(
//           'Become a Provider',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Column(
//                   children: [
//                     const Icon(
//                       Icons.lightbulb_outline,
//                       size: 50,
//                       color: Color(0xFF706DC7),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Start earning with your EV charger',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Share your home charger and earn money while helping the EV community',
//                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               _buildFormField('Full Name', controller: _nameController),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Phone Number',
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter phone number';
//                   }
//                   if (value.length < 10) {
//                     return 'Enter valid phone number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Complete Address',
//                 controller: _addressController,
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter address';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildDropdownField(
//                 'Charger Type',
//                 ['Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'Tesla'],
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select charger type';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     selectedChargerType = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildFormField(
//                 'Charging Rate (₹/kWh)',
//                 controller: _rateController,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter charging rate';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Enter valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildDropdownField(
//                 'Available Hours',
//                 ['9AM-10AM', '4PM-8PM', '6PM-10PM', '24/7'],
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select available hours';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     selectedAvailableHours = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 24),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF706DC7).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: const Color(0xFF706DC7).withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.attach_money,
//                       color: Color(0xFF706DC7),
//                       size: 24,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Earning Potential',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Color(0xFF706DC7),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Average providers earn ₹3000 to ₹7000 per month by sharing their chargers 4-6 hours daily',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Checkbox(
//                     value: agreeToTerms,
//                     onChanged: (value) {
//                       setState(() {
//                         agreeToTerms = value ?? false;
//                       });
//                     },
//                   ),
//                   const Expanded(
//                     child: Text.rich(
//                       TextSpan(
//                         children: [
//                           TextSpan(text: 'I agree to the '),
//                           TextSpan(
//                             text: 'Terms & Conditions',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                           TextSpan(text: ' and '),
//                           TextSpan(
//                             text: 'Provider Guidelines',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate() && agreeToTerms) {
//                       _submitForm();
//                     } else if (!agreeToTerms) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Please agree to terms and conditions'),
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF706DC7),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Submit Application',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Center(
//                 child: Text(
//                   'Applications are reviewed within 24-48 hours of submission',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFormField(
//     String label, {
//     TextEditingController? controller,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           validator: validator,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField(
//     String label,
//     List<String> options, {
//     String? Function(String?)? validator,
//     void Function(String?)? onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 12,
//             ),
//           ),
//           items: options.map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value),
//             );
//           }).toList(),
//           validator: validator,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   void _submitForm() {
//     final providerData = {
//       'name': _nameController.text,
//       'phone': _phoneController.text,
//       'address': _addressController.text,
//       'chargerType': selectedChargerType,
//       'rate': _rateController.text,
//       'availableHours': selectedAvailableHours,
//     };

//     print('Form submitted: $providerData');

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Application submitted successfully!')),
//     );

//     _formKey.currentState?.reset();
//     setState(() {
//       selectedChargerType = null;
//       selectedAvailableHours = null;
//       agreeToTerms = false;
//     });
//   }
// }



// 