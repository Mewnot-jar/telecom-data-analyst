-- =====================================================================
--  Base de datos de practica  |  Retail Telecomunicaciones - Chile
--  Motor: PostgreSQL (Levantado en Supabase)
-- =====================================================================

DROP SCHEMA IF EXISTS organizacion CASCADE;
DROP SCHEMA IF EXISTS catalogo     CASCADE;
DROP SCHEMA IF EXISTS clientes     CASCADE;

CREATE SCHEMA organizacion;
CREATE SCHEMA catalogo;
CREATE SCHEMA clientes;

-- ORGANIZACION
CREATE TABLE organizacion.gerente_comercial (
    gerente_id        INTEGER PRIMARY KEY,
    nombre            VARCHAR(50)  NOT NULL,
    apellido_paterno  VARCHAR(50)  NOT NULL,
    apellido_materno  VARCHAR(50),
    genero            CHAR(1),
    email             VARCHAR(120),
    fecha_ingreso     DATE
);

CREATE TABLE organizacion.jefe_comercial (
    jefe_id           INTEGER PRIMARY KEY,
    nombre            VARCHAR(50)  NOT NULL,
    apellido_paterno  VARCHAR(50)  NOT NULL,
    apellido_materno  VARCHAR(50),
    genero            CHAR(1),
    email             VARCHAR(120),
    fecha_ingreso     DATE
);

CREATE TABLE organizacion.zona (
    zona_id      INTEGER PRIMARY KEY,
    nombre_zona  VARCHAR(20) NOT NULL UNIQUE,
    gerente_id   INTEGER NOT NULL REFERENCES organizacion.gerente_comercial(gerente_id)
);

CREATE TABLE organizacion.region (
    region_id     INTEGER PRIMARY KEY,
    nombre_region VARCHAR(60) NOT NULL,
    zona_id       INTEGER NOT NULL REFERENCES organizacion.zona(zona_id),
    jefe_id       INTEGER NOT NULL REFERENCES organizacion.jefe_comercial(jefe_id)
);

CREATE TABLE organizacion.comuna (
    comuna_id     INTEGER PRIMARY KEY,
    nombre_comuna VARCHAR(60) NOT NULL,
    region_id     INTEGER NOT NULL REFERENCES organizacion.region(region_id)
);

CREATE TABLE organizacion.sucursal (
    sucursal_id     INTEGER PRIMARY KEY,
    nombre_sucursal VARCHAR(80) NOT NULL,
    comuna_id       INTEGER NOT NULL REFERENCES organizacion.comuna(comuna_id),
    tipo_sucursal   VARCHAR(15) CHECK (tipo_sucursal IN ('Mall','Calle','Stand')),
    direccion       VARCHAR(120),
    fecha_apertura  DATE,
    activa          BOOLEAN DEFAULT TRUE
);

CREATE TABLE organizacion.ejecutivo (
    ejecutivo_id      INTEGER PRIMARY KEY,
    nombre            VARCHAR(50) NOT NULL,
    apellido_paterno  VARCHAR(50) NOT NULL,
    apellido_materno  VARCHAR(50),
    genero            CHAR(1),
    sucursal_id       INTEGER NOT NULL REFERENCES organizacion.sucursal(sucursal_id),
    email             VARCHAR(120),
    fecha_ingreso     DATE,
    fecha_salida      DATE,
    activo            BOOLEAN DEFAULT TRUE
);

-- CATALOGO
CREATE TABLE catalogo.producto (
    producto_id     INTEGER PRIMARY KEY,
    categoria       VARCHAR(20) NOT NULL
                    CHECK (categoria IN ('Plan','Equipo','Seguro','Accesorio')),
    nombre_producto VARCHAR(80) NOT NULL,
    marca           VARCHAR(40),
    gama            VARCHAR(10),   -- solo Equipo y Seguro
    plan_tier       SMALLINT,      -- solo Plan (1 = mas economico, 3 = premium)
    plan_datos      VARCHAR(20),   -- solo Plan
    tipo_seguro     VARCHAR(20),   -- solo Seguro
    precio_lista    INTEGER NOT NULL,
    costo           INTEGER
);

CREATE TABLE catalogo.regla_comision (
    regla_id    INTEGER PRIMARY KEY,
    categoria   VARCHAR(20) NOT NULL,
    plan_tier   SMALLINT,
    tipo_venta  VARCHAR(20),
    monto_fijo  INTEGER      DEFAULT 0,
    porcentaje  NUMERIC(5,4) DEFAULT 0
);

-- CLIENTES
CREATE TABLE clientes.cliente (
    cliente_id       INTEGER PRIMARY KEY,
    rut              VARCHAR(12) NOT NULL,
    nombre           VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(50),
    apellido_materno VARCHAR(50),
    genero           CHAR(1),
    segmento         VARCHAR(15) CHECK (segmento IN ('Persona','Empresa')),
    fecha_nacimiento DATE,
    comuna_id        INTEGER REFERENCES organizacion.comuna(comuna_id),
    email            VARCHAR(120),
    telefono         VARCHAR(20)
);

-- INDICES
CREATE INDEX idx_region_zona     ON organizacion.region(zona_id);
CREATE INDEX idx_comuna_region   ON organizacion.comuna(region_id);
CREATE INDEX idx_sucursal_comuna ON organizacion.sucursal(comuna_id);
CREATE INDEX idx_ejec_sucursal   ON organizacion.ejecutivo(sucursal_id);
CREATE INDEX idx_cliente_comuna  ON clientes.cliente(comuna_id);
CREATE INDEX idx_producto_cat    ON catalogo.producto(categoria);

CREATE TABLE operaciones.meta_ejecutivo (
    meta_id      INTEGER PRIMARY KEY,
    ejecutivo_id INTEGER  NOT NULL REFERENCES organizacion.ejecutivo(ejecutivo_id),
    anio         SMALLINT NOT NULL,
    mes          SMALLINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    meta_planes  SMALLINT NOT NULL,
    meta_monto   BIGINT   NOT NULL,
    UNIQUE (ejecutivo_id, anio, mes)
);

CREATE TABLE operaciones.encuesta_nps (
    encuesta_id    INTEGER PRIMARY KEY,
    venta_id       INTEGER NOT NULL,
    fecha_encuesta DATE    NOT NULL,
    canal          VARCHAR(20) NOT NULL,
    puntaje        SMALLINT NOT NULL CHECK (puntaje BETWEEN 0 AND 10),
    comentario     TEXT
);

CREATE TABLE operaciones.baja_plan (
    baja_id          INTEGER PRIMARY KEY,
    venta_id         INTEGER NOT NULL,
    linea_id         INTEGER NOT NULL UNIQUE
                     REFERENCES operaciones.venta_detalle(linea_id),
    producto_id      INTEGER NOT NULL REFERENCES catalogo.producto(producto_id),
    fecha_baja       DATE    NOT NULL,
    dias_permanencia SMALLINT NOT NULL,
    motivo_baja      VARCHAR(40) NOT NULL
);
