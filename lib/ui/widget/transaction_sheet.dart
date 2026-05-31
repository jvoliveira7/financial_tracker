import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

import 'transaction_form.dart';

/// Bottom sheet para adicionar ou editar transações de receita ou despesa
class TransactionSheet extends StatelessWidget {
  /// Tipo da transação (receita ou despesa)
  final TransactionType type;

  /// Comando que deve ser observado o estado de execução e o resultado
  final Command1<void, Failure, TransactionEntity> submitCommand;

  /// Transação existente para edição (null = modo criação)
  final TransactionEntity? initialTransaction;

  const TransactionSheet({
    super.key,
    required this.type,
    required this.submitCommand,
    this.initialTransaction,
  });

  /// Método auxiliar para exibir o bottom sheet como um modal
  static Future<void> show({
    required BuildContext context,
    required TransactionType type,
    required Command1<void, Failure, TransactionEntity> submitCommand,
    TransactionEntity? initialTransaction,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionSheet(
        type: type,
        submitCommand: submitCommand,
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIncome = type == TransactionType.income;
    final color = isIncome ? colorScheme.primary : colorScheme.secondary;

    //Muda o título do header dependendo do modo
    final isEditing = initialTransaction != null;
    final headerTitle = isEditing
        ? 'Editar ${type.nameSingular}'
        : 'Adicionar ${type.nameSingular}';

    final availableHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: availableHeight,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho e "alça" do sheet
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Alça para indicar que o sheet pode ser arrastado
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Título do cabeçalho
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit
                            : isIncome
                                ? Icons.trending_up
                                : Icons.trending_down,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        headerTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Formulário para inserir ou editar a transação
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: TransactionForm(
                  type: type,
                  color: color,
                  submitCommand: submitCommand,
                  initialTransaction: initialTransaction, // repassa pro form
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}