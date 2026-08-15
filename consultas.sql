-- Todas las tablas y vistas con su cantidad de columnas (no tenia idea que se podia hacer esto XD)
-- BLOQUE 1: Inventario del modelo
-- Que tablas y vistas existen, con su cantidad de columnas.
SELECT 
	table_schema, 
	table_name, 
	table_type,
	(SELECT count(*) FROM information_schema.columns c
	WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS columnas
FROM information_schema.tables t
WHERE table_schema IN ('organizacion', 'catalogo', 'clientes', 'operaciones')
ORDER BY table_schema, table_type, table_name;

-- BLOQUE 2: contenido de cada tabla

-- Todos los productos
SELECT * FROM catalogo.producto p
ORDER BY p.producto_id;

-- Cuanto se le paga a cada ejecutivo segun lo que venda
SELECT * FROM catalogo.regla_comision r
ORDER BY r.regla_id;

-- Todos los clientes (limite de 20)
SELECT * FROM clientes.cliente c
ORDER BY c.cliente_id
LIMIT 20;

-- Todas las bajas de planes (limite de 20)
SELECT * FROM operaciones.baja_plan b
ORDER BY b.baja_id
LIMIT 20;

-- Todas las encuestas de nps (limite de 20)
SELECT * FROM operaciones.encuesta_nps e
ORDER BY e.encuesta_id
LIMIT 20;

-- Lo que se espera que venda cada ejecutivo en cada mes (limite de 20)
SELECT * FROM operaciones.meta_ejecutivo m
ORDER BY m.meta_id
LIMIT 20;

-- Todas las ventas (limite de 20)
SELECT * FROM operaciones.venta_detalle v
ORDER BY v.venta_id
LIMIT 20;

-- Todas las comunas
SELECT * FROM organizacion.comuna c
ORDER BY c.comuna_id;

-- Todas las regiones
SELECT * FROM organizacion.region r
ORDER BY r.region_id;

-- Todas las zonas
SELECT * FROM organizacion.zona z
ORDER BY z.zona_id;

-- Todos los jefes comerciales
SELECT * FROM organizacion.jefe_comercial jc
ORDER BY jc.jefe_id;

-- Todos los gerentes comerciales
SELECT * FROM organizacion.gerente_comercial gc
ORDER BY gc.gerente_id;

-- Todos los ejecutivos (limite de 20)
SELECT * FROM organizacion.ejecutivo e
ORDER BY e.ejecutivo_id
LIMIT 20;

-- BLOQUE 3: Verificacion de relaciones
-- Cantidad de ventas, monto neto, sucursales, ejecutivos por cada zona
SELECT 
	z.nombre_zona,
	count(DISTINCT s.sucursal_id) AS cantidad_sucursales,
	count(DISTINCT e.ejecutivo_id) AS  cantidad_ejecutivos,
	count(DISTINCT v.venta_id) AS cantidad_ventas,
	sum(v.cantidad * v.precio_unitario - v.descuento) AS monto_total
FROM organizacion.sucursal s
JOIN organizacion.comuna c ON c.comuna_id = s.comuna_id
JOIN organizacion.region r ON r.region_id = c.region_id
JOIN organizacion.zona z ON z.zona_id = r.zona_id
JOIN organizacion.ejecutivo e ON e.sucursal_id = s.sucursal_id
JOIN operaciones.venta_detalle v ON v.ejecutivo_id = e.ejecutivo_id
GROUP BY z.nombre_zona;

-- Cantidad de ventas, lineas, monto_neto y promedio de compras por venta ordenado por cada mes
SELECT 
	DATE_TRUNC('month', v.fecha_venta)::DATE AS mes,
	count(*) AS lineas,
	count(DISTINCT v.venta_id) AS ventas,
	sum(v.monto_neto) AS monto_neto,
	round(sum(v.monto_neto)::NUMERIC / COUNT(DISTINCT v.venta_id), 0) AS ticket_promedio
FROM operaciones.vw_ventas v
GROUP BY DATE_TRUNC('month', v.fecha_venta)
ORDER BY mes;

-- Dos tipos de TOP El ranking cambia por completo al cambiar el ORDER BY
-- Los planes lideran en unidades y los equipos gama alta lideran en facturacion
-- Top 10 productos vendidos por cantidad
SELECT 
	p.nombre_producto AS producto,
	p.categoria,
	sum(v.cantidad) AS unidades,
	sum(v.monto_neto) AS monto
FROM operaciones.vw_ventas v
JOIN catalogo.vw_productos p ON p.producto_id = v.producto_id
GROUP BY p.nombre_producto, p.categoria
ORDER BY unidades DESC
LIMIT 10;
-- Top 10 productos vendidos por monto
SELECT 
	p.nombre_producto AS producto,
	p.categoria,
	sum(v.cantidad) AS unidades,
	sum(v.monto_neto) AS monto
FROM operaciones.vw_ventas v
JOIN catalogo.vw_productos p ON p.producto_id = v.producto_id
GROUP BY p.nombre_producto, p.categoria
ORDER BY monto DESC
LIMIT 10;
-
-- Trae la cantidad de clientes que pertenece a cada rango etario
SELECT
	cl.tramo_orden,
	cl.tramo_etario,
	count(*) AS clientes,
	round(count(*) * 100.0 / sum(count(*)) OVER (), 1) AS porcentaje
FROM clientes.vw_clientes cl
GROUP BY cl.tramo_etario, cl.tramo_orden
ORDER BY cl.tramo_orden ASC;

-- Cantidad de ventas por tipo de sucursal y su porcentaje de equipo, seguro, accesorio
-- Que porcentaje de la venta llevo equipo, seguro o accesorio
-- Como las banderas son booleanas, al convertirse en entero quedan True=1 False=0,
-- el promedio de la columna es la proporcion
SELECT 
	s.tipo_sucursal,
	count(*) AS ventas,
	round(avg(v.lleva_equipo::INT) * 100, 1) AS pct_equipo,
	round(avg(v.lleva_seguro::INT) * 100, 1) AS pct_seguro,
	round(avg(v.lleva_accesorio::INT) * 100, 1) AS pct_accesorio
FROM operaciones.vw_venta_cabecera v
JOIN organizacion.vw_sucursales s ON s.sucursal_id = v.sucursal_id
GROUP BY s.tipo_sucursal;

--Consulta que trae lo vendido vs lo esperado de planes, y monto por cada zona.
WITH se_vendio AS (
	SELECT 
		s.zona,
		count(*) FILTER (WHERE v.categoria_producto = 'Plan') AS cantidad_planes,
		sum(v.monto_neto) AS monto_real
	FROM operaciones.vw_ventas v
	JOIN organizacion.vw_sucursales s ON s.sucursal_id = v.sucursal_id
	GROUP BY s.zona
),
meta AS(
	SELECT 
		zona,
		sum(meta_planes) AS meta_planes,
		sum(meta_monto) AS meta_monto
	FROM operaciones.vw_metas
	GROUP BY zona
)

SELECT 
	m.zona,
	se.cantidad_planes,
	m.meta_planes,
	ROUND(se.cantidad_planes * 100.0 / m.meta_planes, 1) AS pct_cumplimiento_planes,
	se.monto_real,
	m.meta_monto,
	ROUND(se.monto_real * 100.0 / m.meta_monto, 1) AS pct_cumplimiento_monto
FROM se_vendio se
JOIN meta m ON m.zona = se.zona
ORDER BY pct_cumplimiento_planes DESC; 

-- Consulta de analisis de churn
SELECT 
	b.motivo_baja,
	count(*) AS cantidad_bajas,
	round(avg(b.dias_permanencia), 1) AS promedio_dias_permanencia,
	round(count(*) * 100.0 / sum(count(*)) OVER (), 1) AS pct_del_total
FROM operaciones.vw_bajas b
GROUP BY b.motivo_baja
ORDER BY cantidad_bajas DESC;

WITH vendidos AS (
	SELECT
		p.plan_tier,
		count(*) AS cantidad_planes_vendidos
	FROM operaciones.vw_ventas v
	JOIN catalogo.producto p ON p.producto_id = v.producto_id
	WHERE v.categoria_producto = 'Plan'
	GROUP BY p.plan_tier
),
bajas AS (
	SELECT 
		b.plan_tier,
		count(*) AS cantidad_planes_baja,
		round(avg(b.dias_permanencia), 1) AS permanencia_promedio
	FROM operaciones.vw_bajas b
	GROUP BY b.plan_tier
)
SELECT 
	v.plan_tier,
	v.cantidad_planes_vendidos,
	b.cantidad_planes_baja,
	b.permanencia_promedio,
	round(b.cantidad_planes_baja * 100.0 / v.cantidad_planes_vendidos, 1) AS pct_tasa_baja
FROM vendidos v
JOIN bajas b ON b.plan_tier = v.plan_tier
ORDER BY v.plan_tier ASC;