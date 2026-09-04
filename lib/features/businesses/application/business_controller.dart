import 'package:flutter/foundation.dart';
import '../data/business_repository.dart';
import '../domain/business.dart';

enum BusinessState { initial, loading, hasBusiness, noBusiness, error }

class BusinessController extends ChangeNotifier {
  BusinessController({BusinessRepository? repository})
    : _repository = repository ?? BusinessRepository();

  final BusinessRepository _repository;

  BusinessState _state = BusinessState.initial;
  Business? _currentBusiness;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool _isDemoMode = false;

  BusinessState get state => _state;
  Business? get currentBusiness => _currentBusiness;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isDemoMode => _isDemoMode;

  /// Activates the in-memory isolated demo business mode for hackathon review.
  void loadDemoMode(Business demoBusiness) {
    _isDemoMode = true;
    _currentBusiness = demoBusiness;
    _state = BusinessState.hasBusiness;
    _errorMessage = null;
    notifyListeners();
  }

  /// Exits demo mode and resets to authenticated user state.
  void exitDemoMode() {
    _isDemoMode = false;
    _currentBusiness = null;
    _state = BusinessState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadUserBusiness() async {
    _isDemoMode = false;
    _state = BusinessState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final business = await _repository.getCurrentUserBusiness();
      if (business != null) {
        _currentBusiness = business;
        _state = BusinessState.hasBusiness;
      } else {
        _currentBusiness = null;
        _state = BusinessState.noBusiness;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = BusinessState.error;
    }
    notifyListeners();
  }

  Future<bool> createBusiness({
    required String name,
    required String industry,
    required String country,
    required String currency,
    required int fiscalYearStartMonth,
    required double startingCash,
  }) async {
    _isDemoMode = false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final business = await _repository.createBusiness(
        name: name,
        industry: industry,
        country: country,
        currency: currency,
        fiscalYearStartMonth: fiscalYearStartMonth,
        startingCash: startingCash,
      );
      _currentBusiness = business;
      _state = BusinessState.hasBusiness;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isDemoMode = false;
    _state = BusinessState.initial;
    _currentBusiness = null;
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
