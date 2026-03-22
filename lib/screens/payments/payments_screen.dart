import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/payment_record.dart';
import 'package:vango_parent_app/models/card_info.dart';
import 'package:vango_parent_app/screens/payments/add_card_screen.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';
import 'package:vango_parent_app/widgets/payment_card.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  List<PaymentRecord> _transactions = const [];
  List<CardInfo> _cards = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _dataService.fetchLinkedCards(),
        _dataService.fetchPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _cards = results[0] as List<CardInfo>;
        _transactions = results[1] as List<PaymentRecord>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              'Billing & Payments',
              style: AppTypography.headline.copyWith(fontSize: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'My Cards',
                    style: AppTypography.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCardCarousel(),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Transactions',
                    style: AppTypography.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_transactions.isEmpty && !_isLoading)
            const SliverFillRemaining(
              child: Center(child: Text('No transactions yet')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PaymentCard(payment: _transactions[index]),
                  ),
                  childCount: _transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cards.length + 1,
        itemBuilder: (context, index) {
          if (index == _cards.length) {
            return _buildAddCardButton();
          }
          final card = _cards[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.cardType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.contactless, color: Colors.white70),
                  ],
                ),
                Text(
                  card.cardNo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 4,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.isDefault ? 'PRIMARY' : '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      card.cardExpiry,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCardButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AddCardScreen()))
          .then((_) => _loadData()),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.accent, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Add Card',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
