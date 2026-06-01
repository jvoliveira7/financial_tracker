import 'package:financial_tracker/common/config/dependencies.dart';
import 'package:financial_tracker/common/utils/formatter.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late HomePageController controller;

  @override
  void initState() {
    super.initState();
    //reutiliza o mesmo controller já registrado no injetor
    //os dados já estão carregados, não precisa buscar de novo
    controller = injector.get<HomePageController>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Watch((context) {
        final income = controller.totalIncome.value;
        final expense = controller.totalExpense.value;
        final balance = controller.balance.value;
        final incomes = controller.incomes.value;
        final expenses = controller.expenses.value;
        final all = [...incomes, ...expenses];

        //maior receita e maior despesa do período
        final biggestIncome = incomes.isEmpty
            ? null
            : incomes.reduce((a, b) => a.amount > b.amount ? a : b);
        final biggestExpense = expenses.isEmpty
            ? null
            : expenses.reduce((a, b) => a.amount > b.amount ? a : b);

        //média por transação
        final avg = all.isEmpty
            ? 0.0
            : all.fold(0.0, (sum, t) => sum + t.amount) / all.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //titulo da seção
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Visão Geral',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              //card com saldo em destaque
              _buildBalanceCard(context, balance, colorScheme),
              const SizedBox(height: 16),

              //grid com 4 estatísticas
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    'Total Receitas',
                    Formatter.formatCurrency(income),
                    Icons.trending_up,
                    colorScheme.primary,
                  ),
                  _buildStatCard(
                    context,
                    'Total Despesas',
                    Formatter.formatCurrency(expense),
                    Icons.trending_down,
                    colorScheme.secondary,
                  ),
                  _buildStatCard(
                    context,
                    'Transações',
                    '${all.length} registros',
                    Icons.receipt_long,
                    colorScheme.tertiary,
                  ),
                  _buildStatCard(
                    context,
                    'Média por registro',
                    Formatter.formatCurrency(avg),
                    Icons.calculate_outlined,
                    Colors.orange.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              //destaques
              Text(
                'Destaques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              _buildHighlightCard(
                context,
                'Maior Receita',
                biggestIncome?.title ?? 'Nenhuma receita',
                biggestIncome != null
                    ? Formatter.formatCurrency(biggestIncome.amount)
                    : '-',
                Icons.star_outline,
                colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _buildHighlightCard(
                context,
                'Maior Despesa',
                biggestExpense?.title ?? 'Nenhuma despesa',
                biggestExpense != null
                    ? Formatter.formatCurrency(biggestExpense.amount)
                    : '-',
                Icons.warning_amber_outlined,
                colorScheme.secondary,
              ),
            ],
          ),
        );
      }),
    );
  }

  //card de saldo com cor dinâmica (verde se positivo, vermelho se negativo)
  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    ColorScheme colorScheme,
  ) {
    final isPositive = balance >= 0;
    final color = isPositive ? colorScheme.primary : colorScheme.secondary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.account_balance_wallet : Icons.warning_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Atual',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                Text(
                  Formatter.formatCurrency(balance),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context,
    String label,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[500]),
        ),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ),
    );
  }
}