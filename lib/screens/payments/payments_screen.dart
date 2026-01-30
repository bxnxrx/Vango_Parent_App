import 'package:flutter/material.dart';

import 'package:vango_parent_app/data/mock_data.dart';
import 'package:vango_parent_app/screens/payments/add_card_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';
import 'package:vango_parent_app/widgets/payment_card.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // Removing const from list definition
  final List<_PaymentMethod> _methods = [
    _PaymentMethod(
      name: 'Mastercard',
      masked: '•••• 8463',
      brand: _PaymentBrand.mastercard,
      detail: 'Personal card',
    ),
    _PaymentMethod(
      name: 'PayPal',
      masked: 'orb***@gmail.com',
      brand: _PaymentBrand.paypal,
      detail: 'Preferred online',
    ),
    _PaymentMethod(
      name: 'Apple Pay',
      masked: 'Wallet • iPhone',
      brand: _PaymentBrand.apple,
      detail: 'Face ID enabled',
    ),
  ];

  int _selectedMethod = 0;
  final double _orderAmount = 8000;
  final double _promo = 220;
  final double _delivery = 600;
  final double _tax = 200;

  double get _total {
    return _orderAmount - _promo + _delivery + _tax;
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (context) => Center(
        child: Container(
          margin: EdgeInsets.all(40),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 50,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: AppTypography.headline.copyWith(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                'Your payment of Rs. ${_total.toStringAsFixed(0)} has been processed',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment method',
                style: AppTypography.headline.copyWith(fontSize: 20),
              ),
              Text(
                'Secure checkout powered by EduRide',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                _PaymentMethodsCard(
                  methods: _methods,
                  selected: _selectedMethod,
                  onSelect: (index) {
                    setState(() {
                      _selectedMethod = index;
                    });
                  },
                ),
                SizedBox(height: 18),
                _DeliveryCard(),
                SizedBox(height: 18),
                _OrderSummaryCard(
                  orderAmount: _orderAmount,
                  promo: _promo,
                  delivery: _delivery,
                  tax: _tax,
                  total: _total,
                ),
                SizedBox(height: 24),
                GradientButton(
                  label: 'Pay now',
                  expanded: true,
                  onPressed: _showPaymentSuccess,
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent transactions',
                      style: AppTypography.title.copyWith(fontSize: 18),
                    ),
                    TextButton(onPressed: () {}, child: Text('View all')),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final payment = MockData.payments[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: PaymentCard(payment: payment),
              );
            }, childCount: MockData.payments.length),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final List<_PaymentMethod> methods;
  final int selected;
  final ValueChanged<int> onSelect;

  const _PaymentMethodsCard({
    Key? key,
    required this.methods,
    required this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          // Using a for loop instead of map
          for (var i = 0; i < methods.length; i++) ...[
            _PaymentMethodTile(
              method: methods[i],
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
            if (i != methods.length - 1)
              Divider(height: 1, indent: 76, endIndent: 20),
          ],
          Divider(height: 1, indent: 0, endIndent: 0),
          Padding(
            padding: EdgeInsets.all(20),
            child: GradientButton(
              label: 'Add payment method',
              icon: Icons.add,
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => AddCardScreen()));
              },
              expanded: true,
              secondary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    Key? key,
    required this.method,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: _PaymentBrandIcon(brand: method.brand),
      title: Text(
        method.name,
        style: AppTypography.title.copyWith(fontSize: 16),
      ),
      subtitle: Text(
        '${method.masked} • ${method.detail}',
        style: AppTypography.body.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
            width: 2,
          ),
          color: selected ? AppColors.accent : Colors.transparent,
        ),
        child: selected
            ? Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup location',
                      style: AppTypography.title.copyWith(fontSize: 16),
                    ),
                    Text(
                      'A3/4 Jawhra, Colombo 06',
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.chevron_right)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final double orderAmount;
  final double promo;
  final double delivery;
  final double tax;
  final double total;

  const _OrderSummaryCard({
    Key? key,
    required this.orderAmount,
    required this.promo,
    required this.delivery,
    required this.tax,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Standard function for text style
    TextStyle valueStyle(bool accent) {
      if (accent) {
        return AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        );
      } else {
        return AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        );
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Order amount',
            value: orderAmount,
            style: valueStyle(false),
          ),
          _SummaryRow(
            label: 'Promo code',
            value: -promo,
            style: valueStyle(false),
          ),
          _SummaryRow(
            label: 'Delivery',
            value: delivery,
            style: valueStyle(false),
          ),
          _SummaryRow(label: 'Tax', value: tax, style: valueStyle(false)),
          Divider(height: 32),
          _SummaryRow(
            label: 'Total amount',
            value: total,
            style: valueStyle(true),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle style;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Spacer(),
          Text('Rs. ${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String name;
  final String masked;
  final _PaymentBrand brand;
  final String detail;

  _PaymentMethod({
    required this.name,
    required this.masked,
    required this.brand,
    required this.detail,
  });
}

enum _PaymentBrand { mastercard, paypal, apple }

class _PaymentBrandIcon extends StatelessWidget {
  final _PaymentBrand brand;

  const _PaymentBrandIcon({Key? key, required this.brand}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // Using if-else instead of switch
    if (brand == _PaymentBrand.paypal) {
      icon = Icons.account_balance_wallet;
      color = Color(0xFF003087);
    } else if (brand == _PaymentBrand.apple) {
      icon = Icons.phone_iphone;
      color = Colors.black87;
    } else {
      // mastercard
      icon = Icons.credit_card;
      color = Color(0xFFEA5B0C);
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}
