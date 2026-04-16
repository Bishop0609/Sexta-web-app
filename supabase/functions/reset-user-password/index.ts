import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const DEFAULT_PASSWORD = "Sexta2026*";

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user_id } = await req.json();

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id es requerido" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // 1. Buscar el usuario completo (necesitamos email para crear en auth si no existe)
    const { data: userData, error: userError } = await supabase
      .from("users")
      .select("id, auth_id, email, full_name, rut")
      .eq("id", user_id)
      .single();

    if (userError || !userData) {
      return new Response(
        JSON.stringify({ error: "Usuario no encontrado en tabla users", detail: userError?.message }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validar que tenga email para crear/linkear en auth
    if (!userData.email || userData.email.trim() === '') {
      return new Response(
        JSON.stringify({ error: "Usuario sin email. No se puede crear/resetear credenciales." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let authId = userData.auth_id;

    // 3. RAMA A: Usuario sin auth_id → crear en auth.users
    if (!authId) {
      // 3.1 Verificar si ya existe un auth user con ese email (huérfano de un intento previo)
      const { data: existingAuthUsers, error: listError } = await supabase.auth.admin.listUsers();
      
      if (listError) {
        return new Response(
          JSON.stringify({ error: "Error buscando usuarios en auth", detail: listError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const existingAuth = existingAuthUsers.users.find(
        (u) => u.email?.toLowerCase() === userData.email.toLowerCase()
      );

      if (existingAuth) {
        // 3.2 Existe huérfano → linkear y resetear password
        authId = existingAuth.id;

        const { error: linkError } = await supabase
          .from("users")
          .update({ auth_id: authId })
          .eq("id", user_id);

        if (linkError) {
          return new Response(
            JSON.stringify({ error: "Error linkeando auth_id existente", detail: linkError.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Resetear su password al default
        const { error: updatePassError } = await supabase.auth.admin.updateUserById(
          authId!,
          { password: DEFAULT_PASSWORD }
        );

        if (updatePassError) {
          return new Response(
            JSON.stringify({ error: "Error actualizando contraseña de auth existente", detail: updatePassError.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      } else {
        // 3.3 No existe → crear nuevo auth user
        const { data: newAuth, error: createError } = await supabase.auth.admin.createUser({
          email: userData.email,
          password: DEFAULT_PASSWORD,
          email_confirm: true,
          user_metadata: {
            full_name: userData.full_name,
            rut: userData.rut,
          },
        });

        if (createError || !newAuth?.user) {
          return new Response(
            JSON.stringify({ error: "Error creando usuario en auth", detail: createError?.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        authId = newAuth.user.id;

        // 3.4 Linkear el nuevo auth_id en la tabla users
        const { error: linkError } = await supabase
          .from("users")
          .update({ auth_id: authId })
          .eq("id", user_id);

        if (linkError) {
          // Rollback: borrar el auth user recién creado para no dejar huérfano
          await supabase.auth.admin.deleteUser(authId!);
          return new Response(
            JSON.stringify({ error: "Error linkeando auth_id (rollback aplicado)", detail: linkError.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }
    } else {
      // 4. RAMA B: Usuario con auth_id → resetear password via RPC (comportamiento original)
      const { error: rpcError } = await supabase.rpc('reset_user_password', {
        target_auth_id: authId,
        new_password: DEFAULT_PASSWORD,
      });

      if (rpcError) {
        return new Response(
          JSON.stringify({ error: "Error reseteando contraseña", detail: rpcError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 5. Marcar requires_password_change (para ambas ramas)
    const { error: updateError } = await supabase
      .from("users")
      .update({ requires_password_change: true })
      .eq("id", user_id);

    if (updateError) {
      return new Response(
        JSON.stringify({ 
          error: "Credenciales creadas/reseteadas pero falló marcar flag", 
          detail: updateError.message 
        }),
        { status: 207, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: authId === userData.auth_id 
          ? "Contraseña reseteada a temporal" 
          : "Credenciales creadas exitosamente"
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});