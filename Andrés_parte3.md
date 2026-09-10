# Prompt 1: Construcción de la Consulta (a) — Ranking con Función de Ventana

Hola Nemotron, Genera una consulta SQL sobre el esquema de Food Store que devuelva, para cada usuario vigente (eliminado = FALSE) con al menos un pedido no eliminado (eliminado = FALSE), su nombre completo, el total gastado (suma de pedido.total) y su puesto en un ranking de mayor a menor gasto.

Usa una función de ventana (DENSE_RANK() o RANK()).

Si hay empate en el gasto total, desempata por el id del usuario en forma ascendente.


Aplica borrado lógico en todas las tablas involucradas.


No uses SELECT *.
Genera además una versión 2 alternativa utilizando una estructura distinta (por ejemplo, calculando el total gastado previamente en una CTE o Subconsulta antes de aplicar la función de ventana) y la consulta de verificación con EXCEPT en ambos sentidos.

---

# Prompt 2: Construcción de la Consulta (b) — Subconsulta Correlacionada

Hola Nemotron, Genera una consulta SQL sobre Food Store que devuelva todos los productos vigentes (eliminado = FALSE) cuyo precio sea mayor al precio promedio de los productos pertenecientes a su misma categoría.

La primera versión debe resolverse usando una subconsulta correlacionada en la cláusula WHERE.


La segunda versión debe resolverse usando un JOIN con una subconsulta agrupada por categoría.


Muestra id, nombre, categoria_id y precio.


Aplica filtro de borrado lógico en las consultas principales y subconsultas.


Incluye la verificación con EXCEPT.