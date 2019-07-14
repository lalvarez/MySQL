-- DISENYO EXTERNO

/* Perfil rel_publicas
vistas:
	conductores 	(atributos persona)
	duenyos			(atributos persona)
	asignaciones	(dni, vehiculo, cond_habitual SI/NO)
	buenagente		(personas q nunca han alegado)
acceso tabla vehiculos
*/

CREATE PROFILE rel_publicas LIMIT 
   SESSIONS_PER_USER UNLIMITED; 
   
CREATE USER rp_name IDENTIFIED BY rp_password
	PROFILE rel_publicas;


-----------------------------------------------------------------------------------------------------------------
GRANT SELECT ON vehicles TO rp_name;
GRANT SELECT ON rp_conductores_view TO rp_name;
GRANT SELECT ON rp_owners_view TO rp_name;
GRANT SELECT ON rp_asignaciones_view TO rp_name;
----------------------------------------------------------------------------------------------------------------------


 CREATE OR REPLACE VIEW rp_conductores_view AS
	SELECT drivers.DNI, drivers.lic_date, drivers.lic_type, persons.name AS nombre, persons.surn_1 AS apellido1, 
			persons.surn_2 AS apellido2, persons.address, persons.town, persons.mobile, persons.email, persons.birthdate
	FROM drivers
	INNER JOIN persons ON drivers.DNI = persons.DNI
	ORDER BY  apellido1, apellido2, nombre;
	
 CREATE OR REPLACE VIEW rp_owners_view AS
	SELECT vehicles.owner, persons.DNI, persons.name AS nombre, persons.surn_1 AS apellido1, 
			persons.surn_2 AS apellido2, persons.address, persons.town, persons.mobile, persons.email, persons.birthdate
	FROM vehicles
	INNER JOIN persons ON vehicles.owner = persons.DNI
	ORDER BY  apellido1, apellido2, nombre;

CREATE OR REPLACE VIEW rp_asignaciones_view AS
	SELECT dr_DNI, dr_asgvehiculo, cond_habitual
	FROM(
		-- lista de drivers que no son regular driver
		SELECT driver_DNI as dr_DNI, veh_plate AS dr_asgvehiculo, 'NO' AS cond_habitual
		FROM (
			SELECT assignments.driver as driver_DNI, assignments.nPlate as veh_plate
			FROM assignments
			INNER JOIN vehicles ON assignments.nPlate = vehicles.nPlate
			WHERE assignments.driver != vehicles.reg_driver
			)
		UNION
		-- lista de drivers que si son regular driver
		SELECT driver_DNI as dr_DNI, veh_plate AS dr_asgvehiculo, 'SI' AS cond_habitual
		FROM (
			SELECT assignments.driver as driver_DNI, assignments.nPlate as veh_plate
			FROM assignments
			INNER JOIN vehicles ON assignments.nPlate = vehicles.nPlate
			WHERE assignments.driver = vehicles.reg_driver
			)	
		)
	ORDER BY dr_DNI, dr_asgvehiculo;

CREATE OR REPLACE VIEW buenagente_view AS
	--personas que no aparecen en la tabla alegaciones (si alegacion es Rechazada)
		SELECT DNI
		FROM persons
		WHERE NOT EXISTS (
							SELECT * FROM allegations
							WHERE allegations.new_debtor = persons.DNI
								AND allegations.status = 'R'
						);

/* Perfil administrativo
vistas:
	sanc_impagadas 	(importe, penalizacion actual, total_multa)
	notificacion	(matricula, owner contacto) ordenada por: email/telefono/direccion_postal
	ult_infraccion	(dni, vehiculo, cond_habitual SI/NO)
acceso tabla alegaciones
*/

CREATE PROFILE administrativo LIMIT 
   SESSIONS_PER_USER UNLIMITED; 

CREATE USER ad_name IDENTIFIED BY ad_password
	PROFILE administrativo;
-------------------------------------------------------------------------------------------------------------------------------
GRANT SELECT ON ad_sanc_impagadas_view TO ad_name;
GRANT SELECT ON ad_notificacion_view TO ad_name;
GRANT SELECT ON ad_ult_infraccion_view TO ad_name;
GRANT SELECT ON allegations TO ad_name;	
--------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE VIEW ad_sanc_impagadas_view AS
	SELECT amount, amount*2 AS penalizacion, amount*3 AS total_multa
	FROM tickets
	WHERE state = 'No-abonada';

CREATE OR REPLACE VIEW ad_notificacion_view AS
	SELECT nPlate, owner_DNI, sent_date, name AS owner_name, surn_1 AS owner_appellido1, 
			surn_2 AS owner_appellido2, email, mobile, address
	FROM
		(
		SELECT nPlate, owner AS owner_DNI, sent_date 
		FROM tickets
		INNER JOIN vehicles ON obs1_veh = nPlate
		WHERE state = 'No-abonada'		
		)
	INNER JOIN persons ON owner_DNI = persons.DNI
	ORDER BY email, mobile, address;

CREATE OR REPLACE VIEW ad_ult_infraccion_view AS
	SELECT obs1_veh as matricula, obs1_date as fecha
	FROM(
			SELECT * FROM tickets
			ORDER BY obs1_date
		)
	WHERE ROWNUM =1;

	
	
		
	


		
