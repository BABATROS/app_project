import 'package:flutter/material.dart';

import 'admin_users.dart';
import 'admin_shops.dart';
import 'admin_products.dart';
import 'admin_orders.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _AdminMenuCard(
              icon: Icons.people,
              title: 'ผู้ใช้งาน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersPage(),
                  ),
                );
              },
            ),
            _AdminMenuCard(
              icon: Icons.store,
              title: 'ร้านค้า',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminShopsPage(),
                  ),
                );
              },
            ),
            _AdminMenuCard(
              icon: Icons.inventory_2,
              title: 'สินค้า',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProductsPage(),
                  ),
                );
              },
            ),
            _AdminMenuCard(
              icon: Icons.receipt_long,
              title: 'คำสั่งซื้อ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminOrdersPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
