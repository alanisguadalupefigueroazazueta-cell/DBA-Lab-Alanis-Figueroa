-- LAB-01 · Actividad 12 — Campos modificados en cada UPDATE auditado
-- Sesión de administrador.

SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a
CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'
  AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;

-- Restaurar el valor anterior del RFC de María García (id = 3).
-- La condición sobre el valor actual evita sobrescribir un cambio posterior.
-- Esta restauración también quedará auditada.
UPDATE clientes
SET rfc = 'GAMA780912XYZ'
WHERE id = 3 AND rfc = 'GAMA780912ZZZ';
