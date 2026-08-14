-- Todas las tablas y vistas con su cantidad de columnas (no tenia idea que se podia hacer esto XD)
SELECT 
	table_schema, 
	table_name, 
	table_type,
	(SELECT count(*) FROM information_schema.columns c
	WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS columnas
FROM information_schema.tables t
WHERE table_schema IN ('organizacion', 'catalogo', 'clientes', 'operaciones')
ORDER BY table_schema, table_type, table_name;

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
