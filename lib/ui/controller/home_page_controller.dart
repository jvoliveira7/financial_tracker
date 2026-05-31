import 'package:financial_tracker/common/types/date_filter_type.dart';
import 'package:financial_tracker/domain/usecase/use_case_facade.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../common/errors/errors_classes.dart';
import '../../common/patterns/command.dart';
import '../../common/patterns/result.dart';
import '../../domain/entity/transaction_entity.dart';

class HomePageController {
  HomePageController({
    required TransactionFacadeUseCases transactionsUseCases,
  }) : _transactionsUseCases = transactionsUseCases {
    load = Command0(_loadTransactions);
    searchTransactionsByDate = Command2(_searchTransactionsByDate);
    saveTransaction = Command1(_saveTransaction);
    editTransaction = Command1(_editTransaction); // <- novo
    undoDelectedTransaction = Command1(_undoDelectedTransaction);
    deleteTransaction = Command1(_deleteTransaction);

    incomes = Computed(
      () => _transactions.value
          .where((e) => e.type == TransactionType.income)
          .toList(),
    );

    expenses = Computed(
      () => _transactions.value
          .where((e) => e.type == TransactionType.expense)
          .toList(),
    );

    totalIncome = Computed(
      () => _transactions.value
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount),
    );

    totalExpense = Computed(
      () => _transactions.value
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount),
    );

    balance = Computed(() => totalIncome.value - totalExpense.value);
  }

  final TransactionFacadeUseCases _transactionsUseCases;

  // commands
  late final Command0<List<TransactionEntity>, Failure> load;
  late final Command1<void, Failure, TransactionEntity> saveTransaction;
  late final Command1<void, Failure, TransactionEntity> editTransaction; // <- novo
  late final Command1<void, Failure, TransactionEntity> undoDelectedTransaction;
  late final Command1<void, Failure, String> deleteTransaction;
  late final Command2<List<TransactionEntity>, Failure, DateTime, DateTime>
      searchTransactionsByDate;

  // signals
  final Signal<List<TransactionEntity>> _transactions = Signal([]);
  final Signal<bool> _isFilterVisible = Signal(false);

  // variáveis de controle
  TransactionEntity? _lastDeleted;
  int? _lastDeletedIndex;

  DateFilterType _currentFilterType = DateFilterType.all;
  DateTime? _startDate;
  DateTime? _endDate;
  DateFilterType get filterType => _currentFilterType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // computed signals
  late final Computed<List<TransactionEntity>> incomes;
  late final Computed<List<TransactionEntity>> expenses;
  late final Computed<double> totalIncome;
  late final Computed<double> totalExpense;
  late final Computed<double> balance;

  ReadonlySignal<List<TransactionEntity>> get transctions => _transactions;
  ReadonlySignal<bool> get isFilterVisible => _isFilterVisible;

  Future<Result<List<TransactionEntity>, Failure>> _searchTransactionsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await _transactionsUseCases.getByDate.call((
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      onSuccess: (transactions) {
        _transactions.value = transactions;
      },
      onFailure: (_) {
        _transactions.value = [];
      },
    );

    return result;
  }

  Future<Result<List<TransactionEntity>, Failure>> _loadTransactions() async {
    final result = await _transactionsUseCases.getAll.call(());

    result.fold(
      onSuccess: (transactions) {
        _transactions.value = transactions;
      },
      onFailure: (_) {},
    );

    return result;
  }

  Future<Result<void, Failure>> _saveTransaction(
    TransactionEntity transaction,
  ) async {
    final result = await _transactionsUseCases.addTransaction.call((
      transaction: transaction,
    ));

    if (result.isSuccess) {
      _transactions.value = [..._transactions.value, transaction];
    }

    return result;
  }

  // atualiza uma transação existente pelo ID e atualiza o signal
  Future<Result<void, Failure>> _editTransaction(
    TransactionEntity updatedTransaction,
  ) async {
    final result = await _transactionsUseCases.addTransaction.call((
      transaction: updatedTransaction,
    ));

    if (result.isSuccess) {
      //substitui a transação antiga pela atualizada, mantendo a posição na lista
      _transactions.value = _transactions.value.map((t) {
        return t.id == updatedTransaction.id ? updatedTransaction : t;
      }).toList();
    }

    return result;
  }

  Future<Result<void, Failure>> _undoDelectedTransaction(
    TransactionEntity transaction,
  ) async {
    final last = _lastDeleted;
    final index = _lastDeletedIndex;

    if (last != null && index != null && transaction == last) {
      final result = await _transactionsUseCases.addTransaction.call((
        transaction: last,
      ));

      if (result.isSuccess) {
        final list = [..._transactions.value];
        list.insert(index, last);
        _transactions.value = list;

        _lastDeleted = null;
        _lastDeletedIndex = null;
      }

      return result;
    }

    return Error(DefaultError('Nenhuma transação excluída para restaurar.'));
  }

  Future<Result<void, Failure>> _deleteTransaction(String id) async {
    final result = await _transactionsUseCases.deleteById.call((id: id));

    result.fold(
      onSuccess: (_) {
        _lastDeletedIndex =
            _transactions.value.indexWhere((e) => e.id == id);
        _lastDeleted = _transactions.value[_lastDeletedIndex!];

        _transactions.value =
            _transactions.value.where((e) => e.id != id).toList();
      },
      onFailure: (failure) {},
    );

    return result;
  }

  void toggleFilterVisibility() {
    _isFilterVisible.value = !_isFilterVisible.value;
  }

  void setFiltersParams(
    DateFilterType type,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    _currentFilterType = type;
    _startDate = startDate;
    _endDate = endDate;
  }
}