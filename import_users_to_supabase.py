"""
Script para importar usuarios desde CSV a Supabase
Crea usuarios en auth.users y en la tabla public.users

Contraseñas temporales: RUT sin guión + "2026"
Ejemplo: 8726935-3 → 87269352026

Uso:
    python import_users_to_supabase.py
"""

import csv
import re
from supabase import create_client, Client

# =====================================================
# CONFIGURACIÓN - COMPLETAR CON TUS CREDENCIALES
# =====================================================
SUPABASE_URL = "TU_SUPABASE_URL"  # ej: https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY = "TU_SERVICE_ROLE_KEY"  # Service Role Key (no anon key!)

# Nombre del archivo CSV
CSV_FILE = "listado de usuarios para ingreso a BD 080126.csv"

# =====================================================
# MAPPING DE GÉNERO BASADO EN NOMBRES
# =====================================================
NOMBRES_MASCULINOS = {
    'osman', 'mario', 'juan', 'eduardo', 'baldomero', 'andré', 'luis', 
    'fernando', 'hans', 'ángelo', 'angelo', 'matías', 'matias', 'samuel',
    'sebastian', 'sebastián', 'javier', 'víctor', 'victor', 'cristian',
    'joy', 'christian', 'felipe', 'hernán', 'hernan', 'jhon', 'jorge',
    'gonzalo', 'nicolás', 'nicolas', 'alexander', 'esteban', 'brayan',
    'carlos', 'irian', 'andrés', 'andres', 'jordan', 'josé', 'jose',
    'miguel', 'rolando', 'julio', 'paulo', 'jesús', 'jesus', 'martín',
    'martin', 'manuel', 'vicente', 'gabriel', 'hans', 'wladimir', 'ignacio',
    'joseph', 'thomas'
}

NOMBRES_FEMENINOS = {
    'sonia', 'jennifer', 'valeska', 'nicole', 'emily', 'fernanda', 'rosa',
    'karen', 'francisca', 'millaray', 'javiera', 'valeria', 'stephania',
    'madelaine', 'paulina', 'paula', 'yanara', 'karla', 'tania', 'belén', 'belen',
    'antonella', 'daniela', 'alejandra'
}

def inferir_genero(nombre_completo: str) -> str:
    """
    Infiere el género basado en el primer nombre
    Returns: 'M' para masculino, 'F' para femenino
    """
    # Obtener el primer nombre
    nombres = nombre_completo.lower().strip().split()
    
    # Limpiar prefijos comunes
    nombres_limpios = [n for n in nombres if n not in ['b.', 'ch.', 'j.', 'c.', 'n.']]
    
    if not nombres_limpios:
        nombres_limpios = nombres
    
    primer_nombre = nombres_limpios[0] if nombres_limpios else ''
    
    # Normalizar caracteres especiales
    primer_nombre = (primer_nombre
                     .replace('á', 'a').replace('é', 'e')
                     .replace('í', 'i').replace('ó', 'o')
                     .replace('ú', 'u').replace('ñ', 'n'))
    
    # Verificar en listas
    if primer_nombre in NOMBRES_FEMENINOS:
        return 'F'
    elif primer_nombre in NOMBRES_MASCULINOS:
        return 'M'
    
    # Heurística adicional: nombres terminados en 'a' suelen ser femeninos
    if primer_nombre.endswith('a') and len(primer_nombre) > 2:
        return 'F'
    
    # Por defecto, asumimos masculino (puedes cambiar esto)
    return 'M'

def limpiar_rut(rut: str) -> str:
    """Limpia el RUT removiendo guiones y puntos"""
    return rut.replace('-', '').replace('.', '')

def mapear_estado_civil(estado_csv: str) -> str:
    """Mapea el estado civil del CSV al formato de la BD"""
    if 'Casado' in estado_csv or 'casado' in estado_csv:
        return 'married'
    else:
        return 'single'

def generar_password(rut: str) -> str:
    """
    Genera contraseña temporal basada en el RUT
    Formato: RUT sin guión + "2026"
    """
    rut_limpio = limpiar_rut(rut)
    return f"{rut_limpio}2026"

def generar_email(rut: str, email_csv: str) -> str:
    """Genera email si no existe en CSV"""
    if email_csv and email_csv.strip():
        return email_csv.strip()
    return f"{rut}@sexta.cl"

def importar_usuarios():
    """Función principal de importación"""
    
    # Conectar a Supabase
    print("Conectando a Supabase...")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Leer CSV
    print(f"Leyendo archivo {CSV_FILE}...")
    usuarios_creados = 0
    usuarios_fallidos = 0
    
    with open(CSV_FILE, 'r', encoding='utf-8') as file:
        # Detectar delimitador (punto y coma en este caso)
        csv_reader = csv.DictReader(file, delimiter=';')
        
        for idx, row in enumerate(csv_reader, start=1):
            try:
                rut = row['rut'].strip()
                full_name = row['full_name'].strip()
                victor_number = row['victor_number'].strip()
                registro_compania = row['registro_compania'].strip()
                rank = row['rank'].strip()
                marital_status_csv = row['marital_status'].strip()
                email_csv = row['email'].strip() if row['email'] else ''
                role = row['role'].strip()
                
                # Procesar datos
                gender = inferir_genero(full_name)
                marital_status = mapear_estado_civil(marital_status_csv)
                email = generar_email(rut, email_csv)
                password = generar_password(rut)
                
                print(f"\n[{idx}] Creando usuario: {full_name}")
                print(f"    RUT: {rut} | Victor: {victor_number} | Género: {gender}")
                
                # 1. Crear usuario en Auth (usando Admin API)
                try:
                    auth_response = supabase.auth.admin.create_user({
                        "email": email,
                        "password": password,
                        "email_confirm": True,
                        "user_metadata": {
                            "rut": rut,
                            "full_name": full_name
                        }
                    })
                    
                    user_id = auth_response.user.id
                    print(f"    ✅ Usuario Auth creado: {user_id}")
                    
                except Exception as e:
                    print(f"    ❌ Error creando Auth user: {e}")
                    usuarios_fallidos += 1
                    continue
                
                # 2. Insertar en tabla public.users
                try:
                    user_data = {
                        "id": user_id,
                        "rut": rut,
                        "victor_number": victor_number,
                        "registro_compania": registro_compania if registro_compania else None,
                        "full_name": full_name,
                        "gender": gender,
                        "marital_status": marital_status,
                        "rank": rank,
                        "role": role,
                        "email": email if email_csv else None
                    }
                    
                    supabase.table('users').insert(user_data).execute()
                    print(f"    ✅ Usuario insertado en tabla users")
                    usuarios_creados += 1
                    
                except Exception as e:
                    print(f"    ❌ Error insertando en tabla users: {e}")
                    # Intentar eliminar el usuario de Auth si falló la inserción
                    try:
                        supabase.auth.admin.delete_user(user_id)
                        print(f"    ⚠️  Usuario Auth eliminado (rollback)")
                    except:
                        pass
                    usuarios_fallidos += 1
                    
            except Exception as e:
                print(f"    ❌ Error procesando fila {idx}: {e}")
                usuarios_fallidos += 1
    
    # Resumen
    print("\n" + "="*60)
    print("RESUMEN DE IMPORTACIÓN")
    print("="*60)
    print(f"✅ Usuarios creados exitosamente: {usuarios_creados}")
    print(f"❌ Usuarios fallidos: {usuarios_fallidos}")
    print(f"📊 Total procesados: {usuarios_creados + usuarios_fallidos}")
    print("="*60)
    print("\n⚠️  IMPORTANTE: Los usuarios deben cambiar su contraseña en el primer login")
    print("    Contraseña temporal: RUT sin guión + '2026'")
    print("    Ejemplo: RUT 8726935-3 → Contraseña: 87269352026")

if __name__ == "__main__":
    print("="*60)
    print("IMPORTADOR DE USUARIOS A SUPABASE")
    print("="*60)
    
    # Verificar configuración
    if SUPABASE_URL == "TU_SUPABASE_URL" or SUPABASE_SERVICE_KEY == "TU_SERVICE_ROLE_KEY":
        print("❌ ERROR: Debes configurar SUPABASE_URL y SUPABASE_SERVICE_KEY")
        print("   Edita el archivo y completa las credenciales en las líneas 15-16")
        exit(1)
    
    respuesta = input("\n¿Estás seguro de importar los usuarios? (si/no): ")
    if respuesta.lower() in ['si', 'sí', 's', 'yes', 'y']:
        importar_usuarios()
    else:
        print("Importación cancelada.")
