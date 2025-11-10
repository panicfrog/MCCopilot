import 'package:flutter/material.dart';

// 默认入口点（用于 Tab 3 - Flutter 1）
void main() => runApp(
  const MyApp(
    title: 'Flutter Example',
    color: Colors.blue,
    icon: Icons.flutter_dash,
    route: '/example',
  ),
);

// 购物模块入口点（用于 Tab 4）
@pragma('vm:entry-point')
void shoppingMain() => runApp(
  const MyApp(
    title: '购物模块',
    color: Colors.orange,
    icon: Icons.shopping_cart,
    route: '/shopping',
  ),
);

// 个人中心入口点（用于 Tab 5）
@pragma('vm:entry-point')
void profileMain() => runApp(
  const MyApp(
    title: '个人中心',
    color: Colors.purple,
    icon: Icons.person,
    route: '/profile',
  ),
);

// 主应用
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.route,
  });

  final String title;
  final MaterialColor color;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(colorSchemeSeed: color, useMaterial3: true),
      home: MyHomePage(title: title, color: color, icon: icon, route: route),
    );
  }
}

// 首页
class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.route,
  });

  final String title;
  final MaterialColor color;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color[50],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '独立的 Flutter 引擎',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '🎯 这是一个独立的引擎实例',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entry Point: ${route.replaceAll('/', '')}Main\n\n'
                      '• 通过 FlutterEngineGroup 创建\n'
                      '• 共享 Dart VM\n'
                      '• 独立的状态和导航栈\n'
                      '• 低内存占用',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
