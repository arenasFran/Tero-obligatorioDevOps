-- Inicialización de las bases que RDS no crea.
--
-- RDS solo crea la base indicada en db_name (orders). Este script crea
-- catalogdb y cartdb, otorga permisos y crea la tabla que el servicio carts
-- espera encontrar.
--
-- Es idempotente: \gexec ejecuta CREATE DATABASE solo si la base no existe,
-- así que se puede correr varias veces sin fallar.

SELECT 'CREATE DATABASE catalogdb'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'catalogdb')\gexec

SELECT 'CREATE DATABASE cartdb'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cartdb')\gexec

GRANT ALL PRIVILEGES ON DATABASE catalogdb TO retail_user;
GRANT ALL PRIVILEGES ON DATABASE cartdb TO retail_user;
GRANT ALL PRIVILEGES ON DATABASE orders TO retail_user;

\c orders
GRANT ALL ON SCHEMA public TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retail_user;

\c catalogdb
GRANT ALL ON SCHEMA public TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retail_user;

\c cartdb
GRANT ALL ON SCHEMA public TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retail_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retail_user;

CREATE TABLE IF NOT EXISTS cart_items (
    customer_id VARCHAR(255) NOT NULL,
    item_id     VARCHAR(255) NOT NULL,
    quantity    INTEGER      NOT NULL,
    unit_price  INTEGER      NOT NULL,
    PRIMARY KEY (customer_id, item_id)
);
