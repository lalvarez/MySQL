/* VISTA 
			a) Nueva Multa
Se crea una vista basada en la JOIN de la tabla observaciones con la tabla
roads y filtrando las observaciones cuya velocidad es mayor que la mitad del
limite de la carretera (un radar no puede tener un limite superior al de la carretera) */ 

CREATE OR REPLACE VIEW nueva_multa AS
SELECT observations.nPlate, observations.odatetime, observations.speed, roads.speed_limit
FROM observations
INNER JOIN roads ON observations.road = roads.name
WHERE observations.speed > (roads.speed_limit / 2)
ORDER BY nPlate, odatetime;

/* VISTA
			b) Proteston
Se crea una vista basada en la tabla allegations mostrando anyo, mes, y conductor con el maximo numero
de alegaciones rechazadas.
La subseleccion sirve para obtener el numero de alegaciones por debtor agrupados por anyo, mes, conductor, y cuenta.
La seleccion calcula la columna MAX y agrupa por las columnas de la seleccion
La columna new_debtor identifica el conductor por que se define proteston cuando la alegacion ha sido rechazada*/

CREATE OR REPLACE VIEW proteston AS 
SELECT year_p, month_p, new_debtor, MAX(cuenta) AS times
FROM (
	SELECT * 
	FROM(
		 SELECT EXTRACT(YEAR FROM reg_date) AS year_p, EXTRACT(MONTH FROM reg_date) AS month_p, 
					new_debtor, COUNT(new_debtor) AS cuenta
		 FROM allegations
		 WHERE status = 'R'
		 GROUP BY EXTRACT(YEAR FROM reg_date), EXTRACT(MONTH FROM reg_date), new_debtor
		 ORDER BY year_p, month_p, cuenta
		)
	)
GROUP BY year_p, month_p, new_debtor
ORDER BY year_p, month_p;
		
/* VISTA 
			c) Tramos
Se crea una vista sobre una SELF JOIN selection donde los radares en la misma
carretera y direccion, y estan separados 5 Km o menos */
CREATE OR REPLACE VIEW tramos AS
SELECT A.road, A.Km_point AS Km_point1, B.Km_point AS Km_point2, A.direction, A.speedlim
FROM radars A, radars B
WHERE A.road = B.road AND A.direction = B.direction AND (B.Km_point-A.Km_point) <= 5
ORDER BY A.road, A.Km_point;

/* VISTA 
			d) Conductores avispados
Se combina la tabla observaciones con las tablas vehicles and radars. La tabla vehicles
proporciona el reg_drived via nPlate. La tabla radars proporciona la velocidad limite
de la carretera (speedlim) via las columnas road, Km_point, y direction.
Se hace un inline selection (con columnas conductor y el porcentage calculado)
de aquellas observaciones con velocidad detectada en el radar (speed) es menor que la 
velocidad limite (speedlim) indicada por el radar.
Una seleccion sobre la seleccion anterior, crea los records con conductor y su promedio
de porcentage, se agrupan por conductor DNI para permitir usar el comando HAVING despues
de haber ordenado por promedio*/

CREATE OR REPLACE VIEW avispados AS
SELECT *
FROM (
		SELECT vrd AS driver, AVG(percentage) AS promedio 
		FROM (
				SELECT vehicles.reg_driver AS vrd, 100*observations.speed/radars.speedlim AS percentage
				FROM ((observations 
						INNER JOIN vehicles ON observations.nPlate = vehicles.nPlate)
						INNER JOIN radars ON observations.road = radars.road AND
											observations.Km_point = radars.Km_point AND
											observations.direction = radars.direction)
				WHERE speed <= speedlim
			)
		GROUP BY vrd
		ORDER BY promedio
	)
WHERE ROWNUM <=10;
		

	

