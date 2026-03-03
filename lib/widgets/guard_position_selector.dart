import 'package:flutter/material.dart';
import 'package:sexta_app/models/user_model.dart';

/// Reusable widget for selecting a user for a guard position
/// Features: dropdown with search, displays Victor number and name
class GuardPositionSelector extends StatelessWidget {
  final String label;
  final String? selectedUserId;
  final List<UserModel> availableUsers;
  final Function(String?) onChanged;
  final bool isRequired;
  final String? helperText;

  const GuardPositionSelector({
    Key? key,
    required this.label,
    this.selectedUserId,
    required this.availableUsers,
    required this.onChanged,
    this.isRequired = false,
    this.helperText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedUserId,
          decoration: InputDecoration(
            hintText: 'Seleccionar...',
            helperText: helperText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          isExpanded: true,
          items: [
            // Empty option
            const DropdownMenuItem<String>(
              value: null,
              child: Text('(Vacío)', style: TextStyle(color: Colors.grey)),
            ),
            // User options
            ...availableUsers.map((user) {
              return DropdownMenuItem<String>(
                value: user.id,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'V-${user.victorNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

/// Searchable user selector dialog for large user lists
class SearchableUserSelector extends StatefulWidget {
  final String title;
  final List<UserModel> users;
  final String? selectedUserId;

  const SearchableUserSelector({
    Key? key,
    required this.title,
    required this.users,
    this.selectedUserId,
  }) : super(key: key);

  @override
  State<SearchableUserSelector> createState() => _SearchableUserSelectorState();
}

class _SearchableUserSelectorState extends State<SearchableUserSelector> {
  late List<UserModel> filteredUsers;
  late List<UserModel> _processedUsers;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // FIX 2: Filtrar postulantes y aspirantes
    // FIX 3: Orden alfabético A-Z
    _processedUsers = widget.users.where((u) {
      final rank = (u.rank ?? '').toLowerCase();
      return !rank.contains('postulante') && !rank.contains('aspirante');
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
      
    filteredUsers = List.from(_processedUsers);
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = _processedUsers;
      } else {
        filteredUsers = _processedUsers.where((user) {
          final nameLower = user.fullName.toLowerCase();
          final queryLower = query.toLowerCase();
          final victorStr = user.victorNumber.toString();
          return nameLower.contains(queryLower) || victorStr.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o número Victor...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterUsers,
            ),
            const SizedBox(height: 16),

            // Clear selection option
            ListTile(
              leading: const Icon(Icons.clear, color: Colors.grey),
              title: const Text('(Vacío)'),
              onTap: () => Navigator.pop(context, null),
              tileColor: widget.selectedUserId == null
                  ? Colors.blue.shade50
                  : null,
            ),
            const Divider(),

            // User list
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(
                      child: Text('No se encontraron usuarios'),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = user.id == widget.selectedUserId;

                        return ListTile(
                          // FIX 1: Quitar círculo azul con número Victor
                          // leading: CircleAvatar(...),
                          title: Text(user.fullName),
                          subtitle: Text(user.rank),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                          tileColor: isSelected ? Colors.blue.shade50 : null,
                          onTap: () => Navigator.pop(context, user.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

/// Show searchable user selector dialog
Future<String?> showUserSelectorDialog({
  required BuildContext context,
  required String title,
  required List<UserModel> users,
  String? selectedUserId,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => SearchableUserSelector(
      title: title,
      users: users,
      selectedUserId: selectedUserId,
    ),
  );
}
