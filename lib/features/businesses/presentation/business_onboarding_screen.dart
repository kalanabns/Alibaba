import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/validators.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_primary_button.dart';
import '../../../shared/widgets/finora_text_field.dart';
import '../application/business_controller.dart';

class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key, required this.businessController});

  final BusinessController businessController;

  @override
  State<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _otherIndustryController = TextEditingController();
  final _startingCashController = TextEditingController(text: '0.00');

  static const List<String> _industries = [
    'Retail',
    'Restaurant / Food',
    'Professional Services',
    'Technology',
    'Manufacturing',
    'Construction',
    'Healthcare',
    'Education',
    'Transportation',
    'Agriculture',
    'E-commerce',
    'Hospitality',
    'Other',
  ];

  static const Map<String, String> _countryCurrencyMap = {
    'United States': 'USD',
    'India': 'INR',
    'United Kingdom': 'GBP',
    'Germany': 'EUR',
    'France': 'EUR',
    'Japan': 'JPY',
    'Australia': 'AUD',
    'Canada': 'CAD',
    'United Arab Emirates': 'AED',
    'Singapore': 'SGD',
    'Sri Lanka': 'LKR',
    'Other': 'USD',
  };

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'LKR',
    'AED',
    'SGD',
    'AUD',
    'CAD',
    'JPY',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _selectedIndustry = _industries.first;
  String _selectedCountry = 'United States';
  String _selectedCurrency = 'USD';
  String _selectedFiscalMonth = 'January';

  @override
  void dispose() {
    _nameController.dispose();
    _otherIndustryController.dispose();
    _startingCashController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null) return;
    setState(() {
      _selectedCountry = newCountry;
      if (_countryCurrencyMap.containsKey(newCountry)) {
        _selectedCurrency = _countryCurrencyMap[newCountry]!;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final finalIndustry = _selectedIndustry == 'Other'
        ? (_otherIndustryController.text.trim().isNotEmpty
              ? _otherIndustryController.text.trim()
              : 'Other')
        : _selectedIndustry;

    final monthInt = Validators.monthNameToInteger(_selectedFiscalMonth);
    final startingCash = Validators.parseStartingCash(
      _startingCashController.text,
    );

    await widget.businessController.createBusiness(
      name: _nameController.text.trim(),
      industry: finalIndustry,
      country: _selectedCountry,
      currency: _selectedCurrency,
      fiscalYearStartMonth: monthInt,
      startingCash: startingCash,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
            border: Border(
              bottom: BorderSide(color: Color(0x3338BDF8), width: 1.2),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Set Up Your Business Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: ListenableBuilder(
                listenable: widget.businessController,
                builder: (context, _) {
                  final isSubmitting = widget.businessController.isSubmitting;
                  final errorMessage = widget.businessController.errorMessage;

                  return Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.store_rounded,
                                  color: AppTheme.primaryLight,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Establish Business Workspace',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Provide baseline parameters for your financial engine.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (errorMessage != null) ...[
                            FinoraErrorView(message: errorMessage),
                            const SizedBox(height: 16),
                          ],
                          FinoraTextField(
                            controller: _nameController,
                            label: 'Business Name',
                            hint: 'e.g. Apex Global Trade',
                            prefixIcon: Icons.business_outlined,
                            enabled: !isSubmitting,
                            validator: (val) => Validators.validateRequired(
                              val,
                              'Business name',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedIndustry,
                            decoration: const InputDecoration(
                              labelText: 'Industry Sector',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _industries
                                .map(
                                  (ind) => DropdownMenuItem(
                                    value: ind,
                                    child: Text(ind),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _selectedIndustry = val);
                                    }
                                  },
                          ),
                          if (_selectedIndustry == 'Other') ...[
                            const SizedBox(height: 16),
                            FinoraTextField(
                              controller: _otherIndustryController,
                              label: 'Specify Industry',
                              hint: 'e.g. Clean Energy Tech',
                              enabled: !isSubmitting,
                              validator: (val) =>
                                  Validators.validateRequired(val, 'Industry'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCountry,
                            decoration: const InputDecoration(
                              labelText: 'Operating Country',
                              prefixIcon: Icon(Icons.public_outlined),
                            ),
                            items: _countryCurrencyMap.keys
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting ? null : _onCountryChanged,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Base Currency (ISO)',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                            items: _currencies
                                .map(
                                  (cur) => DropdownMenuItem(
                                    value: cur,
                                    child: Text(cur),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _selectedCurrency = val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFiscalMonth,
                            decoration: const InputDecoration(
                              labelText: 'Fiscal Year Start Month',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            items: _months
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(
                                        () => _selectedFiscalMonth = val,
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          FinoraTextField(
                            controller: _startingCashController,
                            label: 'Starting Cash Balance',
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Icons.account_balance_outlined,
                            enabled: !isSubmitting,
                            validator: Validators.validateStartingCash,
                          ),
                          const SizedBox(height: 28),
                          FinoraPrimaryButton(
                            text: 'Create Business & Launch Dashboard',
                            isLoading: isSubmitting,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
