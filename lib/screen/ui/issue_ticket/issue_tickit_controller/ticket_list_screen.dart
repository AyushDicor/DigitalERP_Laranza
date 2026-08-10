import 'package:digitalerp/app_routes/app_routes.dart';
import 'package:digitalerp/model/get_tickit_list_issue_response_model.dart';
import 'package:digitalerp/screen/ui/home/home_controller.dart';
import 'package:digitalerp/screen/ui/issue_ticket/issue_ticket_screen.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'issue_ticket_controller.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  Color get _color {
    final s = status.toLowerCase();
    if (s.contains('progress')) return newOrangeColor;
    if (s.contains('resolved')) return newGreenColor;
    if (s.contains('closed')) return newTextSecondary;
    if (s.contains('pending')) return newOrangeColor;
    return newBlueColor;
  }

  Color get _bgColor {
    final s = status.toLowerCase();
    if (s.contains('progress')) return newOrangeLightColor;
    if (s.contains('resolved')) return const Color(0xFFD1FAE5);
    if (s.contains('closed')) return newSurfaceColor;
    if (s.contains('pending')) return newOrangeLightColor;
    return newBlueLightColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onFilterTap;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: newBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: newTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search Tickets',
                hintStyle: TextStyle(fontSize: 14, color: newTextHint),
                prefixIcon: Icon(Icons.search_rounded, color: newBlueColor, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: GestureDetector(
              onTap: onFilterTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: newBlueLightColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.filter_list_sharp, color: newBlueColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final Function(String, String, String) onApplyFilter;

  const FilterBottomSheet({super.key, required this.onApplyFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String selectedStatus = 'All';

  final List<String> statusOptions = ['All', 'Open', 'IN PROGRESS', 'ISSUE RESOLVED', 'closed', 'Pending'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Tickets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: newTextPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: newTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: newTextPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusOptions.map((status) {
              final selected = selectedStatus == status;
              return GestureDetector(
                onTap: () => setState(() => selectedStatus = status),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? newBlueColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? newBlueColor : newBorderColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : newTextPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilter(selectedStatus, '', '');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: newBlueColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  CreateIssueTicketController controller = Get.put(CreateIssueTicketController());
  final HomeController homeController = Get.find<HomeController>();

  String currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    controller.getAllIssueTicketList();
  }

  void navigateToCreateTicket() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const IssueTicketForm()));
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        onApplyFilter: (status, from, to) {
          setState(() => currentFilter = status);
          controller.applyFilter(status, from, to);
        },
      ),
    );
  }

  bool isOverdue(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return false;
    try {
      final dueDate = DateFormat("M/d/yyyy h:mm:ss a").parse(dueDateStr);
      return dueDate.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final date = DateFormat("M/d/yyyy h:mm:ss a").parse(raw);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return raw;
    }
  }

  Widget _appBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.home),
            child: Icon(Icons.arrow_back_ios_new, color: newTextPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Tickets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: newTextPrimary)),
                Text('${controller.allIssueTicketList.length} tickets found',
                    style: TextStyle(fontSize: 12, color: newTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip() {
    if (currentFilter == 'All') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: newBlueLightColor, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter: $currentFilter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: newBlueColor)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() => currentFilter = 'All');
                  controller.filteredTickets = controller.allIssueTicketList;
                  controller.update();
                },
                child: Icon(Icons.close_rounded, size: 14, color: newBlueColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: newBlueLightColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: newBlueColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: newTextSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: newTextPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep(String title, String? date, bool isCompleted, IconData icon, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: isCompleted ? newGreenColor : newBorderColor, shape: BoxShape.circle),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: isCompleted ? newGreenColor : newBorderColor),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? newTextPrimary : newTextSecondary)),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(_formatDate(date), style: TextStyle(fontSize: 12, color: newTextSecondary)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTicketDetail(AllIsueTicketList ticket) {
    const order = ['Created', 'IN PROGRESS', 'ISSUE RESOLVED', 'closed'];
    bool stepCompleted(String? status, String step) {
      if (status == null || status.isEmpty) return step == 'Created';
      final currentIndex = order.indexOf(status);
      final stepIndex = order.indexOf(step);
      if (currentIndex == -1) return step == 'Created';
      return stepIndex <= currentIndex;
    }

    final status = ticket.status ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 5,
                        width: 44,
                        decoration:
                            BoxDecoration(color: newBorderColor, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: newBlueLightColor, borderRadius: BorderRadius.circular(22)),
                          child: Icon(Icons.confirmation_number_outlined, color: newBlueColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.complain ?? 'Ticket',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: newTextPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((ticket.customer ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(ticket.customer!,
                                    style: TextStyle(fontSize: 13, color: newTextSecondary)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _infoBlock('Ticket No', '#${ticket.ticketNo ?? 'N/A'}'),
                        const SizedBox(width: 10),
                        _infoBlock('Issue Type', ticket.complaintype ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _infoBlock('Status', (ticket.status?.isEmpty ?? true) ? 'Pending' : ticket.status!),
                        const SizedBox(width: 10),
                        _infoBlock('Due Date', _formatDate(ticket.dueDate)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: newTextPrimary)),
                    const SizedBox(height: 14),
                    _timelineStep('closed', status == 'closed' ? ticket.dueDate : null,
                        stepCompleted(status, 'closed'), Icons.check_circle_outline),
                    _timelineStep(
                        'Issue Resolved',
                        (status == 'ISSUE RESOLVED' || status == 'closed') ? ticket.dueDate : null,
                        stepCompleted(status, 'ISSUE RESOLVED'),
                        Icons.verified_outlined),
                    _timelineStep('In Progress', ticket.createDate, stepCompleted(status, 'IN PROGRESS'),
                        Icons.build_outlined),
                    _timelineStep('Created', ticket.createDate, stepCompleted(status, 'Created'),
                        Icons.edit_calendar_outlined,
                        isLast: true),
                    if (status == 'ISSUE RESOLVED') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                  color: newSurfaceColor, borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: Text('Awaiting your confirmation',
                                  style: TextStyle(fontSize: 12, color: newTextSecondary)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showFeedbackSheet(ticket);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration:
                                  BoxDecoration(color: newBlueColor, borderRadius: BorderRadius.circular(10)),
                              child: Text('Confirm',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedbackSheet(AllIsueTicketList ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: GetBuilder<CreateIssueTicketController>(
              builder: (controller) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 44,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration:
                        BoxDecoration(color: newBorderColor, borderRadius: BorderRadius.circular(10)),
                  ),
                  Text('Rate Ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: newTextPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          controller.rating = index + 1;
                          controller.update();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < controller.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 34,
                            color: Colors.amber,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: newBorderColor),
                    ),
                    child: TextField(
                      controller: controller.feedbackController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: newTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write your feedback...',
                        hintStyle: TextStyle(color: newTextHint, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: newBlueColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => controller.updateTicketEntryApi(context, ticket.ticketNo.toString()),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ticketCard(AllIsueTicketList ticket) {
    final status = ticket.status ?? '';
    final overdue = isOverdue(ticket.dueDate);
    return GestureDetector(
      onTap: () => _showTicketDetail(ticket),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: overdue ? newRedColor.withValues(alpha: 0.4) : newBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration:
                        BoxDecoration(color: newBlueLightColor, borderRadius: BorderRadius.circular(8)),
                    child: Text('#${ticket.ticketNo ?? ''}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: newBlueColor)),
                  ),
                  const Spacer(),
                  if (overdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration:
                          BoxDecoration(color: newRedLightColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: newRedColor),
                          const SizedBox(width: 4),
                          Text('Overdue',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: newRedColor)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.complain ?? '',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: newTextPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business_rounded, size: 13, color: newTextSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      homeController.currentUserData?.usertype == 'Admin'
                          ? (ticket.customer ?? '')
                          : (ticket.complain ?? ''),
                      style: TextStyle(fontSize: 12, color: newTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.category_rounded, size: 13, color: newTextSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      ticket.complaintype ?? '',
                      style: TextStyle(fontSize: 12, color: newTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEFF2F7)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: newTextSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Created: ${_formatDate(ticket.createDate)}',
                                style: TextStyle(fontSize: 11, color: newTextSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: overdue ? newRedColor : newTextSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Due: ${_formatDate(ticket.dueDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: overdue ? newRedColor : newTextSecondary,
                                  fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: status.isEmpty ? 'Pending' : status),
                ],
              ),
              if (status == 'ISSUE RESOLVED') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration:
                      BoxDecoration(color: newOrangeLightColor, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: newOrangeColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Resolved — tap to confirm & rate',
                            style:
                                TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: newOrangeColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateIssueTicketController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          floatingActionButton: FloatingActionButton(
            backgroundColor: purpleColor,
            elevation: 3,
            shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2.5)),
            onPressed: () => navigateToCreateTicket(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _appBar(),
                CustomSearchBar(
                  controller: controller.searchController,
                  onChanged: (query) => controller.filterTickets(query),
                  onFilterTap: showFilterBottomSheet,
                ),
                _filterChip(),
                const SizedBox(height: 4),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.filteredTickets.isEmpty
                          ? Center(
                              child: Text('No Tickets Found',
                                  style: TextStyle(fontSize: 14, color: newTextSecondary)),
                            )
                          : RefreshIndicator(
                              onRefresh: () => controller.getAllIssueTicketList(),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 90),
                                itemCount: controller.filteredTickets.length,
                                itemBuilder: (context, index) =>
                                    _ticketCard(controller.filteredTickets[index]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
