import 'dart:io';

import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/utils/Extensions/extensions.dart';
import 'package:ebroker/utils/payment/lib/payment.dart';
import 'package:ebroker/utils/payment/lib/purchase_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';

import '../../AppIcon.dart';
import '../../constant.dart';
import '../../helper_utils.dart';
import '../../hive_utils.dart';
import '../../ui_utils.dart';

class Paystack extends Payment {
  SubscriptionPackageModel? _model;

  @override
  void onEvent(
      BuildContext context, covariant PaymentStatus currentStatus) async {
    if (currentStatus is Success) {
      await PurchasePackage().purchase(context);
    }
  }

  @override
  void pay(BuildContext context) async {
    if (_model == null) {
      throw "Please setPackage";
    }

    final request = PaystackTransactionRequest(
      reference: generateReference(HiveUtils.getUserDetails().email!),
      secretKey: Constant.paystackKey, // Use your secret key here
      email: HiveUtils.getUserDetails().email!,
      amount: (_model!.price! * 100).toDouble(),
      currency:
          PaystackCurrency.ngn, // Or use Constant.paystackCurrency if mapped
      channel: [
        PaystackPaymentChannel.card,
        PaystackPaymentChannel.bankTransfer,
        PaystackPaymentChannel.mobileMoney,
        PaystackPaymentChannel.ussd,
        PaystackPaymentChannel.bank,
        PaystackPaymentChannel.qr,
        PaystackPaymentChannel.eft,
      ],
      metadata: {
        "username": HiveUtils.getUserDetails().name,
        "package_id": _model!.id,
        "user_id": HiveUtils.getUserId(),
      },
    );

    final initializedTransaction =
        await PaymentService.initializeTransaction(request);

    if (!initializedTransaction.status) {
      HelperUtils.showSnackBarMessage(
        context,
        initializedTransaction.message,
      );
      emit(Failure(message: initializedTransaction.message));
      return;
    }

    await PaymentService.showPaymentModal(
      context,
      transaction: initializedTransaction,
      callbackUrl: 'https://callback.com', // Replace with your callback URL
    );

    final response = await PaymentService.verifyTransaction(
      paystackSecretKey: Constant.paystackKey,
      initializedTransaction.data?.reference ?? request.reference,
    );

    if (response.status) {
      emit(Success(message: "Success"));
    } else {
      emit(Failure(message: response.message));
      HelperUtils.showSnackBarMessage(
        context,
        response.message,
      );
    }
  }

  String generateReference(String email) {
    late String platform;
    if (Platform.isIOS) {
      platform = 'I';
    } else if (Platform.isAndroid) {
      platform = 'A';
    }
    String reference =
        '${platform}_${email.split("@").first}_${DateTime.now().millisecondsSinceEpoch}';
    return reference;
  }

  @override
  Payment setPackage(SubscriptionPackageModel modal) {
    _model = modal;
    return this;
  }
}
