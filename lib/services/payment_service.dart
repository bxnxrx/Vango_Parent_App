import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:vango_parent_app/services/backend_client.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  /// Starts the Preapproval process to tokenize the Parent's card.
  Future<void> initCardPreapproval({
    required Function(String) onSuccess,
    required Function(String) onError,
    required void Function() onDismissed,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Extract available user data, use fallbacks for missing billing info
      final String firstName = user.userMetadata?['full_name'] ?? "Parent";
      final String email = user.email ?? "no-email@vango.lk";
      final String phone = user.phone ?? "0000000000";

      // Defaulting billing info as discussed
      final String address = "Colombo";
      final String city = "Colombo";
      final String country = "Sri Lanka";

      // 1. Request Hash and Order ID from Backend
      // The backend generates the orderId and uses the SECRET to create the hash
      final response = await BackendClient.instance.post(
        '/api/payments/init-preapproval',
        {
          'parentEmail': email,
          'amount':
              '10.00', // Preapproval might require a small dummy amount depending on gateway settings
        },
      );

      final String orderId =
          response['orderId'] ?? "PA_${DateTime.now().millisecondsSinceEpoch}";
      final String hash = response['hash'];
      final String notifyUrl = response['notifyUrl'];

      // 2. Prepare the PayHere object
      Map<String, dynamic> paymentObject = {
        "sandbox": AppConfig.payhereIsSandbox,
        "preapprove": true,
        "merchant_id": AppConfig.payhereMerchantId,
        "notify_url": notifyUrl,
        "order_id": orderId,
        "items": "VanGo Card Verification",
        "currency": "LKR",
        "first_name": firstName,
        "last_name": "",
        "email": email,
        "phone": phone,
        "address": address,
        "city": city,
        "country": country,
        "hash": hash,
        "custom_1":
            user.id, // 👇 ADD THIS LINE to pass the Parent's Supabase ID
      };
      // 3. Launch PayHere SDK
      PayHere.startPayment(
        paymentObject,
        (paymentId) => onSuccess(paymentId.toString()),
        (error) => onError(error.toString()),
        () => onDismissed(),
      );
    } catch (e) {
      onError(e.toString());
    }
  }
}
