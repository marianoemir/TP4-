# Parte 1 — Laboratorio de consultas analíticas lentas

**Integrante:** Mariano
**Materia:** Base de Datos II (UTN) — Unidad 2: Optimización de Consultas
**Proyecto Integrador:** Food Store (TP4 Semana 4)

---

## Consulta 1 — Facturación por categoría y por mes

Cruza 4 tablas: `detalle_pedido`, `pedido`, `producto`, `categoria`.

```sql
SELECT c.nombre AS categoria,
       date_trunc('month', ped.fecha) AS mes,
       SUM(dp.subtotal) AS factura
FROM detalle_pedido dp
JOIN pedido ped ON ped.id = dp.pedido_id AND ped.eliminado = FALSE
JOIN producto pr ON pr.id = dp.producto_id
JOIN categoria c ON c.id = pr.categoria_id
WHERE dp.eliminado = FALSE
GROUP BY c.nombre, date_trunc('month', ped.fecha)
ORDER BY mes, facturado DESC;
```

### Plan "ANTES"

```
"Incremental Sort  (cost=18979.79..19876.91 rows=3000 width=50) (actual time=588.003..600.975 rows=90 loops=1)"
"  Sort Key: (date_trunc('month'::text, (ped.fecha)::timestamp with time zone)), (sum(dp.subtotal)) DESC"
"  Presorted Key: (date_trunc('month'::text, (ped.fecha)::timestamp with time zone))"
"  Full-sort Groups: 3  Sort Method: quicksort  Average Memory: 26kB  Peak Memory: 26kB"
"  Buffers: shared hit=11267"
"  ->  Finalize GroupAggregate  (cost=18978.09..19790.64 rows=3000 width=50) (actual time=587.815..600.867 rows=90 loops=1)"
"        Group Key: (date_trunc('month'::text, (ped.fecha)::timestamp with time zone)), c.nombre"
"        Buffers: shared hit=11264"
"        ->  Gather Merge  (cost=18978.09..19678.14 rows=6000 width=50) (actual time=587.793..600.666 rows=260 loops=1)"
"              Workers Planned: 2"
"              Workers Launched: 2"
"              Buffers: shared hit=11264"
"              ->  Sort  (cost=17978.06..17985.56 rows=3000 width=50) (actual time=517.752..517.768 rows=87 loops=3)"
"                    Sort Key: (date_trunc('month'::text, (ped.fecha)::timestamp with time zone)), c.nombre"
"                    Sort Method: quicksort  Memory: 33kB"
"                    Buffers: shared hit=11264"
"                    ->  Partial HashAggregate  (cost=17752.30..17804.80 rows=3000 width=50) (actual time=517.526..517.587 rows=87 loops=3)"
"                          Group Key: date_trunc('month'::text, (ped.fecha)::timestamp with time zone), c.nombre"
"                          Batches: 1  Memory Usage: 177kB"
"                          Buffers: shared hit=11232"
"                          ->  Hash Join  (cost=7843.55..16502.26 rows=166672 width=25) (actual time=108.345..438.150 rows=133337 loops=3)"
"                                Hash Cond: (pr.categoria_id = c.id)"
"                                Buffers: shared hit=11232"
"                                ->  Hash Join  (cost=7842.42..14921.21 rows=166672 width=19) (actual time=107.519..347.389 rows=133337 loops=3)"
"                                      Hash Cond: (dp.producto_id = pr.id)"
"                                      Buffers: shared hit=11199"
"                                      ->  Parallel Hash Join  (cost=5807.06..12448.30 rows=166672 width=19) (actual time=57.219..214.027 rows=133337 loops=3)"
"                                            Hash Cond: (dp.pedido_id = ped.id)"
"                                            Buffers: shared hit=8469"
"                                            ->  Parallel Seq Scan on detalle_pedido dp  (cost=0.00..6203.72 rows=166672 width=23) (actual time=0.033..54.060 rows=133337 loops=3)"
"                                                  Filter: (NOT eliminado)"
"                                                  Rows Removed by Filter: 1"
"                                                  Buffers: shared hit=4537"
"                                            ->  Parallel Hash  (cost=4765.36..4765.36 rows=83336 width=12) (actual time=56.363..56.364 rows=66668 loops=3)"
"                                                  Buckets: 262144  Batches: 1  Memory Usage: 11520kB"
"                                                  Buffers: shared hit=3932"
"                                                  ->  Parallel Seq Scan on pedido ped  (cost=0.00..4765.36 rows=83336 width=12) (actual time=0.020..28.226 rows=66668 loops=3)"
"                                                        Filter: (NOT eliminado)"
"                                                        Rows Removed by Filter: 0"
"                                                        Buffers: shared hit=3932"
"                                      ->  Hash  (cost=1410.16..1410.16 rows=50016 width=16) (actual time=50.024..50.025 rows=50016 loops=3)"
"                                            Buckets: 65536  Batches: 1  Memory Usage: 2857kB"
"                                            Buffers: shared hit=2730"
"                                            ->  Seq Scan on producto pr  (cost=0.00..1410.16 rows=50016 width=16) (actual time=0.951..28.286 rows=50016 loops=3)"
"                                                  Buffers: shared hit=2730"
"                                ->  Hash  (cost=1.06..1.06 rows=6 width=18) (actual time=0.733..0.733 rows=6 loops=3)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                      Buffers: shared hit=3"
"                                      ->  Seq Scan on categoria c  (cost=0.00..1.06 rows=6 width=18) (actual time=0.716..0.719 rows=6 loops=3)"
"                                            Buffers: shared hit=3"
"Planning Time: 42.920 ms"
"Execution Time: 601.667 ms"
```

**Algoritmos de join identificados:** 3 nodos, todos `Hash Join` (uno de ellos,
`Parallel Hash Join`, ejecutado por 2 workers en paralelo). Tiene sentido: la
consulta agrupa el 100% de los datos (no hay ningún `WHERE` selectivo sobre
fecha ni categoría), así que el optimizador arma tablas hash completas en vez
de saltar con índices.

**Anomalía detectada antes de consultar a la IA:** ni `producto` ni `categoria`
muestran `Filter: (NOT eliminado)` en el plan — confirmando que la consulta
original no aplicaba el borrado lógico en esas dos tablas (solo en `pedido` y
`detalle_pedido`, vía el `ON`/`WHERE`).

### Prompt usado

> "Tengo este plan de EXPLAIN ANALYZE de PostgreSQL para una consulta que cruza
> detalle_pedido, pedido, producto y categoria (facturación por categoría y mes).
> Proponeme índices o reescrituras que lo mejoren, justificando cada propuesta en
> términos del nodo de join concreto que aparece en el plan (indicá si ataca el
> Hash Join entre detalle_pedido y pedido, el de producto, o el de categoria), no
> en generalidades. No apliques nada, solo proponé." + plan completo de arriba.

### Respuesta de la IA (resumen de las 4 propuestas)

1. Índice en `detalle_pedido(pedido_id)` + aprovechar `idx_pedido_fecha_estado_vigente`, justificado **"si la consulta incluye un filtro por rango de fechas"**.
2. Índice en `detalle_pedido(producto_id)`, justificado **"si la consulta filtra previamente productos vigentes o de categorías específicas"**.
3. Aprovechar `idx_producto_categoria_id`, justificado **"si la consulta original incluyera un filtro por categoría"**.
4. Agregar `eliminado = FALSE` en `producto` y `categoria` (faltaba), y usar las vistas vigentes.

### Validación y decisión — Criterio de aceptación

**Se descartaron las propuestas 1, 2 y 3.** Las tres se justifican con
condicionales ("si la consulta incluye...", "si filtra...") que describen una
consulta **distinta** a la que realmente se ejecutó — la consulta real no tiene
ningún filtro selectivo por fecha ni por categoría, agrupa el 100% de las filas.
Sin un predicado selectivo, ningún índice cambia el plan: el motor tiene que leer
la tabla completa de todos modos, por lo que un Seq Scan (o su versión paralela)
sigue siendo la estrategia correcta. La IA propuso optimizaciones válidas para un
escenario hipotético, no para el plan real entregado.

**Se aceptó la propuesta 4** (parcialmente): agregar el filtro de borrado lógico
faltante en `producto` y `categoria`, por ser una corrección real de las reglas
del proyecto (`conventions.md`: el filtro debe aplicarse en cada tabla del JOIN),
no una optimización de performance.

### Consulta corregida

```sql
SELECT c.nombre AS categoria,
       date_trunc('month', ped.fecha) AS mes,
       SUM(dp.subtotal) AS facturado
FROM detalle_pedido dp
JOIN pedido ped ON ped.id = dp.pedido_id AND ped.eliminado = FALSE
JOIN producto pr ON pr.id = dp.producto_id AND pr.eliminado = FALSE
JOIN categoria c ON c.id = pr.categoria_id AND c.eliminado = FALSE
WHERE dp.eliminado = FALSE
GROUP BY c.nombre, date_trunc('month', ped.fecha)
ORDER BY mes, facturado DESC;
```

### Plan "DESPUÉS"

```
"Incremental Sort  (cost=18518.28..19264.27 rows=2500 width=50) (actual time=627.869..640.837 rows=90 loops=1)"
"  Buffers: shared hit=11264"
"  ->  Finalize GroupAggregate  (cost=18516.87..19194.00 rows=2500 width=50) (actual time=627.694..640.744 rows=90 loops=1)"
"        Buffers: shared hit=11264"
"        ->  Gather Merge  (cost=18516.87..19100.25 rows=5000 width=50) (actual time=627.620..640.489 rows=260 loops=1)"
"              Workers Planned: 2  Workers Launched: 2"
"              ->  Sort (cost=17516.85..17523.10 rows=2500 width=50) (actual time=569.687..569.702 rows=87 loops=3)"
"                    ->  Partial HashAggregate (cost=17332.00..17375.75 rows=2500 width=50) (actual time=569.477..569.539 rows=87 loops=3)"
"                          ->  Parallel Hash Join  (cost=7843.52..16290.34 rows=138888 width=25) (actual time=96.742..482.337 rows=133334 loops=3)"
"                                Hash Cond: (dp.pedido_id = ped.id)"
"                                Buffers: shared hit=11232"
"                                ->  Hash Join  (cost=2036.46..9424.25 rows=138888 width=25) (actual time=41.718..255.900 rows=133334 loops=3)"
"                                      Hash Cond: (pr.categoria_id = c.id)"
"                                      Buffers: shared hit=7270"
"                                      ->  Hash Join  (cost=2035.34..8676.60 rows=166665 width=23) (actual time=40.087..208.850 rows=133334 loops=3)"
"                                            Hash Cond: (dp.producto_id = pr.id)"
"                                            Buffers: shared hit=7267"
"                                            ->  Parallel Seq Scan on detalle_pedido dp  (actual rows=133337 loops=3)"
"                                                  Filter: (NOT eliminado)"
"                                                  Buffers: shared hit=4537"
"                                            ->  Hash  (cost=1410.16..1410.16 rows=50014 width=16) (actual rows=50015 loops=3)"
"                                                  ->  Seq Scan on producto pr  (actual rows=50015 loops=3)"
"                                                        Filter: (NOT eliminado)"
"                                                        Rows Removed by Filter: 1"
"                                                        Buffers: shared hit=2730"
"                                      ->  Hash  (cost=1.06..1.06 rows=5 width=18) (actual rows=5 loops=3)"
"                                            ->  Seq Scan on categoria c  (actual rows=5 loops=3)"
"                                                  Filter: (NOT eliminado)"
"                                                  Rows Removed by Filter: 1"
"                                                  Buffers: shared hit=3"
"                                ->  Parallel Hash  (cost=4765.36..4765.36 rows=83336 width=12) (actual rows=66668 loops=3)"
"                                      ->  Parallel Seq Scan on pedido ped (actual rows=66668 loops=3)"
"                                            Filter: (NOT eliminado)"
"                                            Buffers: shared hit=3932"
"Planning Time: 1.377 ms"
"Execution Time: 641.616 ms"
```

**Confirmado:** ahora `producto` y `categoria` sí muestran `Filter: (NOT eliminado)`.
El algoritmo de join **no cambió** (siguen siendo 3 Hash Join, uno paralelo). El
tiempo real subió levemente (601.667 → 641.616 ms): el motor ahora evalúa un
filtro adicional en cada fila de `producto` y `categoria` que antes no evaluaba.
**No es una regresión de performance a corregir** — es el costo de que la
consulta sea correcta en vez de rápida-pero-incorrecta.

---

## Consulta 2 — Historial de compras de un usuario, con detalle de productos

Cruza 4 tablas: `usuario`, `pedido`, `detalle_pedido`, `producto`. Elegida
deliberadamente para contrastar con la Consulta 1: al filtrar por un usuario
puntual, se espera un algoritmo de join distinto.

```sql
SELECT u.nombre, u.apellido, p.fecha, p.estado, pr.nombre AS producto, dp.cantidad, dp.subtotal
FROM usuario u
JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
JOIN detalle_pedido dp ON dp.pedido_id = p.id AND dp.eliminado = FALSE
JOIN producto pr ON pr.id = dp.producto_id
WHERE u.id = 1
ORDER BY p.fecha DESC;
```

### Plan "ANTES"

```
"Sort  (cost=177.49..177.54 rows=20 width=60) (actual time=0.976..0.979 rows=22 loops=1)"
"  Sort Key: p.fecha DESC"
"  Sort Method: quicksort  Memory: 26kB"
"  Buffers: shared hit=144"
"  ->  Nested Loop  (cost=5.50..177.06 rows=20 width=60) (actual time=0.254..0.915 rows=22 loops=1)"
"        Buffers: shared hit=141"
"        ->  Nested Loop  (cost=5.21..170.70 rows=20 width=54) (actual time=0.230..0.750 rows=22 loops=1)"
"              Buffers: shared hit=75"
"              ->  Nested Loop  (cost=4.79..51.51 rows=10 width=43) (actual time=0.184..0.279 rows=11 loops=1)"
"                    Buffers: shared hit=21"
"                    ->  Index Scan using usuario_pkey on usuario u  (cost=0.29..8.30 rows=1 width=35) (actual time=0.052..0.052 rows=1 loops=1)"
"                          Index Cond: (id = 1)"
"                          Buffers: shared hit=6"
"                    ->  Bitmap Heap Scan on pedido p  (cost=4.50..43.11 rows=10 width=24) (actual time=0.129..0.221 rows=11 loops=1)"
"                          Recheck Cond: (usuario_id = 1)"
"                          Filter: (NOT eliminado)"
"                          Rows Removed by Filter: 1"
"                          Heap Blocks: exact=12"
"                          Buffers: shared hit=15"
"                          ->  Bitmap Index Scan on idx_pedido_usuario_id  (cost=0.00..4.50 rows=10 width=0) (actual time=0.038..0.038 rows=12 loops=1)"
"                                Index Cond: (usuario_id = 1)"
"                                Buffers: shared hit=3"
"              ->  Index Scan using detalle_pedido_pedido_id_producto_id_key on detalle_pedido dp  (cost=0.42..11.90 rows=2 width=27) (actual time=0.034..0.041 rows=2 loops=11)"
"                    Index Cond: (pedido_id = p.id)"
"                    Filter: (NOT eliminado)"
"                    Buffers: shared hit=54"
"        ->  Index Scan using producto_pkey on producto pr  (cost=0.29..0.32 rows=1 width=22) (actual time=0.007..0.007 rows=1 loops=22)"
"              Index Cond: (id = dp.producto_id)"
"              Buffers: shared hit=66"
"Planning Time: 33.214 ms"
"Execution Time: 1.157 ms"
```

**Algoritmos de join identificados:** los 3 nodos son `Nested Loop`. Completo
contraste con la Consulta 1: al partir de una sola fila de `usuario` (vía
`usuario_pkey`, `id = 1`), el optimizador "salta" con índices hacia las tablas
relacionadas (`idx_pedido_usuario_id`, la unique key de `detalle_pedido`,
`producto_pkey`) en vez de construir tablas hash completas — es la estrategia
correcta cuando el volumen de filas final es chico.

**Anomalía detectada:** el nodo `Index Scan using producto_pkey on producto pr`
**no tiene ningún `Filter:`** debajo — a diferencia de los nodos de `pedido` y
`detalle_pedido`, que sí muestran `Filter: (NOT eliminado)`. Confirma en el
motor real que la consulta no filtraba borrado lógico en `producto`.

### Corrección aplicada (sin necesidad de nueva consulta a la IA)

Se agregó `AND pr.eliminado = FALSE` directamente, por ser la misma corrección
de borrado lógico ya identificada como patrón en la Consulta 1 — no hizo falta
un nuevo prompt para este hallazgo puntual.

```sql
SELECT u.nombre, u.apellido, p.fecha, p.estado, pr.nombre AS producto, dp.cantidad, dp.subtotal
FROM usuario u
JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
JOIN detalle_pedido dp ON dp.pedido_id = p.id AND dp.eliminado = FALSE
JOIN producto pr ON pr.id = dp.producto_id AND pr.eliminado = FALSE
WHERE u.id = 1
ORDER BY p.fecha DESC;
```

### Plan "DESPUÉS"

```
"Sort  (cost=177.49..177.54 rows=20 width=60) (actual time=0.595..0.600 rows=22 loops=1)"
"  Buffers: shared hit=138"
"  ->  Nested Loop  (cost=5.50..177.06 rows=20 width=60) (actual time=0.170..0.559 rows=22 loops=1)"
"        ->  Nested Loop  (cost=5.21..170.70 rows=20 width=54) (actual time=0.153..0.378 rows=22 loops=1)"
"              ->  Nested Loop  (cost=4.79..51.51 rows=10 width=43) (actual time=0.129..0.170 rows=11 loops=1)"
"                    ->  Index Scan using usuario_pkey on usuario u  (actual time=0.052..0.053 rows=1 loops=1)"
"                          Index Cond: (id = 1)"
"                    ->  Bitmap Heap Scan on pedido p  (actual time=0.073..0.108 rows=11 loops=1)"
"                          Filter: (NOT eliminado)"
"                          Rows Removed by Filter: 1"
"              ->  Index Scan using detalle_pedido_pedido_id_producto_id_key on detalle_pedido dp  (actual time=0.014..0.017 rows=2 loops=11)"
"                    Filter: (NOT eliminado)"
"        ->  Index Scan using producto_pkey on producto pr  (cost=0.29..0.32 rows=1 width=22) (actual time=0.007..0.007 rows=1 loops=22)"
"              Index Cond: (id = dp.producto_id)"
"              Filter: (NOT eliminado)"
"              Buffers: shared hit=66"
"Planning Time: 1.552 ms"
"Execution Time: 0.709 ms"
```

**Confirmado:** `producto` ahora muestra `Filter: (NOT eliminado)`. Algoritmo de
join sin cambios (3x Nested Loop). Tiempo: 1.157 → 0.709 ms (variación esperable
por ruido de medición dado el bajo volumen de filas, no atribuible al filtro).

---

## Tabla de resultados — sección 1.2

| Consulta | Algoritmo de join (antes) | Cambio aplicado | Algoritmo de join (después) | Mejora |
|---|---|---|---|---|
| 1. Facturación por categoría y mes | 3x Hash Join (1 paralelo) | Se descartaron 3 propuestas de índice de la IA (asumían filtros de fecha/categoría que la consulta real no tiene); se corrigió `eliminado = FALSE` faltante en `producto` y `categoria` | 3x Hash Join (1 paralelo) — **sin cambio de algoritmo** | Sin mejora de performance (601.667 → 641.616 ms, la corrección agrega costo); mejora de **corrección de datos** |
| 2. Historial de compras por usuario | 3x Nested Loop | Se corrigió `eliminado = FALSE` faltante en `producto` | 3x Nested Loop — **sin cambio de algoritmo** | Tiempo similar (1.157 → 0.709 ms, variación por bajo volumen); mejora de **corrección de datos** |

