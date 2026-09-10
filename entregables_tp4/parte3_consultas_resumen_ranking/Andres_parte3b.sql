-- ==================================================================--------------------
-- Archivo: Andrés_parte3b.sql (CORREGIDO)
-- Descripción: Consultas SQL sobre esquema Food Store que listan productos vigentes
-- cuyo precio es mayor al precio promedio de productos de su misma categoría.
-- Se aplica borrado lógico (eliminado = FALSE) en todas las tablas involucradas.
-- Se entregan dos versiones: subconsulta correlacionada y JOIN con subquery agrupada.
-- Incluye verificación EXCEPT.
-- =======================================================================

-- =======================================================================
-- b) consulta con subconsulta correlacionada
-- =======================================================================

-- =======================================================================
-- VERSION 1: Subconsulta correlacionada en la cláusula WHERE
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
