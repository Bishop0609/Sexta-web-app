import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sexta_app/core/constants/app_constants.dart';

/// Service for sending emails via Resend API
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _baseUrl = 'https://api.resend.com/emails';

  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppConstants.resendApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': AppConstants.resendFromEmail,
          'to': [to],
          'subject': subject,
          'html': htmlContent,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  /// Notifica a los oficiales sobre una nueva solicitud de permiso
  Future<bool> sendPermissionRequestNotification({
    required String officerEmail,
    required String firefighterName,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #D32F2F; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
    .button { 
      display: inline-block; 
      background-color: #D32F2F; 
      color: white; 
      padding: 12px 24px; 
      text-decoration: none; 
      border-radius: 4px; 
      margin: 10px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Nueva Solicitud de Permiso</h1>
    </div>
    <div class="content">
      <p><strong>Bombero:</strong> $firefighterName</p>
      <p><strong>Período:</strong> $startDate - $endDate</p>
      <p><strong>Motivo:</strong></p>
      <p>$reason</p>
    </div>
    <p style="text-align: center;">
      <a href="#" class="button">Revisar Solicitud</a>
    </p>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: officerEmail,
      subject: 'Nueva Solicitud de Permiso - $firefighterName',
      htmlContent: htmlContent,
    );
  }

  /// Notifica al bombero sobre la decisión de su permiso
  Future<bool> sendPermissionDecisionNotification({
    required String firefighterEmail,
    required String firefighterName,
    required bool approved,
    String? rejectionReason,
  }) async {
    final status = approved ? 'APROBADA' : 'RECHAZADA';
    final statusColor = approved ? '#2E7D32' : '#C62828';
    final message = approved 
        ? 'Tu solicitud de permiso ha sido aprobada.'
        : 'Tu solicitud de permiso ha sido rechazada.';
    
    final rejectionSection = !approved && rejectionReason != null
        ? '''
        <div style="background-color: #FFEBEE; padding: 15px; border-left: 4px solid #C62828; margin: 15px 0;">
          <p><strong>Motivo del rechazo:</strong></p>
          <p>$rejectionReason</p>
        </div>
        '''
        : '';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #D32F2F; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .status { 
      background-color: $statusColor; 
      color: white; 
      padding: 15px; 
      text-align: center; 
      font-size: 18px; 
      font-weight: bold; 
      border-radius: 4px; 
      margin: 20px 0;
    }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Respuesta a Solicitud de Permiso</h1>
    </div>
    <div class="status">$status</div>
    <div class="content">
      <p>Estimado/a $firefighterName,</p>
      <p>$message</p>
      $rejectionSection
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: firefighterEmail,
      subject: 'Solicitud de Permiso $status',
      htmlContent: htmlContent,
    );
  }

  /// Notifica asignación de guardia
  Future<bool> sendShiftAssignmentNotification({
    required String firefighterEmail,
    required String firefighterName,
    required String shiftDate,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Asignación de Guardia</h1>
    </div>
    <div class="content">
      <p>Estimado/a $firefighterName,</p>
      <p>Se te ha asignado guardia para el día:</p>
      <p style="font-size: 20px; font-weight: bold; text-align: center; color: #1A237E;">
        $shiftDate
      </p>
      <p>Recuerda presentarte puntualmente y realizar el check-in en el sistema.</p>
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: firefighterEmail,
      subject: 'Asignación de Guardia - $shiftDate',
      htmlContent: htmlContent,
    );
  }
Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String fullName,
    required String rut,
    required String tempPassword,
  }) async {
    final html = '''
<html><body style="font-family:Arial">
<div style="max-width:600px;margin:auto;padding:20px">
  <div style="background:#c8102e;color:white;padding:20px;text-align:center">
    <h1>🔥 SEXTA COMPAÑÍA</h1>
  </div>
  <div style="background:#f9f9f9;padding:30px">
    <h2>Bienvenido/a, $fullName</h2>
    <p>Se ha creado tu cuenta.</p>
    <div style="background:white;border:2px solid #c8102e;padding:20px;margin:20px 0">
      <h3>Credenciales</h3>
      <p><strong>RUT:</strong> <code>$rut</code></p>
      <p><strong>Contraseña temporal:</strong> <code>$tempPassword</code></p>
    </div>
    <div style="background:#fff3cd;padding:15px">
      <strong>⚠️</strong> Deberás cambiar tu contraseña en el primer login.
    </div>
  </div>
</div>
</body></html>
    ''';
    
    return await _sendEmail(
      to: userEmail,
      subject: 'Bienvenido - Sexta Compañía',
      htmlContent: html,
    );
  }
}
