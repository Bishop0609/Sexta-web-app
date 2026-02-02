import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

// CORS headers inline (sin dependencia externa)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const RESEND_API_URL = 'https://api.resend.com/emails'

// Direcciones institucionales para CC en correos de permisos
const PERMISSION_CC_EMAILS = [
  'capitan6@bomberosdecoquimbo.cl',
  'ayudantia@sextacoquimbo.cl'
]

interface EmailRequest {
  type: string
  data: Record<string, any>
}

interface EmailContent {
  to: string | string[]
  subject: string
  html: string
  cc?: string[]
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

    // Prepare email payload
    const resendPayload: any = {
      from: 'SGI Sexta Compañía <notificaciones@sextacoquimbo.cl>',
      to: recipients,
      subject: emailContent.subject,
      html: emailContent.html,
    }

    // Add CC if defined
    if (emailContent.cc && emailContent.cc.length > 0) {
      resendPayload.cc = emailContent.cc
    }

    // Send email via Resend
    const resendResponse = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(resendPayload),
    })

    const resendData = await resendResponse.json()

    if (!resendResponse.ok) {
      console.error('Resend API error:', resendData)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: resendData }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, emailId: resendData.id }),
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

    case 'permission_review':
      return {
        to: data.officerEmail,
        subject: `Nueva Solicitud de Permiso - ${data.firefighterName}`,
        html: generatePermissionReviewHTML(data),
        cc: PERMISSION_CC_EMAILS  // CC a Capitán y Ayudantía
      }

    case 'permission_approved':
      return {
        to: data.firefighterEmail,
        subject: 'Solicitud de Permiso APROBADA',
        html: generatePermissionDecisionHTML(data, true),
        cc: PERMISSION_CC_EMAILS  // CC a Capitán y Ayudantía
      }

    case 'permission_rejected':
      return {
        to: data.firefighterEmail,
        subject: 'Solicitud de Permiso RECHAZADA',
        html: generatePermissionDecisionHTML(data, false),
        cc: PERMISSION_CC_EMAILS  // CC a Capitán y Ayudantía
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
      <li><strong>Período:</strong> ${data.startDate} - ${data.endDate}</li>
      <li><strong>Motivo:</strong> ${data.reason}</li>
    </ul>
    <p>Recibirás una notificación cuando tu solicitud sea revisada.</p>
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
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
    <p><strong>Período:</strong> ${data.startDate} - ${data.endDate}</p>
    <p><strong>Motivo:</strong></p>
    <p>${data.reason}</p>
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
      <li><strong>Período:</strong> ${data.startDate} - ${data.endDate}</li>
      <li><strong>Motivo:</strong> ${data.reason}</li>
    </ul>
    ${rejectionSection}
  </div>
  <div class="footer">
    <p>Sistema de Gestión Integral - Sexta Compañía</p>
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
    <h1>🔔 Recordatorio de Actividad</h1>
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
