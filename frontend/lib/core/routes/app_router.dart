import 'package:flutter/material.dart';

import '../../screens/auth/auth_gate.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/checkout/payment_qr_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../screens/profile/help_center_screen.dart';
import '../../screens/profile/my_listings_screen.dart';
import '../../screens/profile/my_orders_screen.dart';
import '../../screens/profile/sold_orders_screen.dart';
import '../../screens/sell/sell_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../constants/app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authGate:
        return _page(const AuthGate(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.register:
        return _page(const RegisterScreen(), settings);
      case AppRoutes.main:
        return _page(const MainShell(), settings);
      case AppRoutes.sell:
        return _page(const SellScreen(), settings);
      case AppRoutes.notifications:
        final showBack = settings.arguments is bool
            ? settings.arguments as bool
            : true;
        return _page(
          NotificationsScreen(showBackButton: showBack),
          settings,
        );
      case AppRoutes.productDetail:
        final productId = _readStringArg(settings, AppRoutes.productIdArg);
        if (productId == null) {
          return _badArgs(settings);
        }
        return _page(ProductDetailScreen(productId: productId), settings);
      case AppRoutes.checkout:
        return _page(const CheckoutScreen(), settings);
      case AppRoutes.paymentQr:
        final args = settings.arguments;
        if (args is! Map<String, dynamic>) {
          return _badArgs(settings);
        }
        final orderId = args[AppRoutes.orderIdArg] as String?;
        final totalAmount = args['totalAmount'] as double?;
        if (orderId == null || totalAmount == null) {
          return _badArgs(settings);
        }
        return _page(
          PaymentQrScreen(orderId: orderId, totalAmount: totalAmount),
          settings,
        );
      case AppRoutes.myOrders:
        return _page(const MyOrdersScreen(), settings);
      case AppRoutes.soldOrders:
        return _page(const SoldOrdersScreen(), settings);
      case AppRoutes.myListings:
        return _page(const MyListingsScreen(), settings);
      case AppRoutes.helpCenter:
        return _page(const HelpCenterScreen(), settings);
      default:
        return null;
    }
  }

  static String? _readStringArg(RouteSettings settings, String key) {
    final args = settings.arguments;
    if (args is String) {
      return args;
    }
    if (args is Map && args[key] is String) {
      return args[key] as String;
    }
    return null;
  }

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => child,
    );
  }

  static MaterialPageRoute<void> _badArgs(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(
        body: Center(child: Text('Tham số điều hướng không hợp lệ')),
      ),
    );
  }
}
