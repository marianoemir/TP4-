# Food Store — TP4: Reportes analíticos asistidos por IA (Base de Datos II)

Proyecto integrador de un sistema de venta de comida, implementado en PostgreSQL.
Este repositorio contiene el Trabajo Práctico de la **Semana 4** (Unidad 2:
Optimización de Consultas) — *Reportes analíticos asistidos por IA sobre Food
Store: joins, subconsultas, agregación y ventana* — resuelto en grupo de 3
integrantes con OpenCode y Kiro como herramientas de IA.

## Grupo

Grupo 10

**Integrantes:**
- Mariano Chirino
- Andrés Fabre
- Facundo Quiroga

## Repositorio

**Link:** https://github.com/marianoemir/TP4-

## Requisitos previos (heredados de la Semana 3)

Este TP no vuelve a poblar ni indexar la base desde cero: parte de la
`copia_trabajo` tal como quedó al cierre de la Semana 3.

| Archivo | Contenido |
|---|---|
| `Archivos necesarios para la BD/schema.sql` | Tipos ENUM, tablas, constraints e índices base |
| `Archivos necesarios para la BD/objects.sql` | Vistas, función de cálculo, triggers y procedimiento `sp_crear_pedido` |
| `Archivos necesarios para la BD/data.sql` | Datos de prueba (categorías, productos, usuarios, pedidos) |
| `Archivos necesarios para la BD/carga_masiva.sql` | Población masiva: 20.000 usuarios, 50.000 productos, 200.000 pedidos y sus detalles |
| `Archivos necesarios para la BD/indices_semana3.sql` | Índices creados y medidos en la Semana 3 (`idx_pedido_fecha_estado_vigente`, `idx_pedido_usuario_total_estado`), dados por existentes en este TP |

**Orden de ejecución (ya aplicado, no forma parte de esta entrega):**
`schema.sql → objects.sql → data.sql → carga_masiva.sql → indices_semana3.sql`

> Nota: el índice de producto/categoría propuesto en la Semana 3 no se
> recreó — el optimizador lo ignoró y no produjo ninguna mejora medible (ver
> `Tabla_de_resultados_seccion_2.2.md` de la entrega anterior).


| Archivo | Qué contiene |
|---|---|
| `entregables_tp4\parte1_laboratorio_joins/laboratorio_joins.md` | 2 consultas analíticas lentas que cruzan ≥3 tablas (facturación por categoría/mes; historial de compras por usuario), plan real antes/después con `EXPLAIN ANALYZE`, algoritmo de join identificado en cada caso (Hash Join / Nested Loop), y validación crítica de las propuestas de índice de la IA |
| `entregables/parte2_lectura_critica/lectura_critica_joins.md` | Explicación de un plan de 3 nodos `Nested Loop` generada por IA (solo a partir del texto del plan), contrastada línea por línea contra el plan real — verificando identificación de tabla externa/interna y lectura correcta de tiempos acumulados vs. propios |
| `entregables/parte3_consultas_resumen/Andrés_parte3.md`, `Andres_parte3a.sql`, `Andres_parte3b.sql` | (a) Ranking de usuarios por gasto con `DENSE_RANK()`, en 3 versiones estructuralmente distintas (JOIN directo, CTE, subquery); (b) productos con precio superior al promedio de su categoría, con subconsulta correlacionada vs. JOIN + agregación. Ambas verificadas con `EXCEPT` en ambos sentidos |
| `entregables/parte4_competencia/competencia_tp4.md` | Registro de la competencia de optimización entre equipos sobre la consulta común de la cátedra: estrategia ganadora, propuesta descartada y bitácora de motivos |
| `duia/` | Declaración de Uso de IA, una entrada por cada uso relevante de IA en las 4 partes |
### Quién hizo qué

| Parte | Integrante | Contenido |
|---|---|---|
| Parte 1 — Laboratorio de consultas analíticas lentas | Mariano Chirino | 2 consultas con ≥3 JOIN, algoritmo de join identificado en cada plan real, 3 de 4 propuestas de índice de la IA rechazadas por no aplicar al escenario real (asumían filtros que la consulta no tenía), corrección del borrado lógico faltante en `producto`/`categoria` |
| Parte 2 — Lectura crítica de planes de join | Facundo Quiroga | Contraste de una explicación de IA sobre el plan de 3 `Nested Loop` de la Consulta 2 (Parte 1): 2 imprecisiones detectadas (confusión de tiempo acumulado con tiempo propio del nodo; omisión del efecto de `loops` al reportar tiempos unitarios) y 1 afirmación correcta (identificación de outer/inner) |
| Parte 3 — Consultas resumen y subconsultas | Andrés Fabre | Ranking de usuarios por gasto (3 versiones) y productos por encima del precio promedio de su categoría (2 versiones), ambas con especificación precisa de tablas, filtro de borrado lógico, columnas de salida y desempate, verificadas con `EXCEPT` |
| Parte 4 — Competencia de optimización | Facundo Quiroga (con el equipo: Mariano Chirino, Andrés Fabre) | Índice parcial `idx_pedido_usuario_fecha_vigente` sobre `pedido(usuario_id, fecha DESC) WHERE NOT eliminado`, aplicado sobre la consulta común — mejora real de 5.45x (4.58 → 0.84 ms). Índice alternativo en `detalle_pedido(producto_id, pedido_id)` descartado y documentado igual que el ganador, sin mejora medible |

El detalle completo de cada parte (spec o prompt usado, qué generó la IA, qué
se aceptó o descartó y por qué, y la verificación con el motor real) está en
los archivos de `entregables/` y en la `duia/` correspondiente.

## Cómo levantar el proyecto localmente

```bash
# 1. Crear la plantilla con el esquema y el seed chico
createdb plantilla_food_store
psql -d plantilla_food_store -f "Archivos necesarios para la BD/schema.sql"
psql -d plantilla_food_store -f "Archivos necesarios para la BD/objects.sql"
psql -d plantilla_food_store -f "Archivos necesarios para la BD/data.sql"

# 2. Crear una copia de trabajo descartable a partir de la plantilla
createdb -T plantilla_food_store copia_trabajo

# 3. Aplicar la carga masiva y los índices de la Semana 3 (prerrequisitos de este TP)
psql -d copia_trabajo -f "Archivos necesarios para la BD/carga_masiva.sql"
psql -d copia_trabajo -f "Archivos necesarios para la BD/indices_semana3.sql"
```

Antes de aplicar cualquier cambio sobre la base, se sigue el flujo de
`protocolo_seguridad.md`: nunca se trabaja sobre `plantilla_food_store`
directamente, siempre sobre una copia descartable (`copia_trabajo`), con
respaldo previo (`pg_dump` o Backup de pgAdmin) antes de cualquier cambio
estructural, y `ANALYZE` corrido después de cualquier carga masiva o creación
de índice, antes de medir con `EXPLAIN ANALYZE`.

## Criterio de aceptación

Ninguna propuesta de la IA se aplicó "porque lo dijo la IA": cada índice o
reescritura se aplicó solo después de poder explicar, línea por línea, qué
nodo concreto del plan atacaba y por qué se esperaba que mejorara. Se
documentaron también los casos en los que la IA se equivocó en su lectura del
plan (Parte 2) y los casos en los que una propuesta no mejoró el tiempo real
(Parte 1, Parte 4), en vez de descartarlos en silencio.
