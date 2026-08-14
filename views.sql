CREATE OR REPLACE VIEW organizacion.vw_sucursales AS
	SELECT 
		s.sucursal_id,
		s.nombre_sucursal,
		s.tipo_sucursal,
		s.direccion,
		s.fecha_apertura,
		s.activa,
		c.comuna_id,
		c.nombre_comuna AS comuna,
		r.region_id,
		r.nombre_region AS region,
		z.zona_id,
		z.nombre_zona AS zona,
		jc.nombre AS jefe_nombre,
		jc.apellido_paterno AS jefe_apellido,
		jc.nombre || ' ' || jc.apellido_paterno AS jefe_comercial,
		gc.nombre AS gerente_nombre,
		gc.apellido_paterno AS gerente_apellido,
		gc.nombre || ' ' || gc.apellido_paterno AS gerente_comercial
	FROM organizacion.sucursal s
	JOIN organizacion.comuna c ON c.comuna_id = s.comuna_id
	JOIN organizacion.region r ON r.region_id = c.region_id
	JOIN organizacion.zona z ON z.zona_id = r.zona_id
	JOIN organizacion.jefe_comercial jc ON jc.jefe_id = r.jefe_id
	JOIN organizacion.gerente_comercial gc ON gc.gerente_id = z.gerente_id;

CREATE OR REPLACE VIEW organizacion.vw_ejecutivo AS
	SELECT 
		e.ejecutivo_id,
		e.nombre AS ejecutivo_nombre,
		e.apellido_paterno AS ejecutivo_apellido,
		e.nombre || ' ' || e.apellido_paterno AS ejecutivo,
		e.fecha_ingreso,
		e.fecha_salida,
		e.activo,
		e.sucursal_id,
		s.nombre_sucursal,
	    s.tipo_sucursal,
	    s.comuna,
	    s.region,
	    s.zona,
	    s.jefe_comercial,
	    s.gerente_comercial
	FROM organizacion.ejecutivo e
	JOIN organizacion.vw_sucursales s ON s.sucursal_id = e.sucursal_id;

CREATE OR REPLACE VIEW catalogo.vw_productos AS
	SELECT
		producto_id,
		categoria,
		nombre_producto,
		plan_tier,
		plan_datos,
		marca,
		gama,
		tipo_seguro,
		precio_lista,
		costo,
		ROUND((precio_lista - costo)::NUMERIC / precio_lista, 4) AS margen_porcentual
	FROM catalogo.producto;


CREATE OR REPLACE VIEW operaciones.vw_ventas AS
	SELECT
		v.venta_id,
		v.linea_id,
		v.fecha_venta,
		v.sucursal_id,
		v.ejecutivo_id,
		v.cliente_id,
		v.tipo_venta,
		v.categoria_producto,
		v.producto_id,
		v.cantidad,
		v.precio_unitario,
		v.descuento,
		v.cantidad * v.precio_unitario AS monto_bruto,
		v.cantidad * v.precio_unitario - v.descuento AS monto_neto,
		v.cantidad * p.costo AS costo_total,
		((v.cantidad * v.precio_unitario - v.descuento) - (v.cantidad * p.costo)) AS margen
	FROM operaciones.venta_detalle v
	JOIN catalogo.producto p ON p.producto_id = v.producto_id;
	
--La que mas me costo, por eso lleva tanto comentario xdddd
CREATE OR REPLACE VIEW operaciones.vw_venta_cabecera AS
	SELECT
	    v.venta_id,
	    v.fecha_venta,
	    v.sucursal_id,
	    v.ejecutivo_id,
	    v.cliente_id,
	    v.tipo_venta,
	    -- El tier del plan
	    MAX(p.plan_tier) FILTER (WHERE v.categoria_producto = 'Plan') AS plan_tier,
	    -- Que llevo esta venta
	    BOOL_OR(v.categoria_producto = 'Equipo') AS lleva_equipo,
	    BOOL_OR(v.categoria_producto = 'Seguro') AS lleva_seguro,
	    BOOL_OR(v.categoria_producto = 'Accesorio') AS lleva_accesorio,
	    -- Cuantas lineas llevo
	    COUNT(*) AS n_lineas,
	    -- Cuantos accesorios llevo
	    COUNT(*) FILTER (WHERE v.categoria_producto = 'Accesorio') AS n_accesorios,
	    -- Monto desglosado por categoria
	    COALESCE(SUM(v.monto_neto) FILTER (WHERE v.categoria_producto = 'Plan'), 0) AS monto_plan,
	    COALESCE(SUM(v.monto_neto) FILTER (WHERE v.categoria_producto = 'Equipo'), 0) AS monto_equipo,
	    COALESCE(SUM(v.monto_neto) FILTER (WHERE v.categoria_producto = 'Seguro'), 0) AS monto_seguro,
	    COALESCE(SUM(v.monto_neto) FILTER (WHERE v.categoria_producto = 'Accesorio'), 0) AS monto_accesorio,
	    -- Totales de la venta
	    SUM(v.monto_bruto)  AS monto_bruto,
	    SUM(v.monto_neto)   AS monto_neto,
	    SUM(v.costo_total)  AS costo_total,
	    SUM(v.margen)       AS margen
	FROM operaciones.vw_ventas v
	JOIN catalogo.producto p ON p.producto_id = v.producto_id
	GROUP BY
	    v.venta_id,
	    v.fecha_venta,
	    v.sucursal_id,
	    v.ejecutivo_id,
	    v.cliente_id,
	    v.tipo_venta;
-- Vista que trae a todos los clientes junto a su rango etario y comuna, regio y zona
-- Utilzia un CTE que trae todas las columnas del cliente
-- Ademas calcula la edad del cliente para luego utilizarse en la siguiente consulta

CREATE OR REPLACE VIEW clientes.vw_clientes AS
WITH base AS(
	SELECT 
		cl.*,
		EXTRACT(YEAR FROM age(cl.fecha_nacimiento))::INT AS edad
	FROM clientes.cliente cl
)
SELECT 
	b.cliente_id,
	b.nombre,
	b.apellido_paterno,
	b.apellido_materno,
	CONCAT_WS(' ', b.nombre, b.apellido_paterno, b.apellido_materno) AS cliente,
	b.segmento,
	b.genero,
	b.fecha_nacimiento,
	b.edad,
	CASE
		WHEN b.edad IS NULL THEN 'Sin datos'
		WHEN b.edad < 25 THEN '18 - 24'
		WHEN b.edad < 35 THEN '25 - 34'
		WHEN b.edad < 45 THEN '35 - 44'
		WHEN b.edad < 60 THEN '45 - 59'
		WHEN b.edad < 65 THEN '60 - 64'
		ELSE '65+'
	END AS tramo_etario,
	CASE
		WHEN b.edad IS NULL THEN 0
		WHEN b.edad < 25 THEN 1
		WHEN b.edad < 35 THEN 2
		WHEN b.edad < 45 THEN 3
		WHEN b.edad < 60 THEN 4
		WHEN b.edad < 65 THEN 5
	END AS tramo_orden,
	c.comuna_id,
	c.nombre_comuna AS comuna_cliente,
	r.region_id,
	r.nombre_region AS region_cliente,
	z.zona_id,
	z.nombre_zona AS zona_cliente
FROM base b
JOIN organizacion.comuna c ON c.comuna_id = b.comuna_id
JOIN organizacion.region r ON r.region_id = c.region_id
JOIN organizacion.zona z ON z.zona_id = r.zona_id;

-- Vista que trae las metas de cada ejecutivo junto con los datos del ejecutivo

CREATE OR REPLACE VIEW operaciones.vw_metas AS 
SELECT 
	m.meta_id,
	m.ejecutivo_id,
	m.anio,
	m.mes,
	MAKE_DATE(m.anio, m.mes, 1) AS fecha_meta,
	m.meta_planes,
	m.meta_monto,
	e.ejecutivo,
	e.activo,
	e.sucursal_id,
	e.nombre_sucursal,
	e.tipo_sucursal,
	e.comuna,
	e.region,
	e.zona,
	e.jefe_comercial,
	e.gerente_comercial
FROM operaciones.meta_ejecutivo m
JOIN organizacion.vw_ejecutivo e ON e.ejecutivo_id = m.ejecutivo_id;

-- Vista que trae las bajas registradas junto con los datos de venta y sucursales

CREATE OR REPLACE VIEW operaciones.vw_bajas AS
SELECT 
	b.baja_id,
	b.venta_id,
	b.linea_id,
	b.fecha_baja,
	b.dias_permanencia,
	b.motivo_baja,
	CASE
		WHEN b.dias_permanencia < 30 THEN '1. Menos de 30 dias'
		WHEN b.dias_permanencia < 60 THEN '2. 30 a 59 dias'
		WHEN b.dias_permanencia < 90 THEN '3. 60 a 89 dias'
		WHEN b.dias_permanencia < 100 THEN '4. 90 a 179 dias'
		ELSE '5. 180 dias o mas'
	END AS tramo_permanencia,
	v.fecha_venta,
	v.tipo_venta,
	v.sucursal_id,
	v.ejecutivo_id,
	v.cliente_id,
	v.monto_neto AS monto_plan,
	p.nombre_producto AS plan,
	p.plan_tier,
	s.nombre_sucursal,
	s.tipo_sucursal,
	s.comuna,
	s.region,
	s.zona,
	s.jefe_comercial,
	s.gerente_comercial
FROM operaciones.baja_plan b
JOIN operaciones.vw_ventas v ON v.linea_id = b.linea_id
JOIN catalogo.producto p ON p.producto_id = b.producto_id
JOIN organizacion.vw_sucursales s ON s.sucursal_id = v.sucursal_id;

-- Trae la encuesta de satisfaccion en el contexto de la venta.
-- Trae una fila por cada encuesta y se une con vw_venta_cabecera (una fila por venta)
-- y no a vw_ventas (una fila por linea) ya que sino cada encuesta se duplicaria por cada linea de su venta

CREATE OR REPLACE VIEW operaciones.vw_nps AS
SELECT 
	n.encuesta_id,
	n.venta_id,
	n.fecha_encuesta,
	n.canal,
	n.puntaje,
	n.comentario,
	(n.comentario IS NOT NULL) AS tiene_comentario,
	-- Clasificacion estandar del NPS (promotor, pasivo, detractor)
	CASE
		WHEN n.puntaje >= 9 THEN 'Promotor'
		WHEN n.puntaje >= 7 THEN 'Pasivo'
		ELSE 'Detractor'
	END AS grupo_nps,
	-- Con valor_nps podremos ver el % de promotores, pasivos y detractores mas facilmente con dax
	-- NPS = AVERAGE(vw_nps[valor_nps]) * 100
	CASE
		WHEN n.puntaje >= 9 THEN 1
		WHEN n.puntaje >= 7 THEN 0
		ELSE -1
	END AS valor_nps,
	-- Contexto de la venta
	c.fecha_venta,
	c.tipo_venta,
	c.plan_tier,
	c.lleva_equipo,
	c.lleva_seguro,
	c.monto_neto AS monto_venta,
	c.sucursal_id,
	c.ejecutivo_id,
	c.cliente_id,
	-- Datos de la zona
	s.nombre_sucursal,
	s.tipo_sucursal,
	s.comuna,
	s.region,
	s.zona,
	s.jefe_comercial,
	s.gerente_comercial
FROM operaciones.encuesta_nps n
JOIN operaciones.vw_venta_cabecera c ON c.venta_id = n.venta_id
JOIN organizacion.vw_sucursales s ON s.sucursal_id = c.sucursal_id;
	
	
	
	
	
	
	







