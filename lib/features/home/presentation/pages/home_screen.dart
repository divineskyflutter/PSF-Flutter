import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/core/theme/theme_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            icon: Icon(themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeController.toggleTheme(),
          ),
          const IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Outstanding Balance',
                    style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$24,500.00',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Payment: Oct 12',
                        style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
                      ),
                      Text(
                        '\$1,250.00',
                        style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionItem(context, Icons.payment, 'Make Payment'),
                _buildActionItem(context, Icons.document_scanner, 'Documents'),
                _buildActionItem(context, Icons.support_agent, 'Support'),
                _buildActionItem(context, Icons.add_circle_outline, 'New Loan'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Transactions
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildTransactionItem(context, 'Monthly Payment', 'Sep 12, 2026', '-\$1,250.00', true),
            _buildTransactionItem(context, 'Loan Disbursement', 'Aug 01, 2026', '+\$25,750.00', false),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, String title, String date, String amount, bool isDeduction) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDeduction ? colorScheme.error.withOpacity(0.1) : colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeduction ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDeduction ? colorScheme.error : colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
