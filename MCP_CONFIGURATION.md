# 📱 Configuración de MCPs Recomendados

Esta guía explica qué MCPs (Model Context Protocol servers) tienes instalados y cuáles deberías agregar para mejorar tu experiencia de desarrollo.

---

## ✅ MCPs Actualmente Instalados

### 1. **supabase-mcp-server** ⭐ ESENCIAL

**Estado:** ✅ Instalado y funcional

**¿Qué hace?**
- Ejecutar queries SQL directamente
- Aplicar migraciones de base de datos
- Ver logs del proyecto
- Gestionar branches de desarrollo
- Obtener información del proyecto

**¿Por qué lo necesitas?**
Tu aplicación usa Supabase como backend. Este MCP permite gestionar completamente tu base de datos PostgreSQL desde el chat.

**Configuración actual:**
```json
{
  "mcpServers": {
    "supabase-mcp-server": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp"]
    }
  }
}
```

---

### 2. **firebase-mcp-server** ⚠️ TEMPORAL

**Estado:** ✅ Instalado

**¿Qué hace?**
- Deploy a Firebase Hosting
- Configurar reglas de seguridad
- Gestionar proyectos Firebase

**¿Lo necesitas?**
Solo mientras uses Firebase Hosting para demos. Una vez migres completamente a cPanel, puedes desinstalarlo.

**Recomendación:** Mantener hasta migración definitiva a cPanel.

---

### 3. **perplexity-ask** 💡 OPCIONAL

**Estado:** ✅ Instalado

**¿Qué hace?**
- Búsquedas web actualizadas
- Investigación técnica en tiempo real
- Consultas sobre tecnologías nuevas

**¿Lo necesitas?**
Útil para investigar problemas técnicos, pero no esencial para el desarrollo día a día.

**Nota:** Perplexity tiene límites en su plan gratuito.

---

## 🆕 MCPs Recomendados para Agregar

### 1. **Git MCP** ⭐ ALTAMENTE RECOMENDADO

**¿Por qué agregarlo?**
- Control de versiones profesional
- Commits organizados y descriptivos
- Branching para features nuevas
- Historial de cambios completo
- Rollback fácil en caso de errores

**Cómo agregarlo:**

1. Abrir tu archivo de configuración de MCPs (probablemente en `~/.config/Claude/claude_desktop_config.json` o similar)

2. Agregar esta configuración:

```json
{
  "mcpServers": {
    "supabase-mcp-server": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp"]
    },
    "firebase-mcp-server": {
      "command": "npx",
      "args": ["-y", "@firebase/mcp"]
    },
    "perplexity-ask": {
      "command": "npx",
      "args": ["-y", "@perplexity/mcp"]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    }
  }
}
```

**Uso:**
Una vez instalado, podré ayudarte a:
- Hacer commits descriptivos
- Crear branches para features
- Ver historial de cambios
- Hacer merge de branches

---

### 2. **Brave Search MCP** 💰 ALTERNATIVA GRATUITA

**¿Por qué agregarlo?**
Alternativa **100% gratuita** a Perplexity para búsquedas web.

**Cómo agregarlo:**

1. Obtener API key gratuita:
   - Ir a: https://brave.com/search/api/
   - Registrarte gratis
   - Copiar tu API key

2. Agregar a configuración:

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "TU_API_KEY_AQUI"
      }
    }
  }
}
```

**Beneficios:**
- Gratis (hasta 2,000 búsquedas/mes)
- Sin necesidad de cuenta premium
- Resultados actualizados

---

## ❌ MCPs NO Necesarios

### PostgreSQL MCP
**Status:** ❌ No instalar

**¿Por qué no?**
Ya tienes `supabase-mcp-server` que te da acceso completo a PostgreSQL. Este sería redundante.

---

### Filesystem MCP
**Status:** ❌ No instalar

**¿Por qué no?**
Ya tengo herramientas nativas para leer, escribir, buscar y modificar archivos. No necesitas un MCP adicional para esto.

---

### Puppeteer MCP
**Status:** ❌ No instalar ahora

**¿Por qué no?**
Solo sería útil para testing E2E automatizado muy complejo. En tu etapa actual de desarrollo, no lo necesitas.

**Cuándo sí considerarlo:**
- Cuando tengas la app en producción estable
- Si necesitas tests automatizados de navegador
- Para monitoreo continuo de UI

---

## 📋 Resumen de Recomendaciones

### MCPs Actuales
| MCP | Status | Necesario | Acción |
|-----|--------|-----------|--------|
| Supabase | ✅ Instalado | ⭐ Esencial | ✅ Mantener |
| Firebase | ✅ Instalado | ⚠️ Temporal | 🔄 Revisar después de migración |
| Perplexity | ✅ Instalado | 💡 Opcional | ✅ Mantener o reemplazar con Brave |

### MCPs Recomendados
| MCP | Prioridad | Beneficio | Costo |
|-----|-----------|-----------|-------|
| Git | ⭐⭐⭐ Alta | Control de versiones profesional | Gratis |
| Brave Search | ⭐⭐ Media | Búsquedas web gratis | Gratis |

### MCPs NO Recomendados
| MCP | Razón |
|-----|-------|
| PostgreSQL | Redundante con Supabase MCP |
| Filesystem | Herramientas nativas suficientes |
| Puppeteer | No necesario en esta etapa |

---

## 🚀 Configuración Óptima Final

Mi recomendación de configuración completa:

```json
{
  "mcpServers": {
    "supabase-mcp-server": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp"]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "tu_api_key_aqui"
      }
    }
  }
}
```

**Nota sobre Firebase:**
- Mantenerlo solo hasta que completes la migración a cPanel
- Una vez en cPanel definitivo, puedes eliminarlo

---

## 📖 Cómo Agregar MCPs

### Ubicación del archivo de configuración:

**Windows:**
```
C:\Users\TuUsuario\AppData\Roaming\Claude\claude_desktop_config.json
```

**Pasos:**

1. Cerrar Claude Desktop (si está abierto)
2. Abrir el archivo `claude_desktop_config.json` con un editor de texto
3. Agregar las configuraciones de MCPs
4. Guardar el archivo
5. Reiniciar Claude Desktop
6. Verificar que los MCPs estén activos

---

## 🧪 Verificar MCPs Instalados

Para verificar que un MCP está funcionando, puedo:

1. **Supabase MCP:** Listar tus proyectos de Supabase
2. **Git MCP:** Ver el status de tu repositorio
3. **Brave Search MCP:** Hacer una búsqueda de prueba

---

## ❓ Preguntas Frecuentes

**Q: ¿Los MCPs consumen recursos?**
A: Muy pocos. Solo se activan cuando los uso.

**Q: ¿Puedo tener demasiados MCPs?**
A: En teoría sí, pero con 3-4 MCPs esenciales no hay problema.

**Q: ¿Los MCPs son seguros?**
A: Sí, son oficiales de Anthropic/proveedores confiables. No tienen acceso sin tu permiso.

**Q: ¿Necesito pagar por MCPs?**
A: La mayoría son gratuitos. Solo algunos servicios externos (como Perplexity) tienen límites en planes gratuitos.

---

## 🎯 Conclusión

**Tu configuración ideal:**
1. ✅ **Supabase MCP** - Para gestionar tu base de datos
2. 🆕 **Git MCP** - Para control de versiones profesional
3. 🆕 **Brave Search** - Para búsquedas web gratis (reemplaza Perplexity)
4. ⚠️ **Firebase MCP** - Solo hasta migración completa a cPanel

**No agregues:** PostgreSQL, Filesystem, Puppeteer (innecesarios en tu caso)

---

**¿Necesitas ayuda para configurar algún MCP? ¡Solo pregúntame!** 🚀
