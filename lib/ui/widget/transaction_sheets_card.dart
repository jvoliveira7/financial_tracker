import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';

import '../../common/utils/formatter.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

/// Widget que exibe uma lista de transações de receitas e despesas
class TransactionCardSheets extends StatefulWidget {
  final List<TransactionEntity> incomeTransactions;
  final List<TransactionEntity> expenseTransactions;
  final Function(String id) onDelete;
  final Function(TransactionEntity transaction) onEdit;
  final Command1<void, Failure, TransactionEntity> undoDelete;
  final BuildContext scaffoldContext;

  const TransactionCardSheets({
    super.key,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.onDelete,
    required this.onEdit,
    required this.undoDelete,
    required this.scaffoldContext,
  });

  @override
  State<TransactionCardSheets> createState() => _TransactionCardSheetsState();
}

class _TransactionCardSheetsState extends State<TransactionCardSheets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab(
                  TransactionType.income.namePlural,
                  Icons.arrow_upward,
                  0,
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.5),
                ),
                _buildTab(
                  TransactionType.expense.namePlural,
                  Icons.arrow_downward,
                  1,
                  colorScheme.secondary,
                  colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ],
              indicatorColor: _tabController.index == 0
                  ? colorScheme.primary
                  : colorScheme.secondary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: 290,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(
                    context,
                    widget.incomeTransactions,
                    colorScheme.primary,
                    TransactionType.income,
                  ),
                  _buildTransactionList(
                    context,
                    widget.expenseTransactions,
                    colorScheme.secondary,
                    TransactionType.expense,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    IconData icon,
    int index,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _tabController.index == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<TransactionEntity> transactions,
    Color color,
    TransactionType type,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == TransactionType.income
                  ? Icons.savings_outlined
                  : Icons.shopping_cart_outlined,
              size: 52,
              color: color.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma ${type.nameSingular.toLowerCase()} registrada',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque no botão acima para adicionar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final undoTransaction = transaction.copyWith();

          return Dismissible(
            key: Key(transaction.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'Excluir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (direction) async {
              await widget.onDelete(transaction.id);

              ScaffoldMessenger.of(widget.scaffoldContext).clearSnackBars();
              ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                SnackBar(
                  content: Text('${transaction.title} excluída!'),
                  backgroundColor: Colors.pinkAccent,
                  action: SnackBarAction(
                    label: 'DESFAZER',
                    textColor: Colors.white,
                    onPressed: () async {
                      await widget.undoDelete.execute(undoTransaction);
                      if (widget.undoDelete.resultSignal.value?.isSuccess ??
                          false) {
                        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                          SnackBar(
                            content: Text('${transaction.title} restaurada!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.undoDelete.resultSignal.value?.failureValueOrNull ?? 'Erro desconhecido'}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
            // Card elaborado com barra lateral colorida
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Barra lateral colorida indica visualmente o tipo
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                      // Conteúdo do card
                      Expanded(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(
                              // Corrigido: comparação com enum, não String hardcoded
                              type == TransactionType.income
                                  ? Icons.attach_money
                                  : Icons.shopping_bag_outlined,
                              color: color,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            transaction.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Formatter.formatDate(transaction.date),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                          // trailing com valor, sinal explícito e botão de editar
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    // Sinal + para receita, - para despesa
                                    '${type == TransactionType.income ? '+' : '-'} ${Formatter.formatCurrency(transaction.amount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: color.withValues(alpha: 0.7),
                                  size: 18,
                                ),
                                onPressed: () => widget.onEdit(transaction),
                                tooltip: 'Editar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}