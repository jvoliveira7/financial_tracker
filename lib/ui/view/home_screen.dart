import '../../common/config/dependencies.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:financial_tracker/ui/view/dashboard_screen.dart';
import 'package:financial_tracker/ui/widget/date_filter_transactions.dart';
import 'package:financial_tracker/ui/widget/summary_carousel.dart';
import 'package:financial_tracker/ui/widget/transaction_sheet.dart';
import 'package:financial_tracker/ui/widget/transaction_sheets_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomePageController viewModelController;

  @override
  void initState() {
    super.initState();
    viewModelController = injector.get<HomePageController>();
    viewModelController.load.execute();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _getFormattedDate() {
    return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const Text(
              'Controle Financeiro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              _getFormattedDate(),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        actions: [
          Watch((context) {
            final isVisible = viewModelController.isFilterVisible.value;
            return IconButton(
              icon: Icon(isVisible ? Icons.filter_list_off : Icons.filter_list),
              tooltip: isVisible ? 'Ocultar filtros' : 'Mostrar filtros',
              onPressed: viewModelController.toggleFilterVisibility,
            );
          }),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Watch((context) {
              final income = viewModelController.totalIncome.value;
              final expense = viewModelController.totalExpense.value;
              return SummaryCarousel(
                totalIncome: income,
                totalExpense: expense,
              );
            }),
            Watch((context) {
              final isVisible = viewModelController.isFilterVisible.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isVisible ? null : 0,
                child: isVisible
                    ? DateFilterTransactions(
                        filtro: (
                          type: viewModelController.filterType,
                          startDate: viewModelController.startDate,
                          endDate: viewModelController.endDate,
                        ),
                        onFilterChanged: (startDate, endDate) {
                          viewModelController.searchTransactionsByDate
                              .execute(startDate!, endDate!);
                        },
                        onUpdateFilter: (type, startDate, endDate) {
                          viewModelController.setFiltersParams(
                            type,
                            startDate,
                            endDate,
                          );
                        },
                        onAllTransactionsFiltered: () {
                          viewModelController.load.execute();
                        },
                        onTapHideFilter:
                            viewModelController.toggleFilterVisibility,
                      )
                    : const SizedBox.shrink(),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      TransactionType.income,
                      Icons.add_circle,
                      colorScheme.primary,
                      () => _showAddSheet(context, TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      TransactionType.expense,
                      Icons.remove_circle,
                      colorScheme.secondary,
                      () => _showAddSheet(context, TransactionType.expense),
                    ),
                  ),
                ],
              ),
            ),
            Watch((context) {
              final incomes = viewModelController.incomes.value;
              final expenses = viewModelController.expenses.value;
              return TransactionCardSheets(
                incomeTransactions: incomes,
                expenseTransactions: expenses,
                onDelete: (id) {
                  viewModelController.deleteTransaction.execute(id);
                },
                onEdit: (transaction) {
                  _showEditSheet(context, transaction);
                },
                undoDelete: viewModelController.undoDelectedTransaction,
                scaffoldContext: context,
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    TransactionType transactionType,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(transactionType.namePlural),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddSheet(BuildContext context, TransactionType type) {
    TransactionSheet.show(
      context: context,
      type: type,
      submitCommand: viewModelController.saveTransaction,
    );
  }

  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    TransactionSheet.show(
      context: context,
      type: transaction.type,
      submitCommand: viewModelController.editTransaction,
      initialTransaction: transaction,
    );
  }
}