# Food Store — Convenciones de Base de Datos

## Nombres de tablas

Los nombres de tabla son **en singular y en español**:

```
categoria, producto, usuario, pedido, detalle_pedido
```

No usar plural (`productos`), no usar inglés (`product`), no usar PascalCase.

## Columna `eliminado` — Borrado lógico

**Nunca se ejecuta `DELETE`** sobre ninguna tabla del proyecto.

Todas las tablas tienen `eliminado BOOLEAN NOT NULL DEFAULT FALSE`.
La baja de un registro consiste siempre en:

```sql
UPDATE <tabla> SET eliminado = TRUE WHERE id = :id AND eliminado = FALSE;
```

Toda consulta de datos vigentes debe filtrar `WHERE eliminado = FALSE`.
Las vistas `v_categorias_vigentes`, `v_productos_vigentes`, `v_pedidos_resumen` y `v_pedido_detalle` ya aplican ese filtro; úsalas en lugar de escribir el filtro a mano cuando sea posible.

**En consultas con varios JOIN, el filtro debe aplicarse en CADA tabla involucrada**,
no solo en la principal. Omitirlo en una sola tabla del JOIN puede hacer que dos
consultas "parezcan" equivalentes sin serlo (por ejemplo, sumar pedidos de un usuario
ya eliminado, o incluir productos de una categoría dada de baja).

### Baja de un pedido completo

La baja de un pedido requiere una transacción explícita que marque primero los detalles y luego el pedido:

```sql
BEGIN;
    UPDATE detalle_pedido SET eliminado = TRUE WHERE pedido_id = :id;
    UPDATE pedido SET eliminado = TRUE WHERE id = :id;
COMMIT;
```

## Columna `precio_unitario` en `detalle_pedido`

Este campo **congela el precio** del producto en el momento de la venta.
No se actualiza si el precio del producto cambia después.
El trigger `trg_subtotal` lo copia de `producto.precio` si llega `NULL`.

## Columna `disponible` en `producto`

Controla si el producto puede ser pedido. El procedimiento `sp_crear_pedido` rechaza productos con `disponible = FALSE` aunque tengan stock.

## Restricciones de integridad destacadas

- `categoria.nombre` → `UNIQUE`
- `usuario.mail` → `UNIQUE`
- `detalle_pedido(pedido_id, producto_id)` → `UNIQUE` (un producto no puede repetirse en el mismo pedido)
- `producto.precio >= 0`, `producto.stock >= 0`, `detalle_pedido.cantidad > 0`
- `detalle_pedido.pedido_id` tiene `ON DELETE RESTRICT` (no se puede borrar un pedido con detalles via DELETE — lo cual es consistente con la política de borrado lógico)

## Tipos de datos a respetar

| Campo | Tipo |
|---|---|
| IDs | `BIGINT GENERATED ALWAYS AS IDENTITY` |
| Precios y totales | `NUMERIC(10,2)` / `NUMERIC(12,2)` |
| Fechas con zona | `TIMESTAMPTZ` (campo `created_at`) |
| Fecha del pedido | `DATE` (campo `fecha`) |
| Contraseña | `VARCHAR(255)` — almacenar solo hash, nunca texto plano |

## Índices existentes

### Del schema original (`schema.sql`)

```sql
idx_producto_categoria_id   -- producto.categoria_id
idx_pedido_usuario_id       -- pedido.usuario_id
idx_producto_nombre_vigente -- producto(nombre) WHERE eliminado = FALSE  (índice parcial)
```

### Agregados en la práctica anterior (`indices_semana3.sql`)

```sql
idx_pedido_fecha_estado_vigente
    -- pedido(fecha, estado) WHERE eliminado = FALSE
    -- Acelera filtros por rango de fechas + estado (Seq Scan -> Bitmap Heap Scan)

idx_pedido_usuario_total_estado
    -- pedido(usuario_id, total) WHERE eliminado = FALSE AND estado IN ('CONFIRMADO', 'TERMINADO')
    -- Habilita Index Only Scan para agregaciones de gasto por usuario
```

**No duplicar ninguno de estos índices** al proponer optimizaciones nuevas — antes
de sugerir un `CREATE INDEX`, verificar si alguno de los 5 ya cubre el caso.
