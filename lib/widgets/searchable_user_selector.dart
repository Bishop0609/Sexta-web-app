import 'package:flutter/material.dart';
import 'package:sexta_app/models/user_model.dart';

/// Searchable user selector widget
/// Opens a dialog with search field to filter users by name/lastname
class SearchableUserSelector extends StatefulWidget {
  final String label;
  final String? selectedUserId;
  final List<UserModel> availableUsers;
  final ValueChanged<String?> onChanged;
  final bool required;

  const SearchableUserSelector({
    Key? key,
    required this.label,
    this.selectedUserId,
    required this.availableUsers,
    required this.onChanged,
    this.required = false,
  }) : super(key: key);

  @override
  State<SearchableUserSelector> createState() => _SearchableUserSelectorState();
}

class _SearchableUserSelectorState extends State<SearchableUserSelector> {
  Future<void> _showSearchDialog() async {
    final selected = await showDialog<UserModel>(
      context: context,
      builder: (context) => _UserSearchDialog(
        availableUsers: widget.availableUsers,
        currentSelectedId: widget.selectedUserId,
      ),
    );

    if (selected != null) {
      widget.onChanged(selected.id);
    }
  }

  UserModel? get _selectedUser {
    if (widget.selectedUserId == null) return null;
    try {
      return widget.availableUsers.firstWhere(
        (user) => user.id == widget.selectedUserId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = _selectedUser;

    return InkWell(
      onTap: _showSearchDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: selectedUser != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => widget.onChanged(null),
                )
              : const Icon(Icons.search),
          errorText: widget.required && selectedUser == null
              ? 'Campo requerido'
              : null,
        ),
        child: Text(
          selectedUser?.fullName ?? 'Seleccionar...',
          style: TextStyle(
            fontSize: 16,
            color: selectedUser != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Dialog for searching and selecting a user
class _UserSearchDialog extends StatefulWidget {
  final List<UserModel> availableUsers;
  final String? currentSelectedId;

  const _UserSearchDialog({
    required this.availableUsers,
    this.currentSelectedId,
  });

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.availableUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.availableUsers;
      } else {
        _filteredUsers = widget.availableUsers.where((user) {
          final fullName = user.fullName.toLowerCase();
          final firstName = user.firstName.toLowerCase();
          final lastName = user.lastName.toLowerCase();

          return fullName.contains(query) ||
              firstName.contains(query) ||
              lastName.contains(query);
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
                const Expanded(
                  child: Text(
                    'Buscar Usuario',
                    style: TextStyle(
                      fontSize: 20,
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
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o apellido...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Results count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredUsers.length} resultado(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // User list
            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron usuarios',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isSelected = user.id == widget.currentSelectedId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            child: Text(
                              user.firstName[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(user.rank),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                          selected: isSelected,
                          onTap: () => Navigator.pop(context, user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
