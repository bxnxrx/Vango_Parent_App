import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/payment_record.dart';
import 'package:vango_parent_app/models/card_info.dart';
import 'package:vango_parent_app/screens/payments/add_card_screen.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
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
    if (!mounted) return;
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
                    'My Wallet',
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
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cards.length + 1,
        itemBuilder: (context, index) {
          if (index == _cards.length) return _buildAddCardButton();

          final card = _cards[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card.isDefault
                    ? [
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.8),
                      ]
                    : [Colors.grey.shade700, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (card.isDefault)
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Column(
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
                          card.isDefault ? 'PRIMARY' : 'SECONDARY',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.cardExpiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showCardActions(card),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCardActions(CardInfo card) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            if (!card.isDefault)
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Set as Default'),
                // FIXED: Changed onPressed to onTap
                onTap: () async {
                  Navigator.pop(context);
                  await _dataService.setDefaultCard(card.id);
                  _loadData();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: const Text(
                'Remove Card',
                style: TextStyle(color: AppColors.danger),
              ),
              // FIXED: Changed onPressed to onTap
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmation();
                if (confirm == true) {
                  await _dataService.deleteCard(card.id);
                  _loadData();
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card?'),
        content: const Text(
          'Are you sure you want to remove this card? Automated payments may fail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
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
          border: Border.all(color: Theme.of(context).dividerColor),
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
