-- LAB-02 | Actividad 1: Protección de credenciales
-- Datos ficticios únicamente.
-- Actividad 1: Demostracion de una practica insegura

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS usuarios_insegura (
    id       BIGSERIAL PRIMARY KEY,
    usuario  VARCHAR(50)  NOT NULL,
    password VARCHAR(100) NOT NULL
);

INSERT INTO usuarios_insegura (usuario, password)
VALUES ('juan', 'Password123');

SELECT * FROM usuarios_insegura;

-- 2. Generación de hashes: misma contraseña, dos sales distintas
SELECT
    crypt('Password123', gen_salt('bf')) AS hash_1,
    crypt('Password123', gen_salt('bf')) AS hash_2;

-- 3. Credenciales protegidas con bcrypt
CREATE TABLE IF NOT EXISTS usuarios_segura (
    id            BIGSERIAL PRIMARY KEY,
    usuario       VARCHAR(50) NOT NULL,
    password_hash TEXT        NOT NULL
);

INSERT INTO usuarios_segura (usuario, password_hash)
VALUES ('juan', crypt('Password123', gen_salt('bf')));

SELECT id, usuario, password_hash FROM usuarios_segura;

-- 4. Verificación: contraseña correcta (true)
SELECT usuario,
       password_hash = crypt('Password123', password_hash) AS contrasena_correcta
FROM usuarios_segura
WHERE usuario = 'juan';

-- 5. Verificación: contraseña incorrecta (false)
SELECT usuario,
       password_hash = crypt('OtraPassword', password_hash) AS contrasena_correcta
FROM usuarios_segura
WHERE usuario = 'juan';
