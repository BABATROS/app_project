import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/login.dart';
import 'screens/chat_notification_service.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  ChatNotificationService.init();

  PushService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I HAVE COM',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const StartPage(),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  static const Color orange = Color(0xFFFF6B00);
  static const Color dark = Color(0xFF151515);
  static const Color muted = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and brand
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.computer_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I HAVE COM',
                                  style: TextStyle(
                                    color: dark,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'COMPUTER & IT ACCESSORIES',
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 9,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 42),

                      // Welcome heading
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'YOUR TECH, YOUR STYLE',
                          style: TextStyle(
                            color: orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'อุปกรณ์คอมพิวเตอร์ครบ',
                        style: TextStyle(
                          color: dark,
                          fontSize: 28,
                          height: 1.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'จบในที่เดียว',
                        style: TextStyle(
                          color: orange,
                          fontSize: 36,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'คอมพิวเตอร์ โน้ตบุ๊ก อุปกรณ์เสริม และสินค้าไอที\n'
                        'คุณภาพดี ราคาคุ้มค่า พร้อมบริการที่เชื่อถือได้',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: 64,
                        height: 5,
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Minimal icon panel instead of a product image
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 26,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: orange.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.devices_rounded,
                                color: orange,
                                size: 54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'BETTER TECH. BETTER LIFE.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'อัปเกรดประสบการณ์ไอทีของคุณ',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Four features
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.verified_outlined,
                              title: 'สินค้าของแท้',
                              subtitle: 'รับประกันคุณภาพ',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.local_shipping_outlined,
                              title: 'จัดส่งรวดเร็ว',
                              subtitle: 'ทั่วประเทศ',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.support_agent_rounded,
                              title: 'บริการหลังการขาย',
                              subtitle: 'พร้อมดูแลคุณ',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.security_rounded,
                              title: 'ชำระเงินปลอดภัย',
                              subtitle: 'หลายช่องทาง',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Keep the original navigation to LoginPage
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'เริ่มใช้งาน',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Center(
                        child: Text(
                          'YOUR NEXT TECH EXPERIENCE STARTS HERE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: StartPage.orange, size: 27),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StartPage.dark,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StartPage.muted,
            fontSize: 9,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
