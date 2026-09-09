# Declaración de Uso de IA (DUIA) — Parte 1 (TP4)

**Nombre y Apellido:** Mariano Chirino
**Rol / Asignación:** Parte 1 — Laboratorio de consultas analíticas lentas
**Materia:** Base de Datos II (UTN) — Unidad 2: Optimización de Consultas
**Proyecto Integrador:** Food Store (TP4 Semana 4)

---

## Registro de Interacciones y Decisiones con IA

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / se descartó y por qué |
|---|---|---|---|
| OpenCode | Optimización Consulta 1 (Facturación por categoría y mes) | *"Proponé índices o reescrituras justificando cada propuesta en el nodo de join concreto del plan (Hash Join entre detalle_pedido/pedido, producto o categoría), no en generalidades. No apliques nada, solo proponé."* + plan real completo | **Se descartaron 3 de 4 propuestas.** Las propuestas de índices sobre `detalle_pedido(pedido_id)`, `detalle_pedido(producto_id)` y de aprovechar `idx_producto_categoria_id` se justificaban con condicionales ("si la consulta incluye un filtro por fecha...", "si filtra por categoría...") que describían una consulta distinta a la real — la consulta no tiene ningún filtro selectivo, agrupa el 100% de las filas, por lo que ningún índice cambia el plan. **Se aceptó** la 4ta propuesta: agregar `eliminado = FALSE` faltante en `producto` y `categoria` — corrección real de las reglas del proyecto, no optimización de performance. |
| — | Corrección Consulta 2 (Historial de compras por usuario) | No se consultó a la IA de nuevo para este hallazgo — se detectó el mismo patrón (falta de filtro de borrado lógico en `producto`) por inspección directa del plan, reutilizando el criterio ya validado en la Consulta 1. | **Se aplicó directamente** `AND pr.eliminado = FALSE`, sin necesidad de un nuevo prompt. |

---

## Justificación técnica para la defensa oral

1. **Consulta 1 (Hash Join x3, uno paralelo):** la ausencia de cualquier filtro
   selectivo (no hay `WHERE` por fecha ni categoría) obliga al motor a procesar
   el 100% de `detalle_pedido` (400.000+ filas) y `pedido` (200.000+ filas).
   Para ese volumen sin filtro, Hash Join es la estrategia correcta — no hay
   ningún índice que pueda evitar la lectura completa cuando se necesita el
   100% de las filas para agregar.
2. **Por qué se rechazaron 3 de 4 propuestas de la IA:** la IA generó
   propuestas técnicamente correctas *para un escenario distinto* al que se le
   entregó — describía mejoras que solo aplicarían si la consulta tuviera
   filtros que en realidad no tiene. Aceptar esas propuestas sin verificarlas
   contra el plan real hubiera significado crear índices que el optimizador
   nunca usaría (ya que no hay ningún predicado selectivo que puedan explotar).
3. **Consulta 2 (Nested Loop x3):** al filtrar por `u.id = 1`, el optimizador
   arranca desde una única fila de `usuario` y "salta" con índices existentes
   (`idx_pedido_usuario_id`, la unique key de `detalle_pedido`, `producto_pkey`)
   en vez de construir tablas hash completas — la selectividad alta favorece
   Nested Loop sobre Hash Join.
4. **Patrón repetido en ambas consultas:** faltaba el filtro `eliminado = FALSE`
   en `producto` (y en `categoria`, en la Consulta 1). Se corrigió en las dos.
   En la Consulta 1, la corrección **no mejoró el tiempo** (601.667 → 641.616 ms,
   aumentó levemente) — se documenta este resultado honestamente en vez de
   ocultarlo, porque el objetivo de esa corrección era la corrección funcional,
   no la performance.
