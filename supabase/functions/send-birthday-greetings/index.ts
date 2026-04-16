import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;

const SENDER = { name: 'Sexta Compañía de Bomberos', email: 'ayudantia@sextacoquimbo.cl' };
const BCC = [{ email: 'gunthersoft.apps@gmail.com', name: 'GuntherSOFT Logs' }];

interface Birthday {
  user_id: string;
  full_name: string;
  email: string;
  rank: string;
  birth_date: string;
  age: number;
}

function buildEmailHtml(b: Birthday): string {
  return `
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>¡Feliz Cumpleaños!</title>
</head>
<body style="margin:0;padding:0;font-family:'Segoe UI',Arial,sans-serif;background:#f5f5f5;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f5f5f5;padding:30px 0;">
    <tr><td align="center">
      <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.1);">

        <!-- Header festivo -->
        <tr><td style="background:linear-gradient(135deg,#c41e3a 0%,#8b0000 100%);padding:40px 20px;text-align:center;">
          <div style="font-size:64px;line-height:1;">🎂🎉🎈</div>
          <h1 style="color:#ffffff;font-size:32px;margin:20px 0 0 0;font-weight:bold;letter-spacing:1px;">
            ¡FELIZ CUMPLEAÑOS!
          </h1>
        </td></tr>

        <!-- Saludo personal -->
        <tr><td style="padding:40px 40px 20px 40px;text-align:center;">
          <h2 style="color:#c41e3a;font-size:26px;margin:0 0 10px 0;">${b.full_name}</h2>
          <p style="color:#666;font-size:16px;margin:0;">${b.rank}</p>
        </td></tr>

        <!-- Mensaje principal -->
        <tr><td style="padding:20px 40px;">
          <p style="color:#333;font-size:17px;line-height:1.7;text-align:center;margin:0;">
            Hoy toda la <strong>Sexta Compañía de Bomberos de Coquimbo</strong> se une para
            desearte un día lleno de alegría, bendiciones y momentos inolvidables junto a
            quienes amas.
          </p>
        </td></tr>

        <!-- Tarjeta decorativa -->
        <tr><td style="padding:20px 40px;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:linear-gradient(135deg,#fff5f5 0%,#ffe5e5 100%);border-left:4px solid #c41e3a;border-radius:8px;">
            <tr><td style="padding:25px;text-align:center;">
              <p style="color:#8b0000;font-size:18px;font-style:italic;margin:0;line-height:1.6;">
                "Gracias por tu compromiso, dedicación y servicio a la comunidad.
                Tu presencia hace grande a nuestra Compañía."
              </p>
            </td></tr>
          </table>
        </td></tr>

        <!-- Mensaje del equipo -->
        <tr><td style="padding:30px 40px 20px 40px;text-align:center;">
          <p style="color:#333;font-size:16px;line-height:1.7;margin:0;">
            Con todo el cariño de tus compañeros,<br>
            <strong style="color:#c41e3a;">¡Que tengas un cumpleaños extraordinario!</strong>
          </p>
          <div style="font-size:40px;margin-top:20px;">🚒❤️🎁</div>
        </td></tr>

        <!-- Footer institucional -->
        <tr><td style="background:#1a1a1a;padding:25px 40px;text-align:center;">
          <p style="color:#ffffff;font-size:14px;margin:0;font-weight:bold;">
            Sexta Compañía de Bomberos de Coquimbo
          </p>
          <p style="color:#999;font-size:12px;margin:8px 0 0 0;">
            Lealtad y Sacrificio
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>
  `.trim();
}

async function sendBirthdayEmail(b: Birthday): Promise<boolean> {
  try {
    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'api-key': BREVO_API_KEY,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        sender: SENDER,
        to: [{ email: b.email, name: b.full_name }],
        bcc: BCC,
        subject: `🎂 ¡Feliz Cumpleaños, ${b.full_name.split(' ')[0]}!`,
        htmlContent: buildEmailHtml(b),
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`Failed to send to ${b.email}:`, error);
      return false;
    }
    console.log(`Birthday email sent to ${b.full_name} (${b.email})`);
    return true;
  } catch (e) {
    console.error(`Exception sending to ${b.email}:`, e);
    return false;
  }
}

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: birthdays, error } = await supabase.rpc('get_todays_birthdays');

    if (error) {
      console.error('RPC error:', error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    if (!birthdays || birthdays.length === 0) {
      console.log('No birthdays today');
      return new Response(JSON.stringify({ sent: 0, message: 'No birthdays today' }), { status: 200 });
    }

    console.log(`Found ${birthdays.length} birthday(s) today`);

    let sent = 0;
    let failed = 0;
    for (const b of birthdays as Birthday[]) {
      const ok = await sendBirthdayEmail(b);
      ok ? sent++ : failed++;
    }

    return new Response(
      JSON.stringify({ total: birthdays.length, sent, failed }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    console.error('Handler error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});