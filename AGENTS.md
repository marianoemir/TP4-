# Food Store — Instrucciones para Agentes

## Stack Tecnológico

| Componente | Tecnología / Versión | Propósito |
|---|---|---|
| Motor BD | PostgreSQL | Base de datos relacional |
| Lenguaje | SQL / PL/pgSQL | Definición de esquema, vistas, funciones y procedimientos |

## Estructura de carpetas

Los archivos `.sql` del proyecto están dentro de la carpeta `Archivos necesarios para la BD/`, no en la raíz del repositorio.

## Orden de ejecución de los .sql

schema.sql → objects.sql → data.sql → carga_masiva.sql → indices_semana3.sql

Cada archivo depende del anterior; correrlos fuera de orden produce errores de referencia.
`carga_masiva.sql` solo se aplica sobre `copia_trabajo`, nunca sobre `plantilla_food_store`.

## Base de Conocimiento y Steering

- `Archivos necesarios para la BD/schema.sql`: Tipos ENUM, tablas, constraints e índices.
- `Archivos necesarios para la BD/objects.sql`: Vistas, función de cálculo, triggers y procedimiento `sp_crear_pedido`.
- `Archivos necesarios para la BD/data.sql`: Datos de prueba chicos (categorías, productos, usuarios, pedidos).
- `Archivos necesarios para la BD/queries.sql`: Historias de usuario resueltas y consultas analíticas (banco de consultas candidatas para el laboratorio).
- `Archivos necesarios para la BD/transacciones.sql`: Escenarios de concurrencia (de una entrega anterior, no se usa en este TP).
- `Archivos necesarios para la BD/carga_masiva.sql`: Script de población masiva (≥50.000 productos, ≥20.000 usuarios, ≥200.000 pedidos con detalles). Se aplica una sola vez sobre `copia_trabajo`.
- `protocolo_seguridad.md`: **Leer primero**: flujo obligatorio antes de tocar la BD (copia → transacción → respaldo → ANALYZE).
- `entregables_tp4/parte1_laboratorio_joins/`: consultas analíticas con ≥3 tablas, plan real antes/después identificando el algoritmo de join (Nested Loop, Hash Join, Merge Join).
- `entregables_tp4/parte2_lectura_critica_joins/`: contraste de la explicación de un plan con joins generada por IA contra el plan real.
- `entregables_tp4/parte3_consultas_resumen_ranking/`: ranking con función de ventana + consulta con subconsulta correlacionada, verificadas por equivalencia con EXCEPT.
- `entregables_tp4/parte4_competencia_tp4/`: competencia de optimización sobre una consulta con ≥2 JOIN y agregación.
- `duia_tp4.md`: Declaración de Uso de IA de esta entrega (una fila por cada uso relevante).
- `.kiro/steering/project-overview.md`: Visión general y orden de ejecución.
- `.kiro/steering/conventions.md`: Convenciones (nombres en singular, borrado lógico, tipos).
- `.kiro/steering/objects-and-patterns.md`: Triggers automáticos y procedimiento `sp_crear_pedido`.

## Índices ya existentes (de una entrega previa, no se recrean)

Sobre `copia_trabajo` ya deberían existir estos índices, creados y medidos en la práctica
anterior. Antes de proponer un índice nuevo, verificar si alguno de estos ya cubre el caso:

- `idx_producto_categoria_id` — soporta filtros por categoría en `producto`.
- `idx_pedido_usuario_id` — soporta filtros por usuario en `pedido`.
- `idx_producto_nombre_vigente` — índice parcial para búsquedas por nombre (solo vigentes).
- `idx_pedido_fecha_estado_vigente` — parcial, sobre `pedido(fecha, estado)`, para consultas por rango de fechas y estado.
- `idx_pedido_usuario_total_estado` — parcial, sobre `pedido(usuario_id, total)`, para agregaciones de gasto por usuario.

## Protocolo de seguridad ante la BD (obligatorio)

Ningún script (propio o generado por IA) se ejecuta directo sobre la base con datos. Flujo siempre:

1. Trabajar sobre una copia descartable: `createdb -T plantilla_food_store copia_trabajo`.
2. Todo script de escritura corre primero dentro de `BEGIN...ROLLBACK` y se inspecciona antes de aceptarlo.
3. Cambios estructurales (ALTER/DROP/CREATE TRIGGER/CREATE FUNCTION/migración/CREATE INDEX) requieren `pg_dump` de respaldo previo a `respaldos/`.
4. Después de cargar datos masivamente o de crear/eliminar un índice, correr `ANALYZE` sobre las tablas afectadas antes de medir con EXPLAIN ANALYZE.
5. Recién al final: `COMMIT` y luego commit en Git.

Detalles y comandos exactos en `protocolo_seguridad.md`.

## Reglas Duras del Proyecto

1. **Nombres de tablas:** En singular y español (`categoria`, `producto`, `usuario`, `pedido`, `detalle_pedido`).
2. **Borrado lógico:** Nunca ejecutar `DELETE`. Usar `UPDATE <tabla> SET eliminado = TRUE WHERE id = :id AND eliminado = FALSE`. La baja de un pedido completo requiere transacción: primero `detalle_pedido`, luego `pedido`.
3. **Altas de pedidos:** Usar siempre `CALL sp_crear_pedido(...)`. Nunca hacer `INSERT INTO pedido` + `INSERT INTO detalle_pedido` manualmente.
4. **Triggers automáticos:** No modificar los triggers de subtotal y totales (`trg_subtotal`, `trg_total_ins`, `trg_total_upd`). Al insertar en `detalle_pedido` solo se proveen `pedido_id`, `producto_id` y `cantidad`; `precio_unitario`, `subtotal` y `pedido.total` se completan solos.
5. **Vistas vigentes:** Utilizar vistas vigentes (`v_categorias_vigentes`, `v_productos_vigentes`, `v_pedidos_resumen`, `v_pedido_detalle`) para filtrar registros activos (`eliminado = FALSE`) en vez de escribir el filtro a mano.
6. **Transición de estado de pedido:** El trigger `trg_validar_estado_pedido` impide que un pedido pase de `CONFIRMADO` a `PENDIENTE`. No modificarlo ni eludirlo con `INSERT`/`UPDATE` directos.
7. **JOINs y borrado lógico (específico de este TP4):** al combinar varias tablas, el filtro `eliminado = FALSE` debe aplicarse en **cada tabla involucrada**, no solo en la principal — una consulta puede "parecer" correcta y filtrar mal si se omite el borrado lógico en alguna de las tablas unidas (por ejemplo, sumar pedidos de un usuario eliminado, o incluir productos de una categoría eliminada). Verificar esto explícitamente al validar equivalencia entre dos versiones de una misma consulta.
8. **Índices propuestos:** Ningún `CREATE INDEX` se aplica sin poder explicar en la defensa oral sobre qué columnas actúa y qué nodo del plan (incluyendo el algoritmo de join) espera que mejore.
