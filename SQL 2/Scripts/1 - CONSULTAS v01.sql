/*CONSULTA
			a) 10 vehiculos mas observados
TRUNC function returns a TIMESTAMP type truncated segun el segundo parametro
SYSTIMESTAMP retorna un TIMRSTAMP type con la fecha y hora del server
			*/

SELECT * FROM (
				SELECT nPlate, COUNT(nPlate) as contador
				FROM observations
				WHERE TRUNC(odatetime, 'DATE') = TRUNC(SYSTIMESTAMP, 'DATE')
				GROUP BY nPlate
				ORDER BY contador
				)
WHERE rownum < 11;


/*CONSULTA
			b) listado de carreteras y velocidad promedio
Se utiliza la tabla radars para calcular la velocidad limite
promedio en cada punto kilometrico (incluyendo ambos sentidos).
Se lista las columnas road y veloc_promedio ordenadas primero por
velocidad promedio y, si las filas tienen la misma velocidad promedio,
entonces ordenadas por carretera*/

SELECT road, AVG(speedlim) as veloc_promed
FROM radars
GROUP BY road
ORDER BY veloc_promed ASC, road ;

/*CONSULTA
			c) Personas no conductores
En un sub-select anyadimos a la tabla assigments owners and reg_driver
del mismo vehiculo con lo que creamos filas de owner, reg_driver y assigned driver.
Seleccionando aquellos owners que no aparecen ni como assig_driver ni como reg_driver*/

SELECT veh_owner
FROM (
		SELECT veh_owner, assig_driver, main_driver
		FROM (
				SELECT assignments.driver as main_driver, vehicles.reg_driver as assig_driver, vehicles.owner as veh_owner
				FROM assignments
				INNER JOIN vehicles ON assignments.nPlate = vehicles.nPlate
			)
		WHERE veh_owner != assig_driver AND veh_owner != main_driver
	)
ORDER BY veh_owner;

/*CONSULTA
			d) Jefazos
*/

SELECT owner 
FROM (
		SELECT owner, COUNT(owner) AS c_owner
		FROM vehicles
		WHERE owner != reg_driver
		GROUP BY owner
	)
WHERE c_owner >= 3
ORDER BY c_owner DESC;
/*CONSULTA
			e) Evolucion
La diferencia se obtine restando dos queries. Una calcula el total de la columna amount
para aquellos tickets con fecha de pago en el anyo actual y mes actual menos 1. La otra
calcula el total de los tickes con fecha de pago el anyo actual menos 1 y el mes actual
menos 1*/
SELECT
	(
	SELECT SUM(amount)
	FROM tickets
	WHERE EXTRACT(YEAR FROM pay_date) = EXTRACT(YEAR FROM SYSDATE) 
			AND EXTRACT(MONTH FROM pay_date) = EXTRACT(MONTH FROM (ADD_MONTHS(SYSDATE,-1)))
	) -
	(
	SELECT SUM(amount)
	FROM tickets
	WHERE EXTRACT(YEAR FROM pay_date) = EXTRACT(YEAR FROM SYSDATE)-1 
			AND EXTRACT(MONTH FROM pay_date) = EXTRACT(MONTH FROM (ADD_MONTHS(SYSDATE,-1)))
	) AS diferencia
FROM DUAL;


