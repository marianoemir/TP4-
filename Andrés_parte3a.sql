-- ==================================================================--------------------
-- Archivo: Andrés_parte3.sql
-- Descripción: Consultas SQL sobre esquema Food Store que listan usuarios vigentes
-- con pedidos no eliminados, su total gastado y puesto en ranking usando DENSE_RANK().
-- Se aplica borrado lógico (eliminado = FALSE) en todas las tablas involucradas.
-- No se usa SELECT *.
-- ==================================================================--------------------

-- =======================================================================
a) ranking con función de ventana
-- =======================================================================


-- =======================================================================
-- VERSION 1: JOIN directo con DENSE_RANK() en la misma cláusula
-- =======================================================================
-- Este es el enfoque más directo: unen usuario y pedido, agrupan por usuario
-- y aplican la función de ventana DENSE_RANK() sobre el SUM(p.total).
-- El desempate es ASC por u.id cuando hay empate en el gasto total.
--
-- Columnas seleccionadas explícitas (sin SELECT *):
--   - u.nombre || ' ' || u.apellido : nombre completo del usuario
--   - SUM(p.total) : suma total gastado en todos sus pedidos
--   - DENSE_RANK() OVER (...) : puesto en ranking (1, 2, 2, 3... sin gaps)
-- Filtrar: usuario eliminado = FALSE Y pedido eliminado = FALSE
-- =======================================================================
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido;

-- =======================================================================
-- VERSION 2a: CTE (Common Table Expression) con total precalculado
-- =======================================================================
-- Se usa un bloque WITH para calcular primero el total_gastado por usuario,
-- y luego en el SELECT principal se aplica DENSE_RANK() sobre ese total precalculado.
-- Esto puede facilitar que el optimizador distinga las fases de agregación
-- y clasificación.
--
-- Estructura:
--   1. totales_usuarios CTE: agrupa y suma total por usuario
--   2. SELECT principal: aplica DENSE_RANK() sobre los totales del CTE
-- =======================================================================
WITH totales_usuarios AS (
    SELECT 
        u.id AS usuario_id,
        u.nombre || ' ' || u.apellido AS nombre_completo,
        SUM(p.total) AS total_gastado
    FROM usuario u
    INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
    WHERE u.eliminado = FALSE
    GROUP BY u.id, u.nombre, u.apellido
)
SELECT 
    nombre_completo,
    total_gastado,
    DENSE_RANK() OVER (ORDER BY total_gastado DESC, usuario_id ASC) AS puesto
FROM totales_usuarios;

-- =======================================================================
-- VERSION 2b: Subconsulta (subquery) con total precalculado
-- =======================================================================
-- Similar a la Versión 2a, pero en lugar de un CTE se usa una subconsulta
-- en el FROM clause. La subconsulta calcula SUM(p.total) por usuario_id,
-- con un HAVING COUNT(p.id) >= 1 para asegurar al menos un pedido no eliminado.
-- Luego el outer query hace JOIN con usuario y aplica la ventana.
--
-- Este patrón es útil cuando se quiere materializar la agregación antes
-- del JOIN, o cuando el optimizador maneja mejor subqueries en FROM.
-- =======================================================================
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    sub.total_gastado,
    DENSE_RANK() OVER (ORDER BY sub.total_gastado DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN (
    SELECT p.usuario_id, SUM(p.total) AS total_gastado
    FROM pedido p
    WHERE p.eliminado = FALSE
    GROUP BY p.usuario_id
    HAVING COUNT(p.id) >= 1
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 1): Versión 1 EXCEPT Versión 2a
-- =======================================================================
-- Esta consulta devuelve todas las filas de la Versión 1 que NO aparecen
-- en la Versión 2a. Si devuelve cero filas, ambas consultas son equivalentes
-- en cuanto a los resultados (mismo conjunto de filas con mismo orden/puesto).
--
-- Se aplica borrado lógico en ambas piernas (eliminado = FALSE en usuario y pedido).
-- =======================================================================
-- Pierna izquierda: Versión 1
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido

-- Pierna derecha: Versión 2a
EXCEPT

SELECT 
    nombre_completo,
    total_gastado,
    puesto
FROM totales_usuarios;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 2): Versión 2a EXCEPT Versión 1
-- =======================================================================
-- Devuelve filas de la Versión 2a que NO están en la Versión 1.
-- Si ambas son equivalentes, esta pierna también devuelve cero filas.
-- =======================================================================
-- Pierna izquierda: Versión 2a
SELECT 
    nombre_completo,
    total_gastado,
    puesto
FROM totales_usuarios

EXCEPT

-- Pierna derecha: Versión 1
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 1): Versión 2b EXCEPT Versión 1
-- =======================================================================
-- Compara la Versión 2b (subquery en FROM) contra la Versión 1 (JOIN directo).
-- =======================================================================
-- Pierna izquierda: Versión 2b
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    sub.total_gastado,
    DENSE_RANK() OVER (ORDER BY sub.total_gastado DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN (
    SELECT p.usuario_id, SUM(p.total) AS total_gastado
    FROM pedido p
    WHERE p.eliminado = FALSE
    GROUP BY p.usuario_id
    HAVING COUNT(p.id) >= 1
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE

EXCEPT

-- Pierna derecha: Versión 1
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 2): Versión 1 EXCEPT Versión 2b
-- =======================================================================
-- Compara la Versión 1 contra la Versión 2b.
-- =======================================================================
-- Pierna izquierda: Versión 1
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido

EXCEPT

-- Pierna derecha: Versión 2b
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    sub.total_gastado,
    DENSE_RANK() OVER (ORDER BY sub.total_gastado DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN (
    SELECT p.usuario_id, SUM(p.total) AS total_gastado
    FROM pedido p
    WHERE p.eliminado = FALSE
    GROUP BY p.usuario_id
    HAVING COUNT(p.id) >= 1
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE;

