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
	FROM catalogo.producto


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
	JOIN catalogo.producto p ON p.producto_id = v.producto_id
	
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


SELECT * FROM operaciones.vw_venta_cabecera;




