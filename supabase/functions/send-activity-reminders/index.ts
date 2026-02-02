import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers inline (sin dependencia externa)
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        console.log('🔍 Iniciando búsqueda de recordatorios de actividades...')

        const supabase = createClient(supabaseUrl, supabaseServiceKey)
        const now = new Date()

        // =====================================================
        // RECORDATORIOS 48H
        // =====================================================

        console.log('📅 Buscando actividades para recordatorio 48h...')

        // Calcular ventana de tiempo: entre 47 y 49 horas desde ahora
        const window48hStart = new Date(now.getTime() + 47 * 60 * 60 * 1000)
        const window48hEnd = new Date(now.getTime() + 49 * 60 * 60 * 1000)

        const { data: activities48h, error: error48h } = await supabase
            .from('activities')
            .select('*')
            .eq('notify_48h', true)
            .gte('activity_date', window48hStart.toISOString())
            .lte('activity_date', window48hEnd.toISOString())

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

        console.log('📅 Buscando actividades para recordatorio 24h...')

        // Calcular ventana de tiempo: entre 23 y 25 horas desde ahora  
        const window24hStart = new Date(now.getTime() + 23 * 60 * 60 * 1000)
        const window24hEnd = new Date(now.getTime() + 25 * 60 * 60 * 1000)

        const { data: activities24h, error: error24h } = await supabase
            .from('activities')
            .select('*')
            .eq('notify_24h', true)
            .gte('activity_date', window24hStart.toISOString())
            .lte('activity_date', window24hEnd.toISOString())

        if (error24h) {
            console.error('❌ Error buscando actividades 24h:', error24h)
        } else {
            console.log(`📊 Actividades 24h encontradas: ${activities24h?.length || 0}`)

            if (activities24h && activities24h.length > 0) {
                await processReminders(supabase, activities24h, 24)
            }
        }

        console.log('✅ Proceso de recordatorios completado')

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

                // Delay de 500ms para respetar el rate limit de Resend (2 requests/segundo)
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
    // Obtener todos los usuarios
    const { data: allUsers, error } = await supabase
        .from('users')
        .select('id, full_name, email, role, rank')
        .order('full_name')

    if (error || !allUsers) {
        console.error('Error obteniendo usuarios:', error)
        return []
    }

    // Si "all" está en los grupos, devolver todos
    if (groups.includes('all')) {
        return allUsers
    }

    // Filtrar por grupos específicos
    return allUsers.filter(user => {
        // Oficiales
        if (groups.includes('officers') && isOfficer(user.rank)) {
            return true
        }

        // Postulantes/Aspirantes
        if (groups.includes('applicants') && isApplicant(user.rank)) {
            return true
        }

        // Bomberos Activos
        if (groups.includes('active_firefighters') && user.role === 'bombero') {
            return true
        }

        // Bomberos Honorarios
        if (groups.includes('honorary_firefighters') && isHonorary(user.rank)) {
            return true
        }

        // Consejeros de Disciplina (por implementar)
        if (groups.includes('discipline_council')) {
            // TODO: Definir criterio específico
            return false
        }

        return false
    })
}

/**
 * Verifica si el usuario es oficial basándose en su rango (rank)
 * IMPORTANTE: Solo OFICIALES DE COMPAÑÍA (excluye oficiales de cuerpo/generales)
 */
function isOfficer(rank: string): boolean {
    const rankLower = rank.toLowerCase()

    // Solo Oficiales de Compañía (NO incluye oficiales de cuerpo/generales)
    const companyOfficerPatterns = [
        'director',
        'secretari',      // Secretario/a, Pro-Secretario/a
        'tesorer',        // Tesorero/a, Pro-Tesorero/a
        'capitán',
        'teniente',
        'inspector m.',   // Inspector M. Mayor/Menor
    ]

    // Verificar patrones de Oficiales de Compañía
    for (const pattern of companyOfficerPatterns) {
        if (rankLower.includes(pattern)) {
            return true
        }
    }

    // Caso especial: "Ayudante" SOLO si es de compañía
    // Excluir "Ayudante de Comandancia" (es oficial de cuerpo)
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
    return timeString.substring(0, 5) // "HH:MM:SS" -> "HH:MM"
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
