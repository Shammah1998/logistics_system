import 'package:flutter/material.dart';
import 'package:logistics_app/presentation/pages/login/login_page.dart';
import 'package:logistics_app/presentation/pages/home/home_page.dart';
import 'package:logistics_app/presentation/pages/orders/orders_page.dart';
import 'package:logistics_app/presentation/pages/earnings/earnings_page.dart';
import 'package:logistics_app/presentation/pages/profile/profile_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String earnings = '/earnings';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersPage());
      case earnings:
        return MaterialPageRoute(builder: (_) => const EarningsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case null:
      case '':
        // Default to login if no route specified
        return MaterialPageRoute(builder: (_) => const LoginPage());
      default:
        // Redirect unknown routes to login
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}

