import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/access_view_model.dart';
import '../providers/share_view_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/share_modal.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Access',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (modalContext) {
              return ChangeNotifierProvider(
                create: (_) => ShareViewModel(),
                child: ShareModal(
                  onShowSnackBar: (message) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        backgroundColor: const Color(0xFF5B2E5A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AccessViewModel>(
        builder: (context, viewModel, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.doctorList.length,
            itemBuilder: (context, index) {
              final doctor = viewModel.doctorList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: doctor.profileImageUrl.isNotEmpty
                                ? NetworkImage(doctor.profileImageUrl)
                                : null,
                            child: doctor.profileImageUrl.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 10),

                          /// LEFT SIDE INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor.phone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// RIGHT SIDE ACCESS TILL
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Access Till',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6EEDC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  doctor.accessTill,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// STATS
                      Row(
                        children: [
                          _buildStat('Reports', doctor.reports.toString()),
                          const SizedBox(width: 20),
                          _buildStat('Prescriptions', doctor.prescriptions.toString()),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// ACCESS DATE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Access Date: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                doctor.accessDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          /// BUTTON (RIGHT SIDE SMALL)
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () {
                                viewModel.updateAccess(doctor.id);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF5B2E5A),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text(
                                'Update Access',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5B2E5A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
