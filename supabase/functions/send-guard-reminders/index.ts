import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─────────────────────────────────────────────────────────────
// send-guard-reminders — Edge Function independiente
// No modifica send-email ni send-activity-reminders.
// Llama directo a Brevo, igual que _sendEmail() en email_service.dart.
//
// Cron: 0 23 * * *  →  23:00 UTC = 20:00 Chile (UTC-3)
// ─────────────────────────────────────────────────────────────

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl    = Deno.env.get('SUPABASE_URL')!
const supabaseKey    = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const brevoApiKey    = Deno.env.get('BREVO_API_KEY')!
const brevoFromEmail = 'notificaciones@sextacoquimbo.cl'
const brevoFromName  = 'SGI Sexta Compañía'

const EXCLUDED_EMAILS = ['notengo@gmail.com', 'notiene@gmail.com']

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🌙 Iniciando recordatorios de guardia nocturna...')

    const supabase = createClient(supabaseUrl, supabaseKey)

    // ── Fecha de HOY en Chile (UTC-3) ──────────────────────────
    const now      = new Date()
    const chileNow = new Date(now.getTime() + (-3 * 60 * 60 * 1000))
    const todayStr = chileNow.toISOString().split('T')[0] // 'yyyy-MM-dd'

    console.log(`📅 Fecha Chile hoy: ${todayStr}`)

    // ── Evitar duplicados ──────────────────────────────────────
    // reference_date es timestamptz → comparamos con rango del día completo en UTC
    const todayStart = `${todayStr}T00:00:00+00:00`
    const todayEnd   = `${todayStr}T23:59:59+00:00`

    const { data: alreadySent } = await supabase
      .from('sent_reminders')
      .select('id')
      .eq('reminder_type', 'guard_nocturna_today')
      .gte('reference_date', todayStart)
      .lte('reference_date', todayEnd)
      .maybeSingle()

    if (alreadySent) {
      console.log('⏭️  Recordatorios ya enviados hoy. Fin.')
      return new Response(
        JSON.stringify({ success: true, message: 'Already sent today' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ── Guardias de HOY en roles publicados ───────────────────
    const { data: todayGuards, error: guardsError } = await supabase
      .from('guard_roster_daily')
      .select(`
        id,
        guard_date,
        maquinista_id,
        obac_id,
        bombero_ids,
        roster_week:guard_roster_weekly!roster_week_id(status)
      `)
      .eq('guard_date', todayStr)
      .eq('shift_period', 'NOCTURNA')

    if (guardsError) {
      console.error('❌ Error buscando guardias:', guardsError)
      throw guardsError
    }

    console.log(`📊 Registros para hoy: ${todayGuards?.length ?? 0}`)

    const publishedGuards = (todayGuards ?? []).filter(
      (g: any) => g.roster_week?.status === 'published'
    )

    console.log(`✅ Guardias publicadas: ${publishedGuards.length}`)

    if (publishedGuards.length === 0) {
      console.log('ℹ️  Sin guardias publicadas hoy. Fin.')
      return new Response(
        JSON.stringify({ success: true, message: 'No published guards today' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ── Recolectar IDs únicos asignados ───────────────────────
    const assignedIds = new Set<string>()
    // Guardamos el uuid de la primera fila para satisfacer el campo reference_id (uuid) en sent_reminders
    const firstGuardId: string = publishedGuards[0].id

    for (const guard of publishedGuards) {
      if (guard.maquinista_id) assignedIds.add(guard.maquinista_id)
      if (guard.obac_id)       assignedIds.add(guard.obac_id)
      if (Array.isArray(guard.bombero_ids)) {
        guard.bombero_ids.forEach((id: string) => assignedIds.add(id))
      }
    }

    console.log(`👥 Bomberos asignados hoy: ${assignedIds.size}`)

    if (assignedIds.size === 0) {
      console.log('ℹ️  Guardia publicada sin asignados. Fin.')
      return new Response(
        JSON.stringify({ success: true, message: 'No assigned firefighters' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ── Obtener emails de usuarios asignados ──────────────────
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, full_name, email')
      .in('id', Array.from(assignedIds))

    if (usersError) {
      console.error('❌ Error obteniendo usuarios:', usersError)
      throw usersError
    }

    const guardDateDisplay = formatDateEs(todayStr)

    // ── Enviar emails ──────────────────────────────────────────
    let emailsSent   = 0
    let emailsFailed = 0

    for (const user of users ?? []) {
      if (!user.email || EXCLUDED_EMAILS.includes(user.email.toLowerCase())) {
        console.log(`⏭️  Sin email válido: ${user.full_name}`)
        continue
      }

      try {
        const sent = await sendBrevoEmail(user.email, user.full_name, guardDateDisplay)
        if (sent) {
          console.log(`  ✅ Enviado a: ${user.full_name}`)
          emailsSent++
        } else {
          console.error(`  ❌ Falló: ${user.full_name}`)
          emailsFailed++
        }
      } catch (e) {
        console.error(`  ❌ Excepción para ${user.full_name}:`, e)
        emailsFailed++
      }

      // Rate limit Brevo — igual que send-activity-reminders (500ms entre envíos)
      await new Promise(resolve => setTimeout(resolve, 500))
    }

    // ── Registrar en sent_reminders ────────────────────────────
    // reference_id   → uuid de la primera fila guard_roster_daily (requerido por schema uuid)
    // reference_date → timestamp ISO completo (columna es timestamptz, no text)
    await supabase.from('sent_reminders').insert({
      reminder_type:   'guard_nocturna_today',
      reference_id:    firstGuardId,
      reference_date:  new Date().toISOString(),
      recipient_count: emailsSent,
    })

    console.log(`📧 Resumen: ${emailsSent} enviados, ${emailsFailed} fallidos`)

    return new Response(
      JSON.stringify({ success: true, sent: emailsSent, failed: emailsFailed }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    console.error('❌ Error general:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// ─────────────────────────────────────────────────────────────
// Envío directo a Brevo
// Mismo patrón que _sendEmail() en email_service.dart
// ─────────────────────────────────────────────────────────────
async function sendBrevoEmail(
  toEmail: string,
  userName: string,
  guardDate: string
): Promise<boolean> {
  const subject     = `🌙 Recordatorio: Guardia Nocturna de HOY — ${guardDate}`
  const htmlContent = buildEmailHtml(userName, guardDate)

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key':      brevoApiKey,
      'Content-Type': 'application/json',
      'accept':       'application/json',
    },
    body: JSON.stringify({
      sender: { email: brevoFromEmail, name: brevoFromName },
      to:     [{ email: toEmail, name: userName }],
      subject,
      htmlContent,
    }),
  })

  if (response.ok) return true

  const body = await response.text()
  console.error(`  Brevo error ${response.status}: ${body}`)
  return false
}

// ─────────────────────────────────────────────────────────────
// Template HTML
// Mismo estilo que sendShiftReminderNotification en email_service.dart
// header #1A237E · reminder box #E8EAF6 · border-left #1A237E
// ─────────────────────────────────────────────────────────────
function buildEmailHtml(userName: string, guardDate: string): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body       { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header    { background-color: #1A237E; color: white; padding: 24px 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .header h1 { margin: 0; font-size: 22px; font-weight: bold; }
    .content   { background-color: #f9f9f9; padding: 24px; border-radius: 0 0 8px 8px; }
    .reminder  { background-color: #E8EAF6; padding: 16px 20px; border-left: 4px solid #1A237E; border-radius: 0 8px 8px 0; margin: 16px 0; }
    .badge     { display: inline-block; background-color: #C62828; color: white; padding: 4px 14px; border-radius: 20px; font-size: 13px; font-weight: bold; letter-spacing: 1px; margin-bottom: 10px; }
    .date-big  { font-size: 22px; font-weight: bold; color: #1A237E; margin: 6px 0 4px; }
    .info-row  { color: #555; font-size: 14px; margin: 6px 0; }
    .footer    { text-align: center; color: #888; font-size: 12px; margin-top: 24px; border-top: 1px solid #eee; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="container">

    <div class="header">
      <h1>🌙 Recordatorio de Guardia Nocturna</h1>
    </div>

    <div class="content">
      <p>Estimado/a <strong>${userName}</strong>,</p>

      <div class="reminder">
        <span class="badge">HOY</span>
        <div class="date-big">${guardDate}</div>
        <p style="margin: 8px 0 0; color: #555; font-size: 14px;">
          Tienes guardia nocturna asignada esta noche.
        </p>
      </div>

      <p class="info-row">🕚 <strong>Inicio:</strong> 23:00 hrs</p>
      <p class="info-row">🌅 <strong>Término:</strong> 08:00 hrs del día siguiente</p>

      <p style="margin-top: 16px; font-size: 14px; color: #555;">
        Recuerda presentarte puntualmente y realizar el check-in de asistencia en el sistema.
      </p>
    </div>

    <div class="footer">
      <p>Sistema de Gestión Integral - Sexta Compañía</p>
      <p>Desarrollado por GuntherSOFT, 2026</p>
    </div>

  </div>
</body>
</html>`
}

// ─────────────────────────────────────────────────────────────
// Helper: "2026-02-24"  →  "24 de febrero de 2026"
// ─────────────────────────────────────────────────────────────
function formatDateEs(dateStr: string): string {
  const [year, month, day] = dateStr.split('-').map(Number)
  const months = [
    'enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre',
  ]
  return `${day} de ${months[month - 1]} de ${year}`
}
