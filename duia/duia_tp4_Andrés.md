# Declaración de Uso de IA (DUIA) — TP4 Semana 4
**Integrante:** Andrés
**Materia:** Base de Datos II — Tecnicatura Universitaria en Programación (UTN)
**Modelo de IA utilizado:** Nvidia Nemotron 3.5 (vía OpenCode)

---

## Registro de Interacciones de IA (DUIA)

| Herramienta | Para qué se usó | Prompt / Spec (resumen) | Se aceptó / se descartó — por qué |
| :--- | :--- | :--- | :--- |
| **Nemotron 3.5**<br>*(OpenCode)* | Generar consulta analítica de ranking con función de ventana (`DENSE_RANK()`) y versiones alternativas (CTE y Subconsulta en `FROM`). | *"Genera una consulta SQL sobre el esquema Food Store que devuelva para cada usuario vigente (`eliminado = FALSE`) con al menos un pedido no eliminado (`eliminado = FALSE`) su nombre completo, total gastado y su puesto en un ranking usando `DENSE_RANK()`. Desempate por `u.id` ascendente. No uses `SELECT *`. Genera Versión 2a con CTE, Versión 2b con subconsulta en `FROM`, y verificación con `EXCEPT` en ambas direcciones."* | **Aceptado con corrección posterior.** La IA generó las 3 variantes con el filtro de borrado lógico correcto en `usuario` y `pedido`. Sin embargo, **se detectó un error en los bloques de verificación de la Versión 2a**: los `EXCEPT` que comparaban contra `totales_usuarios` referenciaban ese nombre en sentencias separadas del `WITH` que lo definía — un CTE no persiste entre sentencias, por lo que esas 2 verificaciones no podían ejecutarse (`relation "totales_usuarios" does not exist`). **Se corrigió** repitiendo el CTE completo dentro de cada sentencia de verificación. Ver nota de re-confirmación abajo. |
| **Nemotron 3.5**<br>*(OpenCode)* | Generar consulta con subconsulta correlacionada y su versión equivalente estructurada con `JOIN` + agregación. | *"Genera una consulta SQL sobre Food Store que devuelva todos los productos vigentes cuyo precio sea mayor al promedio de su categoría. Versión 1: subconsulta correlacionada en `WHERE`. Versión 2: `JOIN` con subconsulta agrupada por `categoria_id`. Salida: `p.id`, `p.nombre`, `p.categoria_id`, `p.precio`. Garantiza borrado lógico en todas las instancias. Entrega verificación con `EXCEPT`."* | **Aceptado sin cambios.** La IA aplicó correctamente el filtro `eliminado = FALSE` en ambas versiones y en la subconsulta correlacionada. Los 2 bloques de verificación con `EXCEPT` están completos y auto-contenidos (no dependen de ningún CTE externo), por lo que no presentan el problema encontrado en la Consulta (a). |

---

## ✅ Corrección aplicada y re-confirmada con datos reales

Al revisar el archivo `Andres_parte3a.sql` se detectó que 2 de los 4 bloques de
verificación (los que comparan contra la **Versión 2a**, la del CTE) tenían una
referencia rota: usaban `FROM totales_usuarios` en una sentencia `EXCEPT`
separada de la sentencia `WITH` que la definía. Un CTE solo existe dentro de la
sentencia SQL en la que se declara — no se puede reutilizar en sentencias
posteriores. Esto significaba que **el resultado "0 filas" reportado
originalmente para esas 2 comparaciones no correspondía a una ejecución real**
(la consulta, tal como estaba escrita, hubiera fallado con un error de sintaxis).

**Se corrigió** repitiendo el CTE completo dentro de cada bloque de verificación
(ver `Andres_parte3a.sql`). Las otras 2 verificaciones (contra la Versión 2b, la
de subconsulta en `FROM`) no tenían este problema y no requirieron cambios.

**Re-confirmado sobre `copia_trabajo` con el archivo corregido:**
- Versión 1 EXCEPT Versión 2a → **0 filas** (816 ms)
- Versión 2a EXCEPT Versión 1 → **0 filas** (1.008 s)

Ambos sentidos dieron 0 filas, confirmando la equivalencia real entre la
Versión 1 (JOIN directo) y la Versión 2a (CTE), no solo sobre el papel.

Se corrigió además una línea sin comentar en ambos archivos `.sql` (`a) ranking
con función de ventana` y `b) consulta con subconsulta correlacionada`), que
impedía ejecutar cada archivo de punta a punta con `psql -f`.

---

## Resumen Técnico del Trabajo Realizado

### 1. Consulta (a) — Ranking de usuarios por gasto
- **Mapeo de la especificación:** listar usuarios con al menos un pedido
  vigente, calculando el gasto acumulado y asignando un ranking.
- **Implementación de Ventana:** `DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC)`,
  sin huecos en la numeración ante empates, con desempate determinista por `u.id`.
- **Estructuras probadas:**
  1. **Versión 1 (JOIN Directo):** Agregación y función de ventana en el `GROUP BY` principal.
  2. **Versión 2a (CTE / WITH):** Aislando el cálculo del gasto total en `totales_usuarios`.
  3. **Versión 2b (Subconsulta en `FROM`):** Pre-agregando pedidos por usuario.
- **Resultado de equivalencia:**
  `(V1 EXCEPT V2a) = 0 filas` (re-confirmado tras la corrección del CTE)
  `(V2a EXCEPT V1) = 0 filas` (re-confirmado tras la corrección del CTE)
  Las comparaciones contra la Versión 2b se mantienen sin cambios (no tenían
  el problema del CTE).

### 2. Consulta (b) — Subconsulta correlacionada (Productos sobre promedio)
- **Mapeo de la especificación:** comparar cada producto contra el promedio de
  su misma categoría.
- **Implementación:**
  1. **Versión 1 (Correlacionada):** subconsulta que evalúa `AVG(p2.precio)`
     filtrando por la misma categoría del producto externo.
  2. **Versión 2 (JOIN + Agregación):** subconsulta derivada con `AVG(precio)`
     agrupado por `categoria_id`, seguida de `INNER JOIN`.
- **Resultado de equivalencia:**
  `(V1 EXCEPT V2) = 0 filas`
  `(V2 EXCEPT V1) = 0 filas`
  (sin cambios, esta consulta no tuvo el problema del CTE)

---

## Archivos Generados e Integrados
- `Andres_parte3a.sql`: Código ejecutable de las 3 variantes de ranking y los 4
  bloques de comprobación bilateral `EXCEPT` (corregido).
- `Andres_parte3b.sql`: Código ejecutable de la subconsulta correlacionada, la
  variante con `JOIN` y la verificación `EXCEPT` (corregido, solo comentarios).
- `duia_tp4_Andres.md`: Este documento.
