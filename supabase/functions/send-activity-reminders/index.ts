import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers inline (sin dependencia externa)
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

/**
 * Ventanas de búsqueda por hora de ejecución (hora Chile, UTC-3):
 * 
 * Cron 1 - 09:00 Chile (12:00 UTC): actividades entre 01:00 y 11:00 Chile
 * Cron 2 - 14:00 Chile (17:00 UTC): actividades entre 11:01 y 16:59 Chile
 * Cron 3 - 20:00 Chile (23:00 UTC): actividades entre 17:00 y 23:59 Chile
 * 
 * NOTA: activity_date es solo fecha (sin hora), start_time es campo separado.
 * Se filtran actividades del día siguiente y luego se compara start_time
 * contra la ventana horaria correspondiente.
 */
function getTimeWindow(now: Date): { startTime: string, endTime: string } {
    const chileHour = (now.getUTCHours() - 3 + 24) % 24

    if (chileHour >= 6 && chileHour < 12) {
        // Cron 1 (~09:00 Chile): actividades 00:00 - 11:00
        return { startTime: '00:00:00', endTime: '11:00:00' }
    } else if (chileHour >= 12 && chileHour < 18) {
        // Cron 2 (~14:00 Chile): actividades 11:01 - 16:59
        return { startTime: '11:01:00', endTime: '16:59:00' }
    } else {
        // Cron 3 (~20:00 Chile): actividades 17:00 - 23:59
        return { startTime: '17:00:00', endTime: '23:59:00' }
    }
}

/**
 * Calcula la fecha de "mañana" en zona horaria Chile (UTC-3)
 */
function getTomorrowDateChile(now: Date): string {
    // Convertir a hora Chile
    const chileTime = new Date(now.getTime() - 3 * 60 * 60 * 1000)
    // Sumar un día
    chileTime.setUTCDate(chileTime.getUTCDate() + 1)
    // Retornar solo la fecha YYYY-MM-DD
    return chileTime.toISOString().split('T')[0]
}

/**
 * Calcula la fecha de "pasado mañana" en zona horaria Chile (UTC-3)
 */
function getDayAfterTomorrowDateChile(now: Date): string {
    const chileTime = new Date(now.getTime() - 3 * 60 * 60 * 1000)
    chileTime.setUTCDate(chileTime.getUTCDate() + 2)
    return chileTime.toISOString().split('T')[0]
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        console.log('🔍 Iniciando búsqueda de recordatorios de actividades...')

        const supabase = createClient(supabaseUrl, supabaseServiceKey)
        const now = new Date()

        const chileHour = (now.getUTCHours() - 3 + 24) % 24
        const chileMin = now.getUTCMinutes()
        console.log(`⏰ Hora Chile: ${chileHour}:${String(chileMin).padStart(2, '0')}`)

        const timeWindow = getTimeWindow(now)
        const tomorrowDate = getTomorrowDateChile(now)
        const dayAfterDate = getDayAfterTomorrowDateChile(now)

        console.log(`📆 Fecha mañana (Chile): ${tomorrowDate}`)
        console.log(`🕐 Ventana horaria: ${timeWindow.startTime} → ${timeWindow.endTime}`)

        // =====================================================
        // RECORDATORIOS 48H
        // =====================================================

        console.log(`\n📅 Buscando actividades 48h para ${dayAfterDate} entre ${timeWindow.startTime} y ${timeWindow.endTime}...`)

        const { data: activities48h, error: error48h } = await supabase
            .from('activities')
            .select('*')
            .eq('notify_48h', true)
            .eq('activity_date', dayAfterDate)
            .gte('start_time', timeWindow.startTime)
            .lte('start_time', timeWindow.endTime)

        if (error48h) {
            console.error('❌ Error buscando actividades 48h:', error48h)
        } else {
            console.log(`📊 Actividades 48h encontradas: ${activities48h?.length || 0}`)

            if (activities48h && activities48h.length > 0) {
                await processReminders(supabase, activities48h, 48)
            }
        }

        // =====================================================
        // RECORDATORIOS 24H
        // =====================================================

        console.log(`\n📅 Buscando actividades 24h para ${tomorrowDate} entre ${timeWindow.startTime} y ${timeWindow.endTime}...`)

        const { data: activities24h, error: error24h } = await supabase
            .from('activities')
            .select('*')
            .eq('notify_24h', true)
            .eq('activity_date', tomorrowDate)
            .gte('start_time', timeWindow.startTime)
            .lte('start_time', timeWindow.endTime)

        if (error24h) {
            console.error('❌ Error buscando actividades 24h:', error24h)
        } else {
            console.log(`📊 Actividades 24h encontradas: ${activities24h?.length || 0}`)

            if (activities24h && activities24h.length > 0) {
                await processReminders(supabase, activities24h, 24)
            }
        }

        console.log('\n✅ Proceso de recordatorios completado')

        return new Response(
            JSON.stringify({ success: true, message: 'Reminders processed' }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('❌ Error general:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})

async function processReminders(supabase: any, activities: any[], hoursBefore: number) {
    const reminderType = hoursBefore === 24 ? 'activity_24h' : 'activity_48h'

    for (const activity of activities) {
        try {
            console.log(`\n🎯 Procesando: ${activity.title} (${activity.id})`)

            // Verificar si ya se envió este recordatorio
            const { data: alreadySent } = await supabase
                .from('sent_reminders')
                .select('*')
                .eq('reminder_type', reminderType)
                .eq('reference_id', activity.id)
                .single()

            if (alreadySent) {
                console.log(`⏭️  Recordatorio ya enviado anteriormente, saltando...`)
                continue
            }

            // Obtener usuarios según grupos configurados
            const notifyGroups = activity.notify_groups || ['all']
            const users = await getFilteredUsers(supabase, notifyGroups)

            console.log(`👥 Usuarios a notificar: ${users.length}`)

            // Preparar datos del email
            const activityDate = formatDate(activity.activity_date)
            const activityTime = activity.start_time ? formatTime(activity.start_time) : null

            // Enviar emails
            let emailsSent = 0
            let emailsFailed = 0

            for (const user of users) {
                if (!user.email || isExcludedEmail(user.email)) {
                    continue
                }

                try {
                    const { error } = await supabase.functions.invoke('send-email', {
                        headers: {
                            Authorization: `Bearer ${supabaseServiceKey}`
                        },
                        body: {
                            type: `activity_reminder_${hoursBefore}h`,
                            data: {
                                userEmail: user.email,
                                userName: user.full_name,
                                activityTitle: activity.title,
                                activityType: getActivityTypeDisplay(activity.activity_type),
                                activityDate: activityDate,
                                activityTime: activityTime,
                                location: activity.location,
                                hoursBefore: hoursBefore
                            }
                        }
                    })

                    if (error) {
                        console.error(`  ❌ Error enviando a ${user.full_name}:`, error)
                        emailsFailed++
                    } else {
                        emailsSent++
                    }
                } catch (e) {
                    console.error(`  ❌ Excepción enviando a ${user.full_name}:`, e)
                    emailsFailed++
                }

                // Delay de 500ms para respetar el rate limit de Brevo
                await new Promise(resolve => setTimeout(resolve, 500))
            }

            // Registrar que este recordatorio fue enviado
            await supabase.from('sent_reminders').insert({
                reminder_type: reminderType,
                reference_id: activity.id,
                reference_date: activity.activity_date,
                recipient_count: emailsSent
            })

            console.log(`📧 Resumen: ${emailsSent} enviados, ${emailsFailed} fallidos`)

        } catch (error) {
            console.error(`❌ Error procesando actividad ${activity.id}:`, error)
        }
    }
}

async function getFilteredUsers(supabase: any, groups: string[]): Promise<any[]> {
    const { data: allUsers, error } = await supabase
        .from('users')
        .select('id, full_name, email, role, rank')
        .order('full_name')

    if (error || !allUsers) {
        console.error('Error obteniendo usuarios:', error)
        return []
    }

    if (groups.includes('all')) {
        return allUsers
    }

    return allUsers.filter(user => {
        if (groups.includes('officers') && isOfficer(user.rank)) {
            return true
        }
        if (groups.includes('applicants') && isApplicant(user.rank)) {
            return true
        }
        if (groups.includes('active_firefighters') && user.role === 'bombero') {
            return true
        }
        if (groups.includes('honorary_firefighters') && isHonorary(user.rank)) {
            return true
        }
        if (groups.includes('discipline_council')) {
            return false
        }
        return false
    })
}

function isOfficer(rank: string): boolean {
    const rankLower = rank.toLowerCase()

    const companyOfficerPatterns = [
        'director',
        'secretari',
        'tesorer',
        'capitán',
        'teniente',
        'inspector m.',
    ]

    for (const pattern of companyOfficerPatterns) {
        if (rankLower.includes(pattern)) {
            return true
        }
    }

    if (rankLower.includes('ayudante') && !rankLower.includes('de comandancia')) {
        return true
    }

    return false
}

function isApplicant(rank: string): boolean {
    return ['Postulante', 'Aspirante'].includes(rank)
}

function isHonorary(rank: string): boolean {
    return rank.toLowerCase().includes('honorario')
}

function isExcludedEmail(email: string): boolean {
    const excluded = ['notengo@gmail.com', 'notiene@gmail.com']
    return excluded.includes(email.toLowerCase())
}

function formatDate(dateString: string): string {
    const date = new Date(dateString)
    const day = String(date.getDate()).padStart(2, '0')
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const year = date.getFullYear()
    return `${day}/${month}/${year}`
}

function formatTime(timeString: string): string {
    return timeString.substring(0, 5)
}

function getActivityTypeDisplay(type: string): string {
    const types: Record<string, string> = {
        'academia_compania': 'Academia de Compañía',
        'academia_cuerpo': 'Academia de Cuerpo',
        'reunion_ordinaria': 'Reunión Ordinaria',
        'reunion_extraordinaria': 'Reunión Extraordinaria',
        'citacion_compania': 'Citación de Compañía',
        'citacion_cuerpo': 'Citación de Cuerpo',
        'other': 'Otra Actividad'
    }
    return types[type] || type
}
