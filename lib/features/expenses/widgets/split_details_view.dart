import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/features/expenses/screens/add_edit_expense_screen.dart';

class SplitDetailsView extends StatefulWidget {
  final List<UserPublicInfo> participants;
  final Set<int> selectedParticipants;
  final Map<int, double> splits;
  final SplitMethod splitMethod;
  final double totalAmount;
  final String currency;
  final Function(Map<int, double>) onSplitUpdated;
  final String Function(String) getCurrencyCode;
  final double Function() remainingToSplit;

  const SplitDetailsView({
    super.key,
    required this.participants,
    required this.selectedParticipants,
    required this.splits,
    required this.splitMethod,
    required this.totalAmount,
    required this.currency,
    required this.onSplitUpdated,
    required this.getCurrencyCode,
    required this.remainingToSplit,
  });

  @override
  State<SplitDetailsView> createState() => _SplitDetailsViewState();
}

class _SplitDetailsViewState extends State<SplitDetailsView> {
  late TextEditingController _searchController;
  late List<UserPublicInfo> _filteredParticipants;

  // void _updateSplit(int userId, double value) {
  //   setState(() {
  //     widget.splits[userId] = value;
  //     widget.onSplitUpdated(widget.splits);
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredParticipants = widget.participants
        .where((p) => widget.selectedParticipants.contains(p.userId))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterParticipants(String query) {
    setState(() {
      _filteredParticipants = widget.participants
          .where((p) =>
              widget.selectedParticipants.contains(p.userId) &&
              (p.fullName?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(
              'Split Details - ${widget.splitMethod.toString().split('.').last.capitalize()}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.onSplitUpdated(widget.splits);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Remaining to split: ${widget.remainingToSplit().toStringAsFixed(2)} ${widget.currency}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.remainingToSplit() == 0
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Participants',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterParticipants,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredParticipants.length,
            itemBuilder: (context, index) {
              final user = _filteredParticipants[index];
              return _buildSplitItem(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplitItem(UserPublicInfo user) {
    double splitValue = widget.splits[user.userId] ?? 0;
    double amount = 0;
    String splitDisplay;
    bool isReadOnly = widget.splitMethod == SplitMethod.equal;
    IconData? prefixIcon;

    switch (widget.splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.unequal:
        amount = splitValue;
        splitDisplay =
            '${amount.toStringAsFixed(2)} ${widget.getCurrencyCode(widget.currency)}';
        break;
      case SplitMethod.percentage:
        amount = widget.totalAmount * splitValue / 100;
        splitDisplay =
            '${splitValue.toStringAsFixed(2)}% (${amount.toStringAsFixed(2)} ${widget.getCurrencyCode(widget.currency)})';
        break;
      case SplitMethod.shares:
        int totalShares =
            widget.splits.values.fold(0, (sum, value) => sum + value.round());
        amount =
            totalShares > 0 ? widget.totalAmount * splitValue / totalShares : 0;
        splitDisplay =
            '${splitValue.round()} shares (${amount.toStringAsFixed(2)} ${widget.getCurrencyCode(widget.currency)})';
        prefixIcon = Icons.pie_chart;
        break;
    }

    return ListTile(
      title: Text(user.fullName ?? 'User ${user.userId}'),
      subtitle: Text(splitDisplay),
      trailing: SizedBox(
        width: 100,
        child: TextFormField(
          initialValue: splitValue.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: isReadOnly,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: widget.splitMethod == SplitMethod.percentage
                ? '%'
                : widget.splitMethod == SplitMethod.shares
                    ? 'Shares'
                    : widget.getCurrencyCode(widget.currency),
            hintText: 'Enter amount',
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          ),
          onChanged: (value) {
            double newValue = double.tryParse(value) ?? 0;
            widget.onSplitUpdated({...widget.splits, user.userId: newValue});
          },
        ),
      ),
    );
  }
}
