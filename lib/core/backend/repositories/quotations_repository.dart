import 'package:linko/features/requests/domain/models/quotation.dart';

abstract interface class QuotationsRepository {
  Future<Quotation?> getQuotation(String requestId);
  Future<void> sendQuotation(Quotation quotation);
  Future<void> acceptQuotation(String requestId);
}
