// supabase/functions/migrate-to-auth/index.ts
// Migración one-time: crea usuarios en auth.users y linkea con tabla users
// Ejecutar UNA SOLA VEZ con:
// curl -X POST https://taizxujpxyutpjcworti.supabase.co/functions/v1/migrate-to-auth \
//   -H "Authorization: Bearer TU_SERVICE_ROLE_KEY" \
//   -H "Content-Type: application/json"

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const DEFAULT_PASSWORD = "Sexta2026*";

Deno.serve(async (req) => {
  try {
    // Cliente con service_role para operaciones admin
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // 1. Obtener todos los usuarios que NO tienen auth_id todavía
    const { data: users, error: fetchError } = await supabase
      .from("users")
      .select("id, rut, email, full_name, role")
      .is("auth_id", null)
      .order("full_name");

    if (fetchError) {
      return new Response(JSON.stringify({ error: "Error fetching users", detail: fetchError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!users || users.length === 0) {
      return new Response(JSON.stringify({ message: "No hay usuarios pendientes de migrar" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const results = {
      total: users.length,
      success: [] as string[],
      failed: [] as { rut: string; name: string; error: string }[],
    };

    // 2. Crear cada usuario en auth.users
    for (const user of users) {
      try {
        // Crear usuario en auth.users
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email: user.email,
          password: DEFAULT_PASSWORD,
          email_confirm: true, // No envía email de verificación
          user_metadata: {
            full_name: user.full_name,
            rut: user.rut,
            role: user.role,
          },
        });

        if (authError) {
          results.failed.push({
            rut: user.rut,
            name: user.full_name,
            error: authError.message,
          });
          continue;
        }

        // 3. Actualizar auth_id en tabla users
        const { error: updateError } = await supabase
          .from("users")
          .update({ auth_id: authData.user.id })
          .eq("id", user.id);

        if (updateError) {
          results.failed.push({
            rut: user.rut,
            name: user.full_name,
            error: `Auth creado (${authData.user.id}) pero falló update: ${updateError.message}`,
          });
          continue;
        }

        results.success.push(`${user.rut} - ${user.full_name}`);
      } catch (err) {
        results.failed.push({
          rut: user.rut,
          name: user.full_name,
          error: `Exception: ${err.message}`,
        });
      }
    }

    return new Response(JSON.stringify(results, null, 2), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
