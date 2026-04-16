import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/treasury_payment_model.dart';
import '../../services/treasury_service.dart';
import '../../services/user_service.dart';
import '../../services/email_service.dart';
import '../../providers/user_provider.dart';
// import '../../theme/app_theme.dart'; // Asumiendo que existe, si no usaré colores directos

/// Tab de registro de pagos de tesorería (Flujo Persona-Céntrico)
class PaymentRegistrationTab extends ConsumerStatefulWidget {
  final TreasuryService treasuryService;

  const PaymentRegistrationTab({
    super.key,
    required this.treasuryService,
  });

  @override
  ConsumerState<PaymentRegistrationTab> createState() => _PaymentRegistrationTabState();
}

class _PaymentRegistrationTabState extends ConsumerState<PaymentRegistrationTab> {
  final UserService _userService = UserService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

  // Estado de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _searchResults = [];

  // Estado de KPIs
  bool _isKPIsExpanded = false;
  Map<String, dynamic> _monthSummary = {};
  bool _isLoadingKPIs = false;

  // Cache de todos los usuarios para búsqueda local rápida
  List<UserModel> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingKPIs = true);
    try {
      // Cargar KPIs del mes actual
      final now = DateTime.now();
      _monthSummary = await widget.treasuryService.getMonthSummary(
        month: now.month,
        year: now.year,
      );

      // Cargar todos los usuarios para búsqueda local
      _allUsers = await _userService.getAllUsers();
      _searchResults = List.from(_allUsers); // Inicialmente mostrar todos o vacio? Mejor todos ordenados

    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingKPIs = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = List.from(_allUsers);
      } else {
        final lowerQuery = query.toLowerCase();
        _searchResults = _allUsers.where((user) {
          return user.fullName.toLowerCase().contains(lowerQuery) ||
                 user.rut.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildKPIsSection(),
        _buildSearchBar(),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildKPIsSection() {
    return ExpansionTile(
      title: const Text(
        'Resumen del Mes Actual',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: _isKPIsExpanded,
      onExpansionChanged: (expanded) => setState(() => _isKPIsExpanded = expanded),
      children: [
        if (_isLoadingKPIs)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKPIItem(
                  'Total Usuarios',
                  '${_monthSummary['total_users'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildKPIItem(
                  'Pagados',
                  '${_monthSummary['paid_count'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildKPIItem(
                  'Pendientes',
                  '${_monthSummary['pending_count'] ?? 0}',
                  Icons.pending,
                  Colors.orange,
                ),
                _buildKPIItem(
                  'Recaudado',
                  _currencyFormat.format(_monthSummary['total_collected'] ?? 0),
                  Icons.attach_money,
                  Colors.green.shade700,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKPIItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Buscar bombero por nombre o RUT',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No se encontraron bomberos',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserListTile(
          user: user,
          onTap: () => _showUserDetail(user),
          treasuryService: widget.treasuryService, // Pasamos el servicio para que el tile pueda cargar estado mini si quisiéramos, pero por ahora solo onTap
        );
      },
    );
  }

  Future<void> _showUserDetail(UserModel user) async {
    // Mostrar diálogo de carga o abrir directamente con future builder
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final accountStatus = await widget.treasuryService.getUserAccountStatus(user.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Abrir panel de detalle (usando un Dialog full width o BottomSheet grande)
      await showDialog(
        context: context,
        builder: (context) => _UserDetailDialog(
          user: user,
          accountStatus: accountStatus,
          treasuryService: widget.treasuryService,
          currentUser: ref.read(currentUserProvider)!,
          onPaymentSuccess: () {
             // Recargar datos globales si es necesario
             _loadInitialData();
          },
        ),
      );

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estado de cuenta: $e')),
        );
      }
    }
  }
}

/// Tile simple para la lista de resultados
class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final TreasuryService treasuryService;

  const _UserListTile({
    required this.user,
    required this.onTap,
    required this.treasuryService,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade700,
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user.fullName),
      subtitle: Text('${user.rank} | ${user.rut}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

/// Diálogo de detalle del usuario y su estado de cuenta
class _UserDetailDialog extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> accountStatus;
  final TreasuryService treasuryService;
  final UserModel currentUser;
  final VoidCallback onPaymentSuccess;

  const _UserDetailDialog({
    required this.user,
    required this.accountStatus,
    required this.treasuryService,
    required this.currentUser,
    required this.onPaymentSuccess,
  });

  @override
  State<_UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<_UserDetailDialog> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$');
  late Map<String, dynamic> _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.accountStatus;
  }
  
  Future<void> _refreshStatus() async {
    try {
      final newStatus = await widget.treasuryService.getUserAccountStatus(widget.user.id);
      if (mounted) {
        setState(() => _currentStatus = newStatus);
      }
    } catch (e) {
      debugPrint('Error refreshing status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotas = (_currentStatus['quotas'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalDebt = _currentStatus['total_debt'] ?? 0;
    final monthsOwed = _currentStatus['months_owed'] ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                   CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.red.shade700,
                    child: Text(
                      widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text('${widget.user.rank} | ${widget.user.rut}'),
                         if (widget.user.isStudent)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Estudiante', style: TextStyle(fontSize: 12, color: Colors.blue)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Resumen de Deuda
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEUDA TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        _currencyFormat.format(totalDebt),
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: totalDebt > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        totalDebt > 0 ? '$monthsOwed meses pendientes' : 'Al día',
                         style: TextStyle(
                          color: totalDebt > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRegisterPaymentDialog(totalDebt),
                    icon: const Icon(Icons.payment),
                    label: const Text('REGISTRAR PAGO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Tabla de Cuotas
            Expanded(
              child: quotas.isEmpty
                  ? const Center(child: Text('No hay cuotas registradas'))
                  : _buildQuotasList(quotas),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotasList(List<Map<String, dynamic>> quotas) {
    // Agrupar cuotas por año
    final groupedQuotas = <int, List<Map<String, dynamic>>>{};
    for (var quota in quotas) {
      final year = quota['year'] as int;
      if (!groupedQuotas.containsKey(year)) {
        groupedQuotas[year] = [];
      }
      groupedQuotas[year]!.add(quota);
    }

    // Ordenar años descendente
    final sortedYears = groupedQuotas.keys.toList()..sort((a, b) => b.compareTo(a));
    final currentYear = DateTime.now().year;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedYears.length,
      itemBuilder: (context, index) {
        final year = sortedYears[index];
        final yearQuotas = groupedQuotas[year]!;
        
        // Ordenar cuotas del año por mes
        yearQuotas.sort((a, b) => (a['month'] as int).compareTo(b['month'] as int));

        final totalQuotas = yearQuotas.length;
        final paidQuotas = yearQuotas.where((q) => q['status'] == 'paid').length;
        final isComplete = paidQuotas == totalQuotas;
        final isCurrentOrFuture = year >= currentYear;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isCurrentOrFuture ? 2 : 1,
          color: isCurrentOrFuture ? Colors.white : Colors.grey.shade50,
          child: ExpansionTile(
            initiallyExpanded: isCurrentOrFuture,
            title: Text(
              '$year',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isCurrentOrFuture ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
            subtitle: Text(
              isComplete 
                ? '$paidQuotas/$totalQuotas pagados ✅' 
                : '$paidQuotas/$totalQuotas pagados (${totalQuotas - paidQuotas} pendientes)',
              style: TextStyle(
                color: isComplete ? Colors.green : Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: yearQuotas.map((quota) {
              final status = quota['status'] ?? 'pending';
              final isPaid = status == 'paid';
              final isPartial = status == 'partial';
              
              Color bgColor = Colors.transparent;
              IconData icon = Icons.pending_outlined;
              Color iconColor = Colors.grey;

              if (isPaid) {
                bgColor = Colors.green.shade50;
                icon = Icons.check_circle;
                iconColor = Colors.green;
              } else if (isPartial) {
                bgColor = Colors.orange.shade50;
                icon = Icons.pie_chart;
                iconColor = Colors.orange;
              } else if (status == 'current') {
                bgColor = Colors.blue.shade50;
                icon = Icons.today;
                iconColor = Colors.blue;
              } else {
                // Pending (vencida)
                 icon = Icons.warning_amber;
                 iconColor = Colors.red;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(
                    _getMonthName(quota['month']),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(quota['paid_amount'] ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.black),
                        ),
                      ),
                      Text(
                        'de ${_currencyFormat.format(quota['expected_amount'] ?? 0)}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Future<void> _showRegisterPaymentDialog(int totalDebt) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PaymentAmountDialog(
        user: widget.user,
        suggestedAmount: totalDebt > 0 ? totalDebt : 0,
        treasuryService: widget.treasuryService,
        currentUser: widget.currentUser,
      ),
    );

    if (result == true) {
      await _refreshStatus();
      widget.onPaymentSuccess();
    }
  }
}

/// Diálogo para ingresar el monto y confirmar el pago
class _PaymentAmountDialog extends StatefulWidget {
  final UserModel user;
  final int suggestedAmount;
  final TreasuryService treasuryService;
  final UserModel currentUser;

  const _PaymentAmountDialog({
    required this.user,
    required this.suggestedAmount,
    required this.treasuryService,
    required this.currentUser,
  });

  @override
  State<_PaymentAmountDialog> createState() => _PaymentAmountDialogState();
}

class _PaymentAmountDialogState extends State<_PaymentAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _emailService = EmailService();
  
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedAmount > 0) {
      _amountController.text = widget.suggestedAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      // Llamar al servicio de distribución automática
      final result = await widget.treasuryService.distributePaymentFromOldest(
        userId: widget.user.id,
        totalAmount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        receiptNumber: _receiptController.text.isEmpty ? null : _receiptController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        registeredBy: widget.currentUser.id,
      );

      // Enviar correos de notificación
      await _sendPaymentNotifications(amount, result);

      if (mounted) {
        Navigator.pop(context, true); // Cerramos el de ingreso
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error procesando pago: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendPaymentNotifications(int amount, Map<String, dynamic> result) async {
    try {
      final distribution = result['distribution'] as List;
      if (distribution.isEmpty) return;

      const monthNames = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];

      final descriptions = <String>[];
      int? firstYear;
      int? lastYear;

      for (var d in distribution) {
        final monthIndex = (d['month'] as int) - 1;
        final year = d['year'] as int;
        firstYear ??= year;
        lastYear = year;

        if (monthIndex >= 0 && monthIndex < monthNames.length) {
          final monthName = monthNames[monthIndex];
          final needsYear = firstYear != lastYear;
          final label = d['new_status'] == 'paid' ? monthName : 'abono $monthName';
          descriptions.add(needsYear ? '$label $year' : label);
        }
      }

      String monthsDetail;
      if (descriptions.length == 1) {
        monthsDetail = descriptions.first;
      } else {
        final last = descriptions.removeLast();
        monthsDetail = '${descriptions.join(", ")} y $last';
      }

      final paymentYear = firstYear ?? DateTime.now().year;

      final userEmail = widget.user.email;
      final hasValidEmail = userEmail != null && userEmail.isNotEmpty;

      final emailSent = await _emailService.sendPaymentConfirmationNotification(
        userEmail: hasValidEmail ? userEmail : 'tesoreriasextacompania@gmail.com',
        userName: widget.user.fullName,
        paidAmount: amount,
        paymentDate: _dateFormat.format(_paymentDate),
        month: monthsDetail,
        year: paymentYear,
      );

      if (emailSent) {
        print('✅ Correo de pago enviado correctamente');
      } else {
        print('⚠️ No se pudo enviar correo de pago');
      }
    } catch (e) {
      print('⚠️ Error enviando correos de pago: $e');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Pago Registrado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Se han distribuido \$${result['total_applied']} en ${result['distribution'].length} cuotas.'),
              if ((result['remaining'] ?? 0) > 0)
                 Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  color: Colors.yellow.shade100,
                  child: Text(
                    'ATENCIÓN: Sobraron \$${result['remaining']}. ${result['remaining_note']}',
                    style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold),
                  ),
                 ),
              const SizedBox(height: 16),
              const Text('Detalle:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...List<Widget>.from((result['distribution'] as List).map((d) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${d['month']}/${d['year']}'),
                      Text('\$${d['amount_applied']}'),
                      Text(
                        d['new_status'] == 'paid' ? 'PAGADO' : 'ABONADO',
                        style: TextStyle(
                          fontSize: 10,
                          color: d['new_status'] == 'paid' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar Pago - ${widget.user.fullName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese monto';
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: TextEditingController(text: _dateFormat.format(_paymentDate)),
                decoration: const InputDecoration(
                  labelText: 'Fecha del pago',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaymentMethod>(
                    value: _paymentMethod,
                    isDense: true,
                    items: PaymentMethod.values.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiptController,
                decoration: const InputDecoration(
                  labelText: 'N° Comprobante (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
           style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
          child: _isProcessing 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('REGISTRAR'),
        ),
      ],
    );
  }
}
