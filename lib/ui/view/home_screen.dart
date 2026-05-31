import '../../common/config/dependencies.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:financial_tracker/ui/widget/date_filter_transactions.dart';
import 'package:financial_tracker/ui/widget/summary_carousel.dart';
import 'package:financial_tracker/ui/widget/transaction_sheet.dart';
import 'package:financial_tracker/ui/widget/transaction_sheets_card.dart';
import 'package:flutter/material.dart';
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
    // Busca o controller já registrado no injetor de dependências
    viewModelController = injector.get<HomePageController>();
    viewModelController.load.execute();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
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
            icon: const Icon(Icons.receipt_long),
            onPressed: () {},
            tooltip: 'Visualizar todas as transações',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),

            // Carrossel de resumo observa os totais do controlle
            Watch((context) {
              final income = viewModelController.totalIncome.value;
              final expense = viewModelController.totalExpense.value;
              return SummaryCarousel(
                totalIncome: income,
                totalExpense: expense,
              );
            }),

            // Filtro de data animado, controlado pelo signal do controller
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
                        // Bug corrigido: agora usa o toggleFilterVisibility
                        // do controller, não o método local da view
                        onTapHideFilter:
                            viewModelController.toggleFilterVisibility,
                      )
                    : const SizedBox.shrink(),
              );
            }),

            // Botões de adicionar receita e despesa
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

            // Lista de transações — observa os signals de receitas e despesas
            Watch((context) {
              final incomes = viewModelController.incomes.value;
              final expenses = viewModelController.expenses.value;
              return TransactionCardSheets(
                incomeTransactions: incomes,
                expenseTransactions: expenses,
                onDelete: (id) {
                  viewModelController.deleteTransaction.execute(id);
                },
                // onEdit: abre o sheet em modo edição com os dados da transação
                // e usa o editTransaction command em vez do saveTransaction
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

  /// Abre o sheet para adicionar uma transação nova
  void _showAddSheet(BuildContext context, TransactionType type) {
    TransactionSheet.show(
      context: context,
      type: type,
      submitCommand: viewModelController.saveTransaction,
    );
  }

  /// Abre o sheet para editar uma transação existente
  /// Passa a transação como initialTransaction e usa o editTransaction command
  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    TransactionSheet.show(
      context: context,
      type: transaction.type,
      submitCommand: viewModelController.editTransaction,
      initialTransaction: transaction,
    );
  }
}