import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// CORS headers inline (sin dependencia externa)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email'
// Dirección de tesorería para CC en correos de pagos
const TREASURY_CC_EMAIL = 'tesoreriasextacompania@gmail.com'
interface EmailRequest {
  type: string
  data: Record<string, any>
}
interface EmailContent {
  to: string | string[]
  subject: string
  html: string
  cc?: string[]
  bcc?: string[]
}
serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  try {
    // Parse request body
    const { type, data }: EmailRequest = await req.json()
    // Validate required fields
    if (!type || !data) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: type, data' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    // Generate email content based on type
    const emailContent = generateEmailContent(type, data)
    if (!emailContent) {
      return new Response(
        JSON.stringify({ error: `Unknown email type: ${type}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    // Convert 'to' to array if it's a string
    const recipients = Array.isArray(emailContent.to) ? emailContent.to : [emailContent.to]
    // Prepare email payload for Brevo API
    const brevoPayload: any = {
      sender: {
        email: 'notificaciones@sextacoquimbo.cl',
        name: 'SGI Sexta Compañía'
      },
      to: recipients.map((email: string) => ({ email })),
      subject: emailContent.subject,
      htmlContent: emailContent.html,
    }
    // Add CC if defined (convert to Brevo format)
    if (emailContent.cc && emailContent.cc.length > 0) {
      brevoPayload.cc = emailContent.cc.map((email: string) => ({ email }))
    }
    // Add BCC if defined
    if (emailContent.bcc && emailContent.bcc.length > 0) {
      brevoPayload.bcc = emailContent.bcc.map((email: string) => ({ email }))
    }
    // Send email via Brevo
    const brevoResponse = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'api-key': BREVO_API_KEY!,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: JSON.stringify(brevoPayload),
    })
    const brevoData = await brevoResponse.json()
    if (!brevoResponse.ok) {
      console.error('Brevo API error:', brevoData)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: brevoData }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    return new Response(
      JSON.stringify({ success: true, messageId: brevoData.messageId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
function generateEmailContent(type: string, data: Record<string, any>): EmailContent | null {
  switch (type) {
    case 'permission_submitted':
      return {
        to: data.userEmail,
        subject: 'Solicitud de Permiso Recibida',
        html: generatePermissionSubmittedHTML(data),
        // Sin CC - solo confirmación personal al solicitante
      }
    case 'permission_review': {
      const isDirector = data.aprobadorTipo === 'director';
      const toEmail = isDirector ? ['director6@bomberosdecoquimbo.cl'] : ['capitan6@bomberosdecoquimbo.cl'];
      const ccEmail = isDirector 
        ? ['secretario6@bomberosdecoquimbo.cl', 'gunthersoft.apps@gmail.com'] 
        : ['ayudantia@sextacoquimbo.cl', 'gunthersoft.apps@gmail.com'];
      return {
        to: toEmail,
        subject: `Nueva Solicitud de Permiso - ${data.firefighterName}`,
        html: generatePermissionReviewHTML(data),
        cc: ccEmail
      }
    }
    case 'permission_approved': {
      const isDirector = data.aprobadorTipo === 'director';
      const ccEmail = isDirector 
        ? ['secretario6@bomberosdecoquimbo.cl', 'gunthersoft.apps@gmail.com'] 
        : ['ayudantia@sextacoquimbo.cl', 'gunthersoft.apps@gmail.com'];
      return {
        to: data.firefighterEmail,
        subject: 'Solicitud de Permiso APROBADA',
        html: generatePermissionDecisionHTML(data, true),
        cc: ccEmail
      }
    }
    case 'permission_rejected': {
      const isDirector = data.aprobadorTipo === 'director';
      const ccEmail = isDirector 
        ? ['secretario6@bomberosdecoquimbo.cl', 'gunthersoft.apps@gmail.com'] 
        : ['ayudantia@sextacoquimbo.cl', 'gunthersoft.apps@gmail.com'];
      return {
        to: data.firefighterEmail,
        subject: 'Solicitud de Permiso RECHAZADA',
        html: generatePermissionDecisionHTML(data, false),
        cc: ccEmail
      }
    }
    // =====================================================
    // MÓDULO ACTIVIDADES
    // =====================================================
    case 'activity_created':
      return {
        to: data.userEmail,
        subject: `Citación a ${data.activityType} - ${formatDateWithDay(data.activityDate)}`,
        html: generateActivityCreatedHTML(data),
      }
    case 'activity_modified':
      return {
        to: data.userEmail,
        subject: `Actividad Modificada: ${data.activityTitle} - ${formatDateWithDay(data.activityDate)}`,
        html: generateActivityModifiedHTML(data),
      }
    case 'activity_reminder_24h':
      return {
        to: data.userEmail,
        subject: `Recordatorio: ${data.activityTitle} - mañana ${formatDateWithDay(data.activityDate)}`,
        html: generateActivityReminderHTML(data, 24),
      }
    case 'activity_reminder_48h':
      return {
        to: data.userEmail,
        subject: `Recordatorio: ${data.activityTitle} - ${formatDateWithDay(data.activityDate)}`,
        html: generateActivityReminderHTML(data, 48),
      }
    // =====================================================
    // MÓDULO TESORERÍA
    // =====================================================
    case 'payment_confirmation':
    return {
        to: data.userEmail,
        subject: `Pago Registrado - ${data.month} ${data.year}`,
        html: generatePaymentConfirmationHTML(data),
        cc: [TREASURY_CC_EMAIL, 'tesoreria@sextacoquimbo.cl'],
        bcc: ['gunthersoft.apps@gmail.com']
    }
    // =====================================================
    // MÓDULO ASISTENCIAS
    // =====================================================
    case 'attendance_created':
      return {
        to: data.ayudantiaEmail,
        subject: `Nueva Asistencia Registrada - ${data.actType}`,
        html: generateAttendanceCreatedHTML(data),
      }
    // =====================================================
    // MÓDULO GUARDIAS - PERÍODOS DE INSCRIPCIÓN
    // =====================================================
    case 'guard_registration_opened':
      return {
        to: data.recipientEmails,
        subject: `Inscripción de Guardias Abierta - ${data.periodStart} al ${data.periodEnd}`,
        html: generateGuardRegistrationOpenedHTML(data),
      }

    case 'guard_registration_closed':
      return {
        to: data.recipientEmails,
        subject: `Inscripción de Guardias Cerrada - ${data.periodStart} al ${data.periodEnd}`,
        html: generateGuardRegistrationClosedHTML(data),
      }

    default:
      return null
  }
}
function generatePermissionSubmittedHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #D32F2F; color: white; padding: 14px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>✅ Solicitud Recibida</h1>
  </div>
  <div class="content">
    <p>Estimado/a ${data.firefighterName},</p>
    <p>Tu solicitud de permiso ha sido recibida correctamente y está siendo revisada.</p>
    <p><strong>Detalles:</strong></p>
    <ul>
      ${data.activityName 
        ? `<li><strong>Actividad:</strong> ${data.activityName} — ${data.activityDate}</li>
           <li><strong>Aprobador:</strong> ${data.aprobadorTipo === 'capitan' ? 'Capitán' : 'Director'}</li>`
        : `<li><strong>Período:</strong> ${data.startDate} - ${data.endDate}</li>`
      }
      <li><strong>Motivo:</strong> ${data.reason}</li>
    </ul>
    <p>Recibirás una notificación cuando tu solicitud sea revisada.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
function generatePermissionReviewHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #D32F2F; color: white; padding: 14px; text-align: center; }
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
    <p><strong>Bombero:</strong> ${data.firefighterName}</p>
    ${data.activityName 
      ? `<p><strong>Actividad:</strong> ${data.activityName} — ${data.activityDate}</p>
         <p><strong>Aprobador:</strong> ${data.aprobadorTipo === 'capitan' ? 'Capitán' : 'Director'}</p>`
      : `<p><strong>Período:</strong> ${data.startDate} - ${data.endDate}</p>`
    }
    <p><strong>Motivo:</strong></p>
    <p>${data.reason}</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
function generatePermissionDecisionHTML(data: any, approved: boolean): string {
  const status = approved ? 'APROBADA' : 'RECHAZADA'
  const statusColor = approved ? '#2E7D32' : '#C62828'
  const message = approved
    ? 'Tu solicitud de permiso ha sido aprobada.'
    : 'Tu solicitud de permiso ha sido rechazada.'
  const rejectionSection = !approved && data.rejectionReason
    ? `
    <div style="background-color: #FFEBEE; padding: 15px; border-left: 4px solid #C62828; margin: 15px 0;">
      <p><strong>Motivo del rechazo:</strong></p>
      <p>${data.rejectionReason}</p>
    </div>
    `
    : ''
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #D32F2F; color: white; padding: 14px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .status { 
    background-color: ${statusColor}; 
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
  <div class="status">${status}</div>
  <div class="content">
    <p>Estimado/a ${data.firefighterName},</p>
    <p>${message}</p>
    <p><strong>Detalles de tu solicitud:</strong></p>
    <ul>
      ${data.activityName 
        ? `<li><strong>Actividad:</strong> ${data.activityName} — ${data.activityDate}</li>
           <li><strong>Aprobador:</strong> ${data.aprobadorTipo === 'capitan' ? 'Capitán' : 'Director'}</li>`
        : `<li><strong>Período:</strong> ${data.startDate} - ${data.endDate}</li>`
      }
      <li><strong>Motivo:</strong> ${data.reason}</li>
    </ul>
    ${rejectionSection}
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
// =====================================================
// MÓDULO ACTIVIDADES - HTML TEMPLATES
// =====================================================
function generateActivityCreatedHTML(data: any): string {
  const timeInfo = data.activityTime ? ` a las ${data.activityTime} hrs` : ''
  const locationInfo = data.location ? `<p><strong>Lugar:</strong> ${data.location}</p>` : ''
  const descriptionInfo = data.description ? `<p><strong>Descripción:</strong></p><p>${data.description}</p>` : ''
  const dateWithDay = formatDateWithDay(data.activityDate)
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .highlight { background-color: #E3F2FD; padding: 15px; border-left: 4px solid #1A237E; margin: 15px 0; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>Citación a ${data.activityType}</h1>
  </div>
  <div class="content">
    <p>Estimado/a ${data.userName},</p>
    <p>Este es un correo automático para recordarte la siguiente citación:</p>
    <div class="highlight">
      <p><strong>${data.activityTitle}</strong></p>
      <p><strong>Tipo:</strong> ${data.activityType}</p>
      <p><strong>Fecha:</strong> ${dateWithDay}${timeInfo}</p>
      ${locationInfo}
      ${descriptionInfo}
    </div>
    <p>Recibirás recordatorios 48 y 24 horas antes.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
function generateActivityModifiedHTML(data: any): string {
  const timeInfo = data.activityTime ? ` a las ${data.activityTime} hrs` : ''
  const dateWithDay = formatDateWithDay(data.activityDate)
  return `
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
    <h1>⚠️ Actividad Modificada</h1>
  </div>
  <div class="content">
    <p>Estimado/a ${data.userName},</p>
    <div class="warning">
      <p><strong>Se ha modificado la siguiente actividad:</strong></p>
      <p><strong>${data.activityTitle}</strong></p>
      <p><strong>Nueva fecha:</strong> ${dateWithDay}${timeInfo}</p>
    </div>
    <p>Por favor, revisa los detalles actualizados en el sistema.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
function generateActivityReminderHTML(data: any, hoursBefore: number): string {
  const timeInfo = data.activityTime ? ` a las ${data.activityTime} hrs` : ''
  const locationInfo = data.location ? `<p><strong>Lugar:</strong> ${data.location}</p>` : ''
  const reminderText = hoursBefore === 24 ? 'mañana' : 'en 2 días'
  const dateWithDay = formatDateWithDay(data.activityDate)
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .reminder { background-color: #FFF9C4; padding: 15px; border-left: 4px solid #FBC02D; margin: 15px 0; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>🔔 Recordatorio de ${data.activityType}</h1>
  </div>
  <div class="content">
    <p>Estimado/a ${data.userName},</p>
    <div class="reminder">
      <p><strong>Recordatorio: Tienes una actividad ${reminderText}</strong></p>
      <p><strong>${data.activityTitle}</strong></p>
      <p><strong>Tipo:</strong> ${data.activityType}</p>
      <p><strong>Fecha:</strong> ${dateWithDay}${timeInfo}</p>
      ${locationInfo}
    </div>
    <p>¡No olvides asistir!</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
// =====================================================
// MÓDULO TESORERÍA - HTML TEMPLATES
// =====================================================
function generatePaymentConfirmationHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #2E7D32; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .success { background-color: #E8F5E9; padding: 15px; border-left: 4px solid #2E7D32; margin: 15px 0; }
  .info-box { background-color: #E3F2FD; padding: 15px; border-left: 4px solid #1976D2; margin: 15px 0; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>✅ Pago Registrado</h1>
  </div>
  <div class="content">
    <p>Estimado/a ${data.userName},</p>
    <div class="success">
      <p><strong>Se ha registrado exitosamente tu pago en el sistema</strong></p>
      <p><strong>Monto:</strong> $${data.paidAmount}</p>
      <p><strong>Fecha:</strong> ${data.paymentDate}</p>
      <p><strong>Período:</strong> ${data.month} ${data.year}</p>
    </div>
    <div class="info-box">
      <p><strong>ℹ️ Tu saldo actualizado está disponible en la sección "Mi Perfil"</strong></p>
      <p>Ingresa a la aplicación para ver el detalle completo de tus pagos y estado de cuotas.</p>
    </div>
    <p>Gracias por tu puntualidad y compromiso con la compañía.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}
// =====================================================
// MÓDULO ASISTENCIAS - HTML TEMPLATES
// =====================================================
function generateAttendanceCreatedHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #ddd; }
  .totals { background-color: #E8EAF6; padding: 15px; border-radius: 5px; margin: 15px 0; }
  .total-item { display: inline-block; margin: 0 15px; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📋 Nueva Asistencia Registrada</h1>
    </div>
    <div class="content">
      <p><strong>Se ha ingresado una nueva asistencia al sistema que requiere revisión.</strong></p>
      
      <h3>Datos Generales</h3>
      <div class="info-row">
        <span><strong>Fecha:</strong></span>
        <span>${data.eventDate}</span>
      </div>
      <div class="info-row">
        <span><strong>Tipo de Actividad:</strong></span>
        <span>${data.actType}</span>
      </div>
      <div class="info-row">
        <span><strong>Subtipo:</strong></span>
        <span>${data.subtype || 'N/A'}</span>
      </div>
      <div class="info-row">
        <span><strong>Ubicación:</strong></span>
        <span>${data.location || 'N/A'}</span>
      </div>
      <div class="info-row">
        <span><strong>Registrado por:</strong></span>
        <span>${data.createdBy}</span>
      </div>
      
      <div class="totals">
        <h3 style="margin-top: 0;">Resumen de Asistencia</h3>
        <div class="total-item">
          <strong style="color: #2E7D32;">✓ Presentes:</strong> ${data.totalPresent}
        </div>
        <div class="total-item">
          <strong style="color: #C62828;">✗ Ausentes:</strong> ${data.totalAbsent}
        </div>
        <div class="total-item">
          <strong style="color: #F57C00;">⚠ Con Permiso:</strong> ${data.totalLicencia}
        </div>
      </div>
      
      <p><strong>Por favor, ingresa al sistema para revisar y aprobar esta asistencia.</strong></p>
      <p style="font-size: 12px; color: #666;">
        Dirígete al módulo "Modificar Asistencias" donde encontrarás esta asistencia marcada como "Pendiente de Revisión".
      </p>
    </div>
    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
      <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
    </div>
  </div>
</body>
</html>
`
}
// =====================================================
// HELPER FUNCTIONS
// =====================================================
/**
 * Converts DD/MM/YYYY date to Spanish format with day of week
 * Example: "03/02/2026" =^> "lunes 03/02/2026"
 */
// =====================================================
// MÓDULO GUARDIAS - HTML TEMPLATES
// =====================================================

function generateGuardRegistrationOpenedHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .highlight { background-color: #E8F5E9; padding: 20px; border-left: 4px solid #2E7D32; margin: 15px 0; text-align: center; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>📋 Inscripción de Guardias Abierta</h1>
  </div>
  <div class="content">
    <p>Estimado/a Bombero/a,</p>
    <p>Se ha abierto el período de inscripción de guardias nocturnas.</p>
    <div class="highlight">
      <p style="font-size: 18px; font-weight: bold; color: #2E7D32; margin: 0;">
        Período: ${data.periodStart} al ${data.periodEnd}
      </p>
    </div>
    <p>Ingresa a la aplicación, sección <strong>"Inscribir Disponibilidad"</strong>, y registra los días en que puedes hacer guardia.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}

function generateGuardRegistrationClosedHTML(data: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
  .header { background-color: #1A237E; color: white; padding: 20px; text-align: center; }
  .content { background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
  .highlight { background-color: #FFEBEE; padding: 20px; border-left: 4px solid #C62828; margin: 15px 0; text-align: center; }
  .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>🔒 Inscripción de Guardias Cerrada</h1>
  </div>
  <div class="content">
    <p>Estimado/a Bombero/a,</p>
    <p>Se ha cerrado el período de inscripción de guardias nocturnas.</p>
    <div class="highlight">
      <p style="font-size: 18px; font-weight: bold; color: #C62828; margin: 0;">
        Período cerrado: ${data.periodStart} al ${data.periodEnd}
      </p>
    </div>
    <p>Ya no es posible modificar tu disponibilidad para este período. El capitán procederá a generar el rol de guardias.</p>
    <p>Si tienes algún inconveniente, comunícate directamente con el capitán.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
    <p style="font-size: 10px; margin-top: 5px;">Desarrollado por GuntherSOFT, 2026</p>
  </div>
</div>
</body>
</html>
`
}

function formatDateWithDay(dateString: string): string {
  const daysInSpanish = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado']
  // Parse DD/MM/YYYY
  const parts = dateString.split('/')
  if (parts.length !== 3) return dateString
  const day = parseInt(parts[0], 10)
  const month = parseInt(parts[1], 10) - 1 // Month is 0-indexed
  const year = parseInt(parts[2], 10)
  const date = new Date(year, month, day)
  const dayOfWeek = daysInSpanish[date.getDay()]
  return `${dayOfWeek} ${dateString}`
}
