import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';

/// Service for sending emails via Resend API
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _baseUrl = 'https://api.resend.com/emails';
  final _supabase = Supabase.instance.client;

  /// Send email via Supabase Edge Function (solves CORS issues)
  Future<bool> _sendViaEdgeFunction({
    required String emailType,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📤 Enviando email via Edge Function: $emailType');
      print('   Datos: $data');
      
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {
          'type': emailType,
          'data': data,
        },
      );

      print('   Response status: ${response.status}');
      print('   Response data: ${response.data}');
      
      if (response.status == 200) {
        print('   ✅ Email enviado exitosamente via Edge Function');
        return true;
      } else {
        print('   ❌ Error: ${response.status} - ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción enviando email via Edge Function: $e');
      return false;
    }
  }

  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      print('📤 Intentando enviar email a: $to');
      print('   From: ${AppConstants.resendFromEmail}');
      print('   Subject: $subject');
      print('   API Key: ${AppConstants.resendApiKey.substring(0, 10)}...');
      
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

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('   ✅ Email enviado exitosamente');
        return true;
      } else {
        print('   ❌ Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción enviando email: $e');
      return false;
    }
  }

  /// Notifica a los oficiales sobre una nueva solicitud de permiso
  Future<bool> sendPermissionRequestNotification({
    required dynamic officerEmail, // Puede ser String o List<String>
    required String firefighterName,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    // Convertir a lista si es String
    final emails = officerEmail is List ? officerEmail : [officerEmail];
    
    return await _sendViaEdgeFunction(
      emailType: 'permission_review',
      data: {
        'officerEmail': emails, // Enviar como array
        'firefighterName': firefighterName,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );
  }

  /// Notifica al bombero sobre la decisión de su permiso
  Future<bool> sendPermissionDecisionNotification({
    required String firefighterEmail,
    required String firefighterName,
    required bool approved,
    required String startDate,
    required String endDate,
    required String reason,
    String? rejectionReason,
  }) async {
    return await _sendViaEdgeFunction(
      emailType: approved ? 'permission_approved' : 'permission_rejected',
      data: {
        'firefighterEmail': firefighterEmail,
        'firefighterName': firefighterName,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      },
    );
  }

  /// Notifica al solicitante que su permiso fue recibido
  Future<bool> sendPermissionSubmittedConfirmation({
    required String userEmail,
    required String firefighterName,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    return await _sendViaEdgeFunction(
      emailType: 'permission_submitted',
      data: {
        'userEmail': userEmail,
        'firefighterName': firefighterName,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
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

  // =====================================================
  // MÓDULO ACTIVIDADES
  // =====================================================

  /// Notifica a todos los usuarios sobre una nueva actividad creada
  Future<bool> sendActivityCreatedNotification({
    required String userEmail,
    required String userName,
    required String activityTitle,
    required String activityType,
    required String activityDate,
    String? activityTime,
    String? location,
    String? description,
  }) async {
    // Lista de emails genéricos a excluir
    const excludedEmails = [
      'notengo@gmail.com',
      'notiene@gmail.com',
    ];
    
    // No enviar a emails excluidos
    if (excludedEmails.contains(userEmail.toLowerCase())) {
      return false;
    }

    // Usar Edge Function en lugar de llamada directa a Resend
    return await _sendViaEdgeFunction(
      emailType: 'activity_created',
      data: {
        'userEmail': userEmail,
        'userName': userName,
        'activityTitle': activityTitle,
        'activityType': activityType,
        'activityDate': activityDate,
        'activityTime': activityTime,
        'location': location,
        'description': description,
      },
    );
  }

  /// Notifica sobre modificación de una actividad
  Future<bool> sendActivityModifiedNotification({
    required String userEmail,
    required String userName,
    required String activityTitle,
    required String activityDate,
    String? activityTime,
  }) async {
    // Usar Edge Function en lugar de llamada directa a Resend
    return await _sendViaEdgeFunction(
      emailType: 'activity_modified',
      data: {
        'userEmail': userEmail,
        'userName': userName,
        'activityTitle': activityTitle,
        'activityDate': activityDate,
        'activityTime': activityTime,
      },
    );
  }

  /// Recordatorio de actividad (24h o 48h antes)
  Future<bool> sendActivityReminderNotification({
    required String userEmail,
    required String userName,
    required String activityTitle,
    required String activityType,
    required String activityDate,
    String? activityTime,
    String? location,
    required int hoursBefore,
  }) async {
    // Usar Edge Function en lugar de llamada directa a Resend
    final emailType = hoursBefore == 24 ? 'activity_reminder_24h' : 'activity_reminder_48h';
    
    return await _sendViaEdgeFunction(
      emailType: emailType,
      data: {
        'userEmail': userEmail,
        'userName': userName,
        'activityTitle': activityTitle,
        'activityType': activityType,
        'activityDate': activityDate,
        'activityTime': activityTime,
        'location': location,
        'hoursBefore': hoursBefore,
      },
    );
  }

  // =====================================================
  // MÓDULO GUARDIA NOCTURNA
  // =====================================================

  /// Recordatorio de guardia (24h o 48h antes)
  Future<bool> sendShiftReminderNotification({
    required String firefighterEmail,
    required String firefighterName,
    required String shiftDate,
    required int hoursBefore,
  }) async {
    final reminderText = hoursBefore == 24 ? 'mañana' : 'en 2 días';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .reminder { background-color: #E8EAF6; padding: 15px; border-left: 4px solid #1A237E; margin: 15px 0; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🌙 Recordatorio de Guardia</h1>
    </div>
    <div class="content">
      <p>Estimado/a $firefighterName,</p>
      <div class="reminder">
        <p><strong>Recordatorio: Tienes guardia $reminderText</strong></p>
        <p style="font-size: 20px; font-weight: bold; text-align: center; color: #1A237E;">
          $shiftDate
        </p>
      </div>
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
      subject: 'Recordatorio: Guardia $reminderText - $shiftDate',
      htmlContent: htmlContent,
    );
  }

  // =====================================================
  // MÓDULO TESORERÍA
  // =====================================================

  /// Notifica generación de cuota mensual
  Future<bool> sendQuotaGeneratedNotification({
    required String userEmail,
    required String userName,
    required int quotaAmount,
    required String month,
    required int year,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #2E7D32; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .amount { background-color: #E8F5E9; padding: 20px; text-align: center; border-radius: 8px; margin: 15px 0; }
    .amount-value { font-size: 32px; font-weight: bold; color: #2E7D32; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>💰 Cuota Mensual Generada</h1>
    </div>
    <div class="content">
      <p>Estimado/a $userName,</p>
      <p>Se ha generado tu cuota correspondiente a <strong>$month $year</strong>:</p>
      <div class="amount">
        <p style="margin: 0; color: #666;">Monto a pagar:</p>
        <p class="amount-value">\$$quotaAmount</p>
      </div>
      <p>Puedes realizar el pago en el cuartel o mediante transferencia bancaria.</p>
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: userEmail,
      subject: 'Cuota Mensual $month $year - \$$quotaAmount',
      htmlContent: htmlContent,
    );
  }

  /// Notifica confirmación de pago registrado
  Future<bool> sendPaymentConfirmationNotification({
    required String userEmail,
    required String userName,
    required int paidAmount,
    required String paymentDate,
    required String month,
    required int year,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #2E7D32; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .success { background-color: #E8F5E9; padding: 15px; border-left: 4px solid #2E7D32; margin: 15px 0; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Pago Registrado</h1>
    </div>
    <div class="content">
      <p>Estimado/a $userName,</p>
      <div class="success">
        <p><strong>Se ha registrado tu pago exitosamente</strong></p>
        <p><strong>Monto:</strong> \$$paidAmount</p>
        <p><strong>Fecha:</strong> $paymentDate</p>
        <p><strong>Período:</strong> $month $year</p>
      </div>
      <p>Gracias por tu puntualidad.</p>
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: userEmail,
      subject: 'Pago Registrado - $month $year',
      htmlContent: htmlContent,
    );
  }

  /// Recordatorio de cuota pendiente
  Future<bool> sendPaymentReminderNotification({
    required String userEmail,
    required String userName,
    required int pendingAmount,
    required String month,
    required int year,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #F57C00; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .warning { background-color: #FFF3E0; padding: 15px; border-left: 4px solid #F57C00; margin: 15px 0; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>⏰ Recordatorio de Pago</h1>
    </div>
    <div class="content">
      <p>Estimado/a $userName,</p>
      <div class="warning">
        <p><strong>Tienes una cuota pendiente de pago</strong></p>
        <p><strong>Período:</strong> $month $year</p>
        <p><strong>Monto pendiente:</strong> \$$pendingAmount</p>
      </div>
      <p>Por favor, regulariza tu situación a la brevedad.</p>
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
    </div>
  </div>
</body>
</html>
''';

    return await _sendEmail(
      to: userEmail,
      subject: 'Recordatorio: Cuota Pendiente $month $year',
      htmlContent: htmlContent,
    );
  }
}
