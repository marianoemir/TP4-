-- ==================================================================--------------------
-- Archivo: Andrés_parte3b.sql
-- Descripción: Consultas SQL sobre esquema Food Store que listan productos vigentes
-- cuyo precio es mayor al precio promedio de productos de su misma categoría.
-- Se aplica borrado lógico (eliminado = FALSE) en todas las tablas involucradas.
-- Se entregan dos versiones: subconsulta correlacionada y JOIN con subquery agrupada.
-- Incluye verificación EXCEPT.
-- =======================================================================

-- =======================================================================
b) consulta con subconsulta correlacionada
-- =======================================================================



-- =======================================================================
-- VERSION 1: Subconsulta correlacionada en la cláusula WHERE
-- =======================================================================
-- Se utiliza una subconsulta correlacionada (referencia a p.categoria_id desde
-- el query externo) que calcula el precio promedio de productos NO eliminados
-- de la misma categoría. El operador > compara el precio del producto actual
-- contra ese promedio.
--
-- Columnas seleccionadas explícitas (sin SELECT *):
--   - p.id, p.nombre, p.categoria_id, p.precio
-- =======================================================================
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
WHERE p.eliminado = FALSE
AND p.precio > (
    SELECT AVG(p2.precio)
    FROM producto p2
    WHERE p2.categoria_id = p.categoria_id
    AND p2.eliminado = FALSE
);

-- =======================================================================
-- VERSION 2: JOIN con subconsulta agrupada por categoría
-- =======================================================================
-- Se crea una subquery que calcula el precio promedio por categoría para
-- productos vigentes (eliminado = FALSE). Luego se hace JOIN con producto
-- y se filtra donde el precio del producto sea mayor al promedio de su categoría.
--
-- Este patrón permite que el optimizador procese la agregación por separado
-- antes del join, lo cual puede ser más eficiente en algunas bases de datos.
--
-- Columnas seleccionadas explícitas (sin SELECT *):
--   - p.id, p.nombre, p.categoria_id, p.precio
-- =======================================================================
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
INNER JOIN (
    SELECT categoria_id, AVG(precio) AS avg_precio
    FROM producto
    WHERE eliminado = FALSE
    GROUP BY categoria_id
) sub ON sub.categoria_id = p.categoria_id
WHERE p.eliminado = FALSE
AND p.precio > sub.avg_precio;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT: Versión 1 EXCEPT Versión 2
-- =======================================================================
-- Devuelve filas de la Versión 1 que NO aparecen en la Versión 2.
-- Si ambas consultas son equivalentes (mismos productos cumplen la condición),
-- el resultado será cero filas.
--
-- Se aplican los mismos filtros lógicos en ambas piernas.
-- =======================================================================
-- Pierna izquierda: Versión 1 (subconsulta correlacionada)
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
WHERE p.eliminado = FALSE
AND p.precio > (
    SELECT AVG(p2.precio)
    FROM producto p2
    WHERE p2.categoria_id = p.categoria_id
    AND p2.eliminado = FALSE
)

EXCEPT

-- Pierna derecha: Versión 2 (JOIN con subquery agrupada)
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
INNER JOIN (
    SELECT categoria_id, AVG(precio) AS avg_precio
    FROM producto
    WHERE eliminado = FALSE
    GROUP BY categoria_id
) sub ON sub.categoria_id = p.categoria_id
WHERE p.eliminado = FALSE
AND p.precio > sub.avg_precio;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT: Versión 2 EXCEPT Versión 1
-- =======================================================================
-- Devuelve filas de la Versión 2 que NO aparecen en la Versión 1.
-- Si ambas son equivalentes, también devuelve cero filas.
-- =======================================================================
-- Pierna izquierda: Versión 2 (JOIN con subquery agrupada)
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
INNER JOIN (
    SELECT categoria_id, AVG(precio) AS avg_precio
    FROM producto
    WHERE eliminado = FALSE
    GROUP BY categoria_id
) sub ON sub.categoria_id = p.categoria_id
WHERE p.eliminado = FALSE
AND p.precio > sub.avg_precio

EXCEPT

-- Pierna derecha: Versión 1 (subconsulta correlacionada)
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    p.precio
FROM producto p
WHERE p.eliminado = FALSE
AND p.precio > (
    SELECT AVG(p2.precio)
    FROM producto p2
    WHERE p2.categoria_id = p.categoria_id
    AND p2.eliminado = FALSE
);