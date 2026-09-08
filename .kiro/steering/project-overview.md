# Food Store — Visión General del Proyecto

## Descripción

Sistema de venta de comida implementado íntegramente en **PostgreSQL**.
Cubre el ciclo completo: categorías → productos → usuarios → pedidos con sus detalles.

## Archivos del proyecto

| Archivo | Contenido |
|---|---|
| `schema.sql` | Tipos ENUM, tablas, constraints e índices |
| `objects.sql` | Vistas, función de cálculo, triggers y procedimiento `sp_crear_pedido` |
| `data.sql` | Datos de prueba chicos (categorías, productos, usuarios, pedidos de ejemplo) |
| `queries.sql` | Historias de usuario resueltas + consultas analíticas (banco de consultas candidatas para el laboratorio) |
| `transacciones.sql` | Escenarios de atomicidad, aislamiento y bloqueo concurrente (de una entrega anterior, no se usa en este TP) |
| `carga_masiva.sql` | Script de población masiva: ≥50.000 productos, ≥20.000 usuarios, ≥200.000 pedidos con detalles. Se aplica una sola vez sobre `copia_trabajo`, nunca sobre `plantilla_food_store` |
| `indices_semana3.sql` | Recrea los índices ya aceptados y medidos en la práctica anterior (`idx_pedido_fecha_estado_vigente`, `idx_pedido_usuario_total_estado`). Corre después de `carga_masiva.sql` |

## Tablas del modelo

```
categoria
producto       → FK categoria_id → categoria
usuario
pedido         → FK usuario_id   → usuario
detalle_pedido → FK pedido_id    → pedido
               → FK producto_id  → producto
```

## Tipos ENUM definidos

```sql
CREATE TYPE rol          AS ENUM ('ADMIN','USUARIO');
CREATE TYPE estado_pedido AS ENUM ('PENDIENTE','CONFIRMADO','TERMINADO','CANCELADO');
CREATE TYPE forma_pago   AS ENUM ('TARJETA','TRANSFERENCIA','EFECTIVO');
```

## Orden de ejecución

```
schema.sql → objects.sql → data.sql → carga_masiva.sql → indices_semana3.sql
```

Cada archivo depende del anterior; ejecutarlos fuera de orden producirá errores de
referencia. `queries.sql` no se ejecuta de una sola vez: es un banco de consultas
sueltas del que se eligen candidatas para el laboratorio de optimización.

**Importante:** correr `indices_semana3.sql` es obligatorio antes de medir cualquier
plan en la práctica actual — sin él, los planes "antes" no reflejan el estado que la
consigna da por sentado.

## Vistas disponibles

| Vista | Descripción |
|---|---|
| `v_categorias_vigentes` | Categorías con `eliminado = FALSE` |
| `v_productos_vigentes` | Productos y categorías activos, con JOIN entre ambas tablas |
| `v_pedidos_resumen` | Pedidos vigentes con nombre completo del usuario |
| `v_pedido_detalle` | Líneas de detalle vigentes con nombre del producto |
