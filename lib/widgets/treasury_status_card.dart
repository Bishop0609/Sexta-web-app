import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/treasury_service.dart';
import '../../core/theme/app_theme.dart';

/// Widget que muestra el estado de deudas del usuario en su perfil
class TreasuryStatusCard extends StatefulWidget {
  final UserModel user;

  const TreasuryStatusCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<TreasuryStatusCard> createState() => _TreasuryStatusCardState();
}

class _TreasuryStatusCardState extends State<TreasuryStatusCard> {
  final TreasuryService _treasuryService = TreasuryService();
  bool _isLoading = true;
  int _monthsOwed = 0;
  int _totalAmount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDebtInfo();
  }

  Future<void> _loadDebtInfo() async {
    // Si el usuario no tiene fecha de inicio de pagos, no debe cuotas
    if (widget.user.paymentStartDate == null) {
      setState(() {
        _isLoading = false;
        _monthsOwed = 0;
        _totalAmount = 0;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final debtInfo = await _treasuryService.calculateUserDebt(widget.user.id);
      
      setState(() {
        _monthsOwed = debtInfo['months_owed'] ?? 0;
        _totalAmount = debtInfo['total_amount'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar información de deudas';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    return '\$${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${now.day} de ${months[now.month - 1]} de ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Si no tiene fecha de inicio de pagos, no mostrar nada
    if (widget.user.paymentStartDate == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final hasDebt = _monthsOwed > 0;
    final cardColor = hasDebt ? Colors.red.shade50 : Colors.green.shade50;
    final iconColor = hasDebt ? Colors.red : Colors.green;
    final icon = hasDebt ? Icons.warning_amber : Icons.check_circle;

    return Card(
      color: cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tesorería',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDebtInfo,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            if (hasDebt) ...[
              // Mensaje de deuda
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(text: 'A la fecha de hoy '),
                    TextSpan(
                      text: _getCurrentDate(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' usted tiene una deuda de '),
                    TextSpan(
                      text: '$_monthsOwed ${_monthsOwed == 1 ? 'mes' : 'meses'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(text: ' de cuotas lo que corresponde a '),
                    TextSpan(
                      text: _formatCurrency(_totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(
                      text: ', contáctese con el Tesorero para regularizar.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.institutionalRed,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.payment, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Datos para Pago de Cuotas',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            // Payment image
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/images/payment_info.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'Error al cargar imagen de pago.\nContacte al tesorero.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Close button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CERRAR'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance),
                label: const Text('Datos de Pago'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ] else ...[
              // Mensaje sin deuda
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(text: 'A la fecha de hoy '),
                    TextSpan(
                      text: _getCurrentDate(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' usted '),
                    const TextSpan(
                      text: 'NO tiene deudas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const TextSpan(text: ' de cuotas mensuales. '),
                    const TextSpan(
                      text: 'Siga estando al día.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '¡Excelente!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
