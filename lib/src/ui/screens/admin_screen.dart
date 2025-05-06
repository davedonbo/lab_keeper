import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/borrow_request.dart';
import '../../models/borrow_status.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_service.dart';
import '../../services/equipment_service.dart';
import '../../models/equipment.dart';

import '../widgets/request_review_page.dart';
import '../widgets/request_return_page.dart';
import '../widgets/returned_detail_page.dart';

bool overdues = false;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 4, vsync: this);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Inventory',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Equipment')),
                    body: const _EquipmentTab(),
                    floatingActionButton: FloatingActionButton(
                      tooltip: 'Add equipment',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/admin/add',
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Audit logs',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, '/admin/logs'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Returned'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: const [
          _RequestTab(status: BorrowStatus.pending),
          _RequestTab(status: BorrowStatus.approved),
          _RequestTab(status: BorrowStatus.returned),
          _OverdueTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: tabs,
        builder: (_, __) {
          // only show on Overdue tab (index 3)
          if (tabs.index != 3) return const SizedBox.shrink();
          return FloatingActionButton(
            tooltip: 'Send overdue reminders',
            child: const Icon(Icons.notifications_outlined),
            onPressed: _sendReminders,
          );
        },
      ),
    );
  }

  Future<void> _sendReminders() async {
    // Ask for confirmation
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send overdue reminders?'),
        content: const Text(
          'Notify all users whose return date has passed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Check for any overdue requests first
    // final now = DateTime.now();
    // final overdueSnap = await FirebaseFirestore.instance
    //     .collection('borrow_requests')
    //     .where('status', isEqualTo: BorrowStatus.approved.value)
    //     .where('returnDate', isLessThan: now)
    //     .get();

    if (!overdues) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no overdue requests.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffAC3333),),
      ),
    );

    try {
      final resp = await FirebaseFunctions.instance
          .httpsCallable('sendOverdueNotifications')
          .call();
      Navigator.pop(context); // dismiss loading
      final count = resp.data['count'] as int? ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent $count overdue reminder(s).')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reminders: $e')),
      );
    }
  }
}

/*──────────────── REQUEST TAB ─────────────────*/
class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.status});
  final BorrowStatus status;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrow_requests')
          .where('status', isEqualTo: status.value)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reqs = snap.data!.docs
            .map((d) => BorrowRequest.fromJson(
          d.id,
          d.data()! as Map<String, dynamic>,
        ))
            .toList();

        if (reqs.isEmpty) {
          return Center(
            child: Text('No ${status.value.toLowerCase()} requests'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final r = reqs[i];
            return ListTile(
              title: Text('Request ${r.id.substring(0, 6).toUpperCase()}'),
              subtitle: Text(
                '${r.borrowDate.day}/${r.borrowDate.month}/${r.borrowDate.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final doc = await FirebaseFirestore.instance
                    .collection('borrow_requests')
                    .doc(r.id)
                    .get();
                final fresh = BorrowRequest.fromJson(
                  doc.id,
                  doc.data()! as Map<String, dynamic>,
                );

                Widget page;
                switch (status) {
                  case BorrowStatus.pending:
                    page = RequestReviewPage(request: fresh);
                    break;
                  case BorrowStatus.approved:
                    page = ReturnReviewPage(request: fresh);
                    break;
                  case BorrowStatus.returned:
                    page = ReturnedDetailPage(request: fresh);
                    break;
                  default:
                    page = ReturnedDetailPage(request: fresh);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            );
          },
        );
      },
    );
  }
}

/*──────────────── OVERDUE TAB ─────────────────*/
class _OverdueTab extends StatelessWidget {
  const _OverdueTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrow_requests')
          .where('status', isEqualTo: BorrowStatus.approved.value)
          .where('returnDate', isLessThan: now)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final overdue = snap.data!.docs
            .map((d) => BorrowRequest.fromJson(
          d.id,
          d.data()! as Map<String, dynamic>,
        ))
            .toList();
        if (overdue.isEmpty) {
          overdues = false;
          return const Center(child: Text('No overdue requests'));
        }
        else overdues=true;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: overdue.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final r = overdue[i];
            return ListTile(
              title: Text('Request ${r.id.substring(0, 6).toUpperCase()}'),
              subtitle: Text(
                  'Due ${r.returnDate!.day}/${r.returnDate!.month}/${r.returnDate!.year}'),
              trailing:
              const Icon(Icons.error_outline, color: Colors.red),
              onTap: () async {
                final doc = await FirebaseFirestore.instance
                    .collection('borrow_requests')
                    .doc(r.id)
                    .get();
                final fresh = BorrowRequest.fromJson(
                  doc.id,
                  doc.data()! as Map<String, dynamic>,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReturnReviewPage(request: fresh),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/*──────────────── EQUIPMENT TAB (re-used) ─────────────────*/
class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: EquipmentService.instance.streamAll(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!.docs
            .map((d) => Equipment.fromJson(
          d.id,
          d.data()! as Map<String, dynamic>,
        ))
            .toList();
        if (list.isEmpty) {
          return const Center(child: Text('No equipment found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) => ListTile(
            title: Text(list[i].name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete equipment?'),
                    content: Text('Remove “${list[i].name}”?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final admin =
                  await AuthService.instance.currentUserProfile();
                  await EquipmentService.instance
                      .deleteEquipment(list[i].id, admin!);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
