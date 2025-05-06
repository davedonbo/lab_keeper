import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../models/borrow_request.dart';
import '../../models/borrow_status.dart';
import '../widgets/student_request_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 4, vsync: this);
  late final Future<String> _uidFut =
  AuthService.instance.currentUserProfile().then((u) => u!.uid);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: FutureBuilder<String>(
        future: AuthService.instance.currentUserProfile()
            .then((u) => u!.name.split(' ').first),
        builder: (_, s) =>
            Text(s.hasData ? 'Hi, ${s.data}' : 'Dashboard'),
      ),
      actions: [
        IconButton(
          tooltip: 'Call Admin',
          icon: const Icon(Icons.phone_in_talk),
          onPressed: () => _showAdminDialSheet(context),
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
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Approved'),
          Tab(text: 'Returned'),
        ],
      ),
    ),
    body: FutureBuilder<String>(
      future: _uidFut,
      builder: (_, uidSnap) {
        if (!uidSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('userID', isEqualTo: uidSnap.data!);

        return StreamBuilder<QuerySnapshot>(
          stream: q.snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snap.data!.docs
                .map((d) => BorrowRequest.fromJson(
              d.id,
              d.data()! as Map<String, dynamic>,
            ))
                .toList();
            final pending =
            all.where((r) => r.status == BorrowStatus.pending).toList();
            final approved =
            all.where((r) => r.status == BorrowStatus.approved).toList();
            final returned =
            all.where((r) => r.status == BorrowStatus.returned).toList();

            return TabBarView(
              controller: tabs,
              children: [
                _RequestTab(
                    title: 'Total Requests',
                    icon: Icons.inventory_2_outlined,
                    requests: all),
                _RequestTab(
                    title: 'Pending',
                    icon: Icons.schedule,
                    requests: pending),
                _RequestTab(
                    title: 'Approved',
                    icon: Icons.check_circle_outline,
                    requests: approved),
                _RequestTab(
                    title: 'Returned',
                    icon: Icons.assignment_turned_in_outlined,
                    requests: returned),
              ],
            );
          },
        );
      },
    ),
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'beaconFab',
          tooltip: 'Show Beacon',
          child: const Icon(Icons.wifi_tethering),
          onPressed: () => Navigator.pushNamed(context, '/beacon'),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'requestFab',
          icon: const Icon(Icons.add),
          label: const Text('Request'),
          onPressed: () => Navigator.pushNamed(context, '/borrow'),
        ),
      ],
    ),
  );
}

/*──────── reusable request‑list tab ─────────*/
class _RequestTab extends StatelessWidget {
  const _RequestTab(
      {required this.title, required this.icon, required this.requests});
  final String title;
  final IconData icon;
  final List<BorrowRequest> requests;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Card(
          elevation: 1,
          child: ListTile(
            leading:
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            title: Text(title),
            trailing: Text(
              requests.length.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: requests.isEmpty
            ? const Center(child: Text('No requests found'))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = requests[i];
            return ListTile(
              title: Text(
                  'Request ${r.id.substring(0, 6).toUpperCase()}'),
              subtitle: Text(r.status.value),
              trailing: Text(
                  '${r.borrowDate.day}/${r.borrowDate.month}/${r.borrowDate.year}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudentRequestDetailPage(request: r),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

/*──────── call‑admin bottom‑sheet ─────────*/
void _showAdminDialSheet(BuildContext ctx) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'Admin')
      .get();

  if (snap.docs.isEmpty) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('No admins available')),
    );
    return;
  }

  showModalBottomSheet(
    context: ctx,
    shape:
    const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 5,),
        Text('LabKeeper Admins', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
        ListView(
          shrinkWrap: true,
          children: snap.docs.map((d) {
            final name = d['name'];
            final phone = d['phone'];
            return ListTile(
              title: Text(name),
              subtitle: Text(phone),
              trailing: const Icon(Icons.call),
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
