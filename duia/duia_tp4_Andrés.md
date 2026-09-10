# Declaración de Uso de IA (DUIA) — TP4 Semana 4
**Integrante:** Andrés  
**Materia:** Base de Datos II — Tecnicatura Universitaria en Programación (UTN)  
**Modelo de IA utilizado:** Nvidia Nemotron 3.5 (vía OpenCode)

---

## Registro de Interacciones de IA (DUIA)

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / se descartó — por qué |
| :--- | :--- | :--- | :--- |
| **Nemotron 3.5**<br>*(OpenCode)* | Generar consulta analítica de ranking con función de ventana (`DENSE_RANK()`) y versiones alternativas (CTE y Subconsulta en `FROM`). | *"Genera una consulta SQL sobre el esquema Food Store que devuelva para cada usuario vigente (`eliminado = FALSE`) con al menos un pedido no eliminado (`eliminado = FALSE`) su nombre completo (`u.nombre \|\| ' ' \|\| u.apellido`), total gastado (`SUM(p.total)`) y su puesto en un ranking de mayor a menor gasto usando `DENSE_RANK()`. En caso de empate en el gasto, desempata por `u.id` ascendente. No uses `SELECT *`. Genera además una Versión 2a con CTE, una Versión 2b con subconsulta en `FROM`, y los bloques de prueba con `EXCEPT` en ambas direcciones."* | **Aceptado:** Generó correctamente el SQL con las 3 variantes (JOIN directo, CTE y Subquery en `FROM`). Todas las versiones aplicaron adecuadamente el filtro de borrado lógico (`eliminado = FALSE`) tanto en la tabla `usuario` como en `pedido`. Se ejecutaron los scripts de verificación con `EXCEPT` obteniendo 0 filas de diferencia, garantizando equivalencia semántica total. |
| **Nemotron 3.5**<br>*(OpenCode)* | Generar consulta con subconsulta correlacionada y su versión equivalente estructurada con `JOIN` + agregación. | *"Genera una consulta SQL sobre Food Store que devuelva todos los productos vigentes (`eliminado = FALSE`) cuyo precio sea mayor al precio promedio de los productos pertenecientes a su misma categoría. Versión 1: resolver usando una subconsulta correlacionada en la cláusula `WHERE`. Versión 2: resolver mediante un `JOIN` con una subconsulta que agrupe por `categoria_id` y calcule el promedio. Salida explícita: `p.id`, `p.nombre`, `p.categoria_id`, `p.precio`. Garantiza el borrado lógico en todas las instancias y entrega la verificación con `EXCEPT`."* | **Aceptado:** La IA estructuró correctamente la correlación por `categoria_id` en la cláusula `WHERE` para la Versión 1 y la agregación previa por categoría para la Versión 2. Se constató que no olvidó el filtro `eliminado = FALSE` en la subconsulta correlacionada ni en el bloque agrupado. Las pruebas bilaterales de `EXCEPT` arrojaron 0 filas. |

---

## Resumen Técnico del Trabajo Realizado

### 1. Consulta (a) — Ranking de usuarios por gasto
- **Mapeo de la especificación:** Se requería listar a los usuarios con al menos un pedido vigente, calculando el gasto acumulado y asignando un ranking.
- **Implementación de Ventana:** Se utilizó `DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC)` para asegurar que no existan huecos en la numeración ante empates y garantizando un orden determinista en la salida gracias al criterio de desempate por `u.id`.
- **Estructuras probadas:**
  1. **Versión 1 (JOIN Directo):** Agregación y función de ventana en el `GROUP BY` principal.
  2. **Versión 2a (CTE / WITH):** Aislando el cálculo del gasto total en la tabla temporal `totales_usuarios`.
  3. **Versión 2b (Subconsulta en `FROM`):** Pre-agregando pedidos con `HAVING COUNT(p.id) >= 1`.
- **Resultado de equivalencia:**  
  `(V1 EXCEPT V2a) = 0 filas`  
  `(V2a EXCEPT V1) = 0 filas`  
  `(V1 EXCEPT V2b) = 0 filas`  
  `(V2b EXCEPT V1) = 0 filas`

### 2. Consulta (b) — Subconsulta correlacionada (Productos sobre promedio)
- **Mapeo de la especificación:** Comparación de cada producto contra el promedio de su misma categoría.
- **Implementación:**
  1. **Versión 1 (Correlacionada):** Para cada fila del query externo (`p.categoria_id`), la subconsulta evalúa el `AVG(p2.precio)` filtrando por la misma categoría.
  2. **Versión 2 (JOIN + Agregación):** Subconsulta derivada que calcula `AVG(precio)` agrupando por `categoria_id`, seguida de un `INNER JOIN`.
- **Resultado de equivalencia:**  
  `(V1 EXCEPT V2) = 0 filas`  
  `(V2 EXCEPT V1) = 0 filas`

---

## Archivos Generados e Integrados
- `Andrés_parte3a.sql`: Código ejecutable de las 3 variantes de ranking y los 4 bloques de comprobación bilateral `EXCEPT`.
- `Andrés_parte3b.sql`: Código ejecutable de la subconsulta correlacionada, la variante con `JOIN` y la verificación `EXCEPT`.
- `duia_tp4_Andrés.md`: Documento de bitácora y justificación para la entrega del grupo.
