import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  TransactionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Transaction>> getTransactions({
    required String businessId,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select()
          .eq('business_id', businessId);

      if (type != null) {
        query = query.eq('transaction_type', type.name);
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim();
        query = query.or(
          'description.ilike.%$term%,merchant_name.ilike.%$term%,category.ilike.%$term%',
        );
      }

      final response = await query
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Database query error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load transactions. Please try again.');
    }
  }

  Future<List<Transaction>> getRecentTransactions({
    required String businessId,
    int limit = 5,
  }) async {
    return getTransactions(businessId: businessId, limit: limit);
  }

  Future<Transaction> createTransaction({
    required String businessId,
    required DateTime transactionDate,
    required TransactionType transactionType,
    required String category,
    required double amount,
    String? subcategory,
    String currency = 'USD',
    String? description,
    String? merchantName,
    String? customerName,
    String? supplierName,
    PaymentStatus paymentStatus = PaymentStatus.unknown,
    TransactionSource source = TransactionSource.manual,
    String? externalReference,
    String? rawText,
  }) async {
    try {
      final response = await _client
          .from('transactions')
          .insert({
            'business_id': businessId,
            'transaction_date': transactionDate.toIso8601String(),
            'transaction_type': transactionType.name,
            'category': category.trim(),
            'subcategory': subcategory?.trim(),
            'amount': amount,
            'currency': currency.trim().toUpperCase(),
            'description': description?.trim(),
            'merchant_name': merchantName?.trim(),
            'customer_name': customerName?.trim(),
            'supplier_name': supplierName?.trim(),
            'payment_status': paymentStatus.name,
            'source': source.name,
            'external_reference': externalReference?.trim(),
            'raw_text': rawText,
          })
          .select()
          .single();

      return Transaction.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save transaction: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while saving transaction.');
    }
  }

  /// Inserts batch of transactions with chunking for performance & reliability.
  Future<int> createTransactionsBatch({
    required String businessId,
    required List<Transaction> transactions,
    int chunkSize = 50,
  }) async {
    if (transactions.isEmpty) return 0;

    int totalInserted = 0;
    for (int i = 0; i < transactions.length; i += chunkSize) {
      final chunk = transactions.sublist(
        i,
        i + chunkSize > transactions.length
            ? transactions.length
            : i + chunkSize,
      );

      final payload = chunk.map((t) {
        return {
          'business_id': businessId,
          'transaction_date': t.transactionDate.toIso8601String(),
          'transaction_type': t.transactionType.name,
          'category': t.category,
          'subcategory': t.subcategory,
          'amount': t.amount,
          'currency': t.currency,
          'description': t.description,
          'merchant_name': t.merchantName,
          'customer_name': t.customerName,
          'supplier_name': t.supplierName,
          'payment_status': t.paymentStatus.name,
          'source': t.source.name,
          'external_reference': t.externalReference,
          'raw_text': t.rawText,
        };
      }).toList();

      try {
        await _client.from('transactions').insert(payload);
        totalInserted += chunk.length;
      } on PostgrestException catch (e) {
        throw Exception(
          'Failed to import transaction batch at row $i: ${e.message}',
        );
      } catch (e) {
        throw Exception('Unexpected error during batch import: $e');
      }
    }

    return totalInserted;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final response = await _client
          .from('transactions')
          .update({
            'transaction_date': transaction.transactionDate.toIso8601String(),
            'transaction_type': transaction.transactionType.name,
            'category': transaction.category.trim(),
            'subcategory': transaction.subcategory?.trim(),
            'amount': transaction.amount,
            'currency': transaction.currency.trim().toUpperCase(),
            'description': transaction.description?.trim(),
            'merchant_name': transaction.merchantName?.trim(),
            'customer_name': transaction.customerName?.trim(),
            'supplier_name': transaction.supplierName?.trim(),
            'payment_status': transaction.paymentStatus.name,
            'external_reference': transaction.externalReference?.trim(),
          })
          .eq('id', transaction.id)
          .eq('business_id', transaction.businessId)
          .select()
          .single();

      return Transaction.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update transaction: ${e.message}');
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while updating transaction.',
      );
    }
  }

  Future<void> deleteTransaction({
    required String id,
    required String businessId,
  }) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('business_id', businessId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete transaction: ${e.message}');
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while deleting transaction.',
      );
    }
  }
}
