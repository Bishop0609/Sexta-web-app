import csv
import uuid
import sys

# Configuración
csv_file = r'.\listado de usuarios para ingreso a BD 080126.csv'
output_file = 'supabase_import_usuarios.sql'

# Password hash para "Bombero2024!" 
# Este es el hash bcrypt real que debes generar con: bcrypt.hashpw("Bombero2024!".encode('utf-8'), bcrypt.gensalt())
# Por ahora usaremos un placeholder que deberás reemplazar
DEFAULT_PASSWORD_HASH = '$2a$10$rJ8xH.yZYv7QGZqK7XvZ4.OKx6h9YzH8pZKW5L3vQ7J4K5L6M7N8O'

def convert_marital_status(spanish_status):
    """Convertir estado civil de español a inglés"""
    mapping = {
        'Casado/a': 'married',
        'Casado': 'married',
        'Casada': 'married',
        'Soltero/a': 'single',
        'Soltero': 'single',
        'Soltera': 'single'
    }
    return mapping.get(spanish_status.strip(), 'single')

def infer_gender(nombre):
    """Inferir género del nombre (muy básico)"""
    # Palabras indicadoras masculinas
    male_indicators = ['Mario', 'Juan', 'Luis', 'Carlos', 'Eduardo', 'Fernando', 'José']
    # Palabras indicadoras femeninas
    female_indicators = ['María', 'Carmen', 'Jennifer', 'Sonia', 'Ana']
    
    nombre_upper = nombre.upper()
    for indicator in male_indicators:
        if indicator.upper() in nombre_upper:
            return 'M'
    for indicator in female_indicators:
        if indicator.upper() in nombre_upper:
            return 'F'
    
    # Por defecto masculino
    return 'M'

# Leer CSV
try:
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter=';')
        users = list(reader)
except FileNotFoundError:
    print(f"Error: No se encontró el archivo: {csv_file}")
    sys.exit(1)

print(f"✅ Total de usuarios encontrados: {len(users)}\n")

# Generar SQL
sql_lines = []
sql_lines.append("-- ========================================")
sql_lines.append("-- IMPORTACIÓN DE USUARIOS DESDE EXCEL")
sql_lines.append("-- Password por defecto: Bombero2024!")
sql_lines.append("-- ========================================\n")

sql_lines.append("-- Paso 1: Crear usuarios en auth.users (autenticación)")
sql_lines.append("-- Paso 2: Crear registros en public.users (datos de usuario)\n")

for i, user in enumerate(users, 1):
    try:
        # Limpiar datos
        rut = user['rut'].strip()
        full_name = user['full_name'].strip().replace("'", "''")
        victor_number = user.get('victor_number', f'V-{i}').strip()
        registro_compania = user.get('registro_compania', '').strip()
        rank = user['rank'].strip().replace("'", "''")
        
        # Convertir estado civil
        marital_status_esp = user.get('marital_status', 'Soltero/a').strip()
        marital_status = convert_marital_status(marital_status_esp)
        
        # Email (puede estar vacío)
        email = user.get('email', '').strip()
        
        # Gender: primero chequear si existe en CSV, sino inferir
        if 'gender' in user and user['gender'].strip():
            gender = user['gender'].strip().upper()
            if gender not in ['M', 'F']:
                gender = 'M' if gender.startswith('M') or gender.startswith('H') else 'F'
        else:
            gender = infer_gender(full_name)
        
        # Role
        role = user.get('role', 'firefighter').strip()
        
        # Generar UUID para auth.users
        auth_id = str(uuid.uuid4())
        
        # SQL para auth.users (tabla de autenticación)
        email_for_auth = email if email else f"{rut.replace('-', '')}@temp.local"
        
        sql_lines.append(f"-- Usuario {i}: {full_name}")
        sql_lines.append(f"INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)")
        sql_lines.append(f"VALUES ('{auth_id}', '{email_for_auth}', '{DEFAULT_PASSWORD_HASH}', NOW(), NOW(), NOW());")
        sql_lines.append("")
        
        # SQL para public.users (datos de usuario)
        email_sql = f"'{email}'" if email else 'NULL'
        registro_sql = f"'{registro_compania}'" if registro_compania else 'NULL'
        
        sql_lines.append(f"INSERT INTO users (id, rut, full_name, victor_number, registro_compania, rank, gender, marital_status, email, role, requires_password_change)")
        sql_lines.append(f"VALUES ('{auth_id}', '{rut}', '{full_name}', '{victor_number}', {registro_sql}, '{rank}', '{gender}', '{marital_status}', {email_sql}, '{role}', true);")
        sql_lines.append("")
        
    except KeyError as e:
        print(f"⚠️  Error en fila {i}: Falta columna {e}")
        continue

sql_lines.append(f"\n-- ========================================")
sql_lines.append(f"-- Total: {len(users)} usuarios importados")
sql_lines.append(f"-- ========================================")

# Escribir archivo SQL
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(sql_lines))

print(f"✅ Script SQL generado: {output_file}")
print(f"📝 Ubicación: {output_file}")
print(f"\n⚠️  IMPORTANTE:")
print(f"   1. Este script usa un password hash de prueba")
print(f"   2. Debes generar el hash real de 'Bombero2024!' con bcrypt")
print(f"   3. Ejecuta el script en Supabase SQL Editor")
