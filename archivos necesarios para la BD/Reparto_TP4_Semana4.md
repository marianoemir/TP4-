# Reparto de trabajo — TP4 Semana 4 (Food Store)
**Base de Datos II — Unidad 2: Optimización de Consultas — Reportes con JOINs**

Somos 3 integrantes: Mariano, Andrés, Facundo. Esta vez la parte más pesada
(Parte 1) la toma **Mariano**, para no repetir siempre el mismo reparto del TP3.

---

## ♻️ Qué reutilizamos del TP3 (no hay que rehacer nada de esto)

| Del TP3 | Se reutiliza tal cual | Por qué |
|---|---|---|
| `schema.sql`, `objects.sql`, `data.sql` | ✅ Sin cambios | El modelo de datos (tablas, vistas, triggers, `sp_crear_pedido`) no cambió entre TPs |
| `carga_masiva.sql` | ✅ Sin cambios | Mismo script de población masiva (50.000+ productos, 20.000+ usuarios, 200.000+ pedidos), ya corregido y verificado en el TP3 |
| `queries.sql` | ✅ Como banco de consultas | Sigue siendo la fuente de donde salen las consultas candidatas — este TP4 solo pide que las nuevas elegidas crucen ≥3 tablas |
| `AGENTS.md`, `protocolo_seguridad.md` | ✅ Con ajustes menores | El protocolo de seguridad (copia → transacción → respaldo → ANALYZE) es el mismo; solo se actualizó el `AGENTS.md` para referenciar las carpetas de este TP4 |
| `.kiro/steering/` | ✅ Sin cambios | Las convenciones del esquema no cambiaron |
| Los 2 índices que sí sirvieron (`idx_pedido_fecha_estado_vigente`, `idx_pedido_usuario_total_estado`) | 🔁 **Se recrean**, no se reutiliza el archivo | Como la base se recrea de cero cada TP, estos índices no persisten solos — por eso armamos `indices_semana3.sql`, que es nuevo pero contiene exactamente los `CREATE INDEX` que ya habían sido aceptados y medidos en el TP3 |
| El flujo de trabajo en sí (medir antes → proponer con IA → validar línea por línea → medir después → documentar) | ✅ Igual | Es el mismo criterio profesional de la cátedra, ahora aplicado a consultas con JOIN en vez de filtros simples |
| El formato de DUIA (tabla: herramienta / para qué / prompt / aceptado o descartado) | ✅ Igual | Mismo formato que usamos en el TP3, solo cambia el contenido |
| El método de verificación de equivalencia (`EXCEPT` en ambos sentidos) | ✅ Igual | Mismo mecanismo, ahora aplicado también a rankings con función de ventana |

**Lo único genuinamente nuevo para armar es:** `indices_semana3.sql` (que ya
armamos) y, obviamente, los 4 documentos de entregables de este TP4.

---

## 🔧 Paso 0 — Levantar la base (bloqueante para TODOS, se hace una sola vez)

### Orden exacto de ejecución (no saltear ni invertir pasos)

```bash
# 1. Plantilla (schema + objects + data chico)
createdb plantilla_food_store
psql -d plantilla_food_store -f "Archivos necesarios para la BD/schema.sql"
psql -d plantilla_food_store -f "Archivos necesarios para la BD/objects.sql"
psql -d plantilla_food_store -f "Archivos necesarios para la BD/data.sql"

# 2. Copia de trabajo descartable
createdb -T plantilla_food_store copia_trabajo

# 3. Carga masiva (50.000+ productos, 20.000+ usuarios, 200.000+ pedidos)
psql -d copia_trabajo -f "Archivos necesarios para la BD/carga_masiva.sql"

# 4. Índices de la Semana 3 — PASO NUEVO, específico de este TP4
psql -d copia_trabajo -f "Archivos necesarios para la BD/indices_semana3.sql"
```

### Por qué el paso 4 (`indices_semana3.sql`) es obligatorio

La consigna de este TP4 da por sentado, en "Requisitos previos", que los índices
de la Semana 3 **ya existen**. Como la base se recrea de cero, hay que recrearlos
explícitamente antes de medir nada — si se saltea este paso, los planes "antes"
de la Parte 1 muestran `Seq Scan` donde la cátedra espera ya un `Index Scan`.

**Nadie puede arrancar ninguna de las 4 partes hasta que este Paso 0 esté
completo.** Avisar al grupo apenas termine.

---

## 🔴 Mariano (vos) — Parte 1: Laboratorio de consultas analíticas lentas (la más pesada)

Concentra el 30% de "Medición" y buena parte del 25% de "Criterio de aceptación".

### Qué tenés que hacer

1. Elegir **al menos 2 consultas analíticas** de `queries.sql` que crucen **al
   menos 3 tablas** (ej: facturación por categoría y mes, ranking de usuarios
   por gasto con detalle de productos).
2. Para cada una:
   - Correr `EXPLAIN ANALYZE` **antes** de cualquier cambio y guardar el plan
     completo.
   - **Identificar el algoritmo de join** que eligió el optimizador para cada
     combinación de tablas (Nested Loop, Hash Join o Merge Join).
   - Pasarle el plan real a la IA y pedirle reescrituras/índices, **justificando
     en términos del nodo de join concreto** (no en generalidades).
   - Leer línea por línea antes de aplicar. Rechazar lo que no se entienda.
   - Aplicar sobre `copia_trabajo`, volver a medir.
   - Si agregar un índice **cambia el algoritmo de join** elegido (ej: de Hash
     Join a Nested Loop), documentarlo y explicar si el cambio fue conveniente.
3. Completar la tabla de la sección 1.2: Consulta | Algoritmo de join (antes) |
   Cambio aplicado | Algoritmo de join (después) | Mejora.
4. DUIA de tus interacciones.

### Entregable
- Tabla comparativa 1.2 completa, con planes antes/después (texto o captura).
- Filas de la DUIA correspondientes.

---

## 🟡 Facundo — Parte 2: Lectura crítica de planes de join

### Depende de: Parte 1 (Mariano)
No puede arrancar hasta que vos tengas **al menos un plan con 2+ nodos de
join** medido y guardado.

### Qué tiene que hacer

1. Tomar uno de los planes reales de la Parte 1 (con al menos 2 nodos de join).
2. Pedirle a la IA que lo explique en lenguaje natural, nodo por nodo, sin más
   contexto que el texto del plan.
3. Contrastar la explicación contra el plan real, prestando atención puntual a:
   - Si la IA identifica correctamente qué tabla es la **"externa"** y cuál la
     **"interna"** en cada `Nested Loop`.
   - Si confunde el **costo estimado de un nodo intermedio** con el **tiempo
     total** de la consulta.
4. Completar la tabla: Afirmación de la IA | ¿Correcta? | Corrección/evidencia.

### Entregable
- Tabla de lectura crítica completa.

---

## 🟢 Andrés — Parte 3: Ranking con función de ventana + subconsulta

### Depende de: Paso 0 únicamente
No depende de vos ni de Facundo — puede arrancar apenas esté la base lista con
los índices de la Semana 3 recreados.

### Qué tiene que hacer

1. Redactar una spec precisa para **2 consultas**:
   - (a) Un **ranking con función de ventana** (`RANK()`, `ROW_NUMBER()`, etc.)
   - (b) Una consulta con **subconsulta correlacionada**

   La spec debe fijar: tablas, **filtro de borrado lógico en cada tabla
   involucrada** (más fácil pifiarla con varias tablas), columnas de salida,
   criterio de partición/orden, y desempate.
2. Pedirle a la IA el SQL a partir de la spec, sin mostrarle solución previa.
3. Pedirle (o escribir) una segunda versión con estructura distinta
   (ej: subconsulta vs. JOIN + agregación) para la misma pregunta.
4. Verificar equivalencia con `EXCEPT` en ambos sentidos — debe dar 0 filas.
5. **Atención especial:** revisar que `eliminado = FALSE` esté en *cada* tabla
   del JOIN, no solo en la principal.

### Entregable
- Las 2 consultas: spec + SQL generado + SQL alternativo + verificación de
  equivalencia (resultado del `EXCEPT`).

---

## 🟢 Facundo — Parte 4: Competencia de optimización entre equipos

### Depende de: Paso 0 únicamente (no de las otras partes)

### Qué tiene que hacer

1. Recibir la consulta común (con ≥2 JOIN y una agregación).
2. Usar la IA para proponer reescrituras/índices, pero decidir y aplicar solo
   lo que el equipo pueda justificar.
3. Medir tiempo antes/después con `EXPLAIN ANALYZE` (gana el mejor tiempo
   real, no el costo estimado).
4. Documentar en la bitácora **toda** propuesta de la IA que no funcionó, no
   solo la que se terminó usando.
5. Completar la tabla: Equipo | Estrategia aplicada | Tiempo antes | Tiempo
   después | Mejora (x).

### Entregable
- Registro de la competencia completo.

---

## Diagrama de dependencias

```
Paso 0 (levantar la base + indices_semana3.sql)
   │
   ├──> Parte 1 (Mariano) ──> Parte 2 (Facundo)
   │
   ├──> Parte 3 (Andrés)      [sin dependencias además del Paso 0]
   │
   └──> Parte 4 (Facundo)     [sin dependencias además del Paso 0]
```

**Cuello de botella real:** el Paso 0 primero, y dentro de las partes, solo la
Parte 2 depende de que vos termines al menos una consulta de la Parte 1 —
Andrés y la Parte 4 de Facundo pueden avanzar en paralelo apenas la base esté lista.

---

## Checklist de entrega

- [ ] Paso 0 completo: base levantada, carga masiva aplicada, **`indices_semana3.sql`
      corrido y confirmado**
- [ ] Tabla comparativa Parte 1 (algoritmo de join antes/después, capturas o texto)
- [ ] Tabla de lectura crítica Parte 2
- [ ] Las 2 consultas de la Parte 3 (spec + SQL + verificación de equivalencia)
- [ ] Registro de la competencia Parte 4
- [ ] DUIA completa (los 3 integrantes)
- [ ] Cada uno puede explicar en la defensa oral su parte y, a grandes rasgos,
      de dónde salió el índice/plan que usan las partes que dependen de la suya

## Peso de cada parte en la nota

| Dimensión | Qué se evalúa | Peso | Parte | Quién |
|---|---|---|---|---|
| Medición | EXPLAIN ANALYZE antes/después, identificando algoritmo de join | 30% | Parte 1 | Mariano |
| Criterio de aceptación | Propuestas de IA validadas contra el plan real | 25% | Parte 1 (principalmente) | Mariano |
| Lectura crítica | Imprecisiones detectadas en planes con varios JOIN | 20% | Parte 2 | Facundo |
| Equivalencia verificada | Consultas alternativas (incl. rankings) comprobadas equivalentes | 15% | Parte 3 | Andrés |
| Bitácora y defensa | DUIA completa y capacidad de explicar decisiones | 10% | Transversal (incl. Parte 4) | Los 3 |
