-- ==================================================================--------------------
-- Archivo: Andrés_parte3a.sql (CORREGIDO)
-- Descripción: Consultas SQL sobre esquema Food Store que listan usuarios vigentes
-- con pedidos no eliminados, su total gastado y puesto en ranking usando DENSE_RANK().
-- Se aplica borrado lógico (eliminado = FALSE) en todas las tablas involucradas.
-- No se usa SELECT *.
-- ==================================================================--------------------

-- =======================================================================
-- a) ranking con función de ventana
-- =======================================================================

-- =======================================================================
-- VERSION 1: JOIN directo con DENSE_RANK() en la misma cláusula
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
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 1): Versión 1 EXCEPT Versión 2a
-- CORREGIDO: el CTE se repite completo dentro de esta misma sentencia,
-- porque un WITH no persiste entre sentencias separadas.
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
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido

EXCEPT

SELECT 
    nombre_completo,
    total_gastado,
    DENSE_RANK() OVER (ORDER BY total_gastado DESC, usuario_id ASC) AS puesto
FROM totales_usuarios;

-- =======================================================================
-- VERIFICACIÓN CON EXCEPT (sentido 2): Versión 2a EXCEPT Versión 1
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
FROM totales_usuarios

EXCEPT

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
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE

EXCEPT

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
SELECT 
    u.nombre || ' ' || u.apellido AS nombre_completo,
    SUM(p.total) AS total_gastado,
    DENSE_RANK() OVER (ORDER BY SUM(p.total) DESC, u.id ASC) AS puesto
FROM usuario u
INNER JOIN pedido p ON p.usuario_id = u.id AND p.eliminado = FALSE
WHERE u.eliminado = FALSE
GROUP BY u.id, u.nombre, u.apellido

EXCEPT

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
) sub ON sub.usuario_id = u.id
WHERE u.eliminado = FALSE;
