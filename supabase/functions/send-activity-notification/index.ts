import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

/**
 * Edge Function: send-activity-notification
 * 
 * Envía notificaciones de actividades (creación o modificación) a los usuarios
 * correspondientes según los grupos configurados.
 * 
 * Se invoca desde Flutter con una sola llamada HTTP, y el backend se encarga
 * de enviar todos los correos sin depender del navegador del usuario.
 * 
 * Body esperado:
 * {
 *   isNewActivity: boolean,     // true = creación, false = modificación
 *   activityTitle: string,
 *   activityType: string,       // display name del tipo (ej: "Reunión Ordinaria")
 *   activityDate: string,       // formato DD/MM/YYYY
 *   activityTime?: string,      // formato HH:MM
 *   location?: string,
 *   description?: string,
 *   notifyGroups: string[],     // ["all"] o ["officers", "applicants", etc.]
 * }
 */
serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const {
            isNewActivity,
            activityTitle,
            activityType,
            activityDate,
            activityTime,
            location,
            description,
            notifyGroups,
        } = await req.json()

        if (!activityTitle || !activityDate || !notifyGroups) {
            return new Response(
                JSON.stringify({ error: 'Faltan campos requeridos: activityTitle, activityDate, notifyGroups' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`📤 Iniciando envío de notificación: ${activityTitle}`)
        console.log(`   Tipo: ${isNewActivity ? 'Nueva actividad' : 'Actividad modificada'}`)
        console.log(`   Grupos: ${JSON.stringify(notifyGroups)}`)

        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // Obtener usuarios filtrados por grupos
        const users = await getFilteredUsers(supabase, notifyGroups)
        console.log(`👥 Usuarios a notificar: ${users.length}`)

        const emailType = isNewActivity ? 'activity_created' : 'activity_modified'
        let emailsSent = 0
        let emailsFailed = 0

        for (const user of users) {
            if (!user.email || isExcludedEmail(user.email)) {
                continue
            }

            try {
                const emailData: Record<string, any> = {
                    userEmail: user.email,
                    userName: user.full_name,
                    activityTitle: activityTitle,
                    activityType: activityType,
                    activityDate: activityDate,
                    activityTime: activityTime,
                    location: location,
                }

                // activity_created también envía description
                if (isNewActivity && description) {
                    emailData.description = description
                }

                const { error } = await supabase.functions.invoke('send-email', {
                    headers: {
                        Authorization: `Bearer ${supabaseServiceKey}`
                    },
                    body: {
                        type: emailType,
                        data: emailData,
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

        console.log(`📧 Resumen: ${emailsSent} enviados, ${emailsFailed} fallidos de ${users.length} usuarios`)

        return new Response(
            JSON.stringify({
                success: true,
                sent: emailsSent,
                failed: emailsFailed,
                total: users.length,
            }),
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

// =====================================================
// FUNCIONES DE FILTRADO (misma lógica que send-activity-reminders)
// =====================================================

async function getFilteredUsers(supabase: any, groups: string[]): Promise<any[]> {
    const { data: allUsers, error } = await supabase
        .from('users')
        .select('id, full_name, email, role, rank')
        .eq('status', 'activo')
        .order('full_name')

    if (error || !allUsers) {
        console.error('Error obteniendo usuarios:', error)
        return []
    }

    if (groups.includes('all')) {
        return allUsers
    }

    return allUsers.filter((user: any) => {
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

// Omite correos específicos y cualquier correo @noemail.cl (RUTs sin email)
function isExcludedEmail(email: string): boolean {
    const excluded = ['notengo@gmail.com', 'notiene@gmail.com']
    const emailLower = email.toLowerCase()
    return excluded.includes(emailLower) || emailLower.endsWith('@noemail.cl')
}
