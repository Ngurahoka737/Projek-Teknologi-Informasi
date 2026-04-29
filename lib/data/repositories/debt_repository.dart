import '../../domain/entities/debt.dart';

abstract class DebtRepository {
  Future<List<Debt>> getAllDebts();
  Future<int> insertDebt(Debt debt);
  Future<int> deleteDebt(int id);
}
