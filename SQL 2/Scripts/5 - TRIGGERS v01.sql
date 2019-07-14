-- TRIGGERS 

/*			a) Insertar multa
 
 */ 
CREATE OR REPLACE TRIGGER insertar_multa
	AFTER INSERT ON observations
	FOR EACH ROW
	DECLARE
		sp NUMBER(3);
		id VARCHAR2(9);
		vp NUMBER(3);
		obs2 OBS_TYPE;
		obs_anterior observations%ROWTYPE;
		radar_ant_vl NUMBER(3);
	BEGIN
		---------------------------------------------------------------------------------
		-- multa por velocidad puntual
		-- speed supera a radar speedlim
		-- capturamos la velocidad lim del radar para (road, Km_point, y direction)
		SELECT speedlim INTO sp
		FROM radars
		WHERE :NEW.road = radars.road AND :NEW.Km_point = radars.Km_point AND :NEW.direction = radars.direction;
		-- capturamos el DNI del owner del vehiculo
		SELECT owner INTO id
		FROM vehicles
		WHERE :NEW.nPlate = vehicles.nPlate;
		-- si la velocidad es superior a la del radar, se crea una nueva fila en la tabla tickets
		-- la cuantia se calcula con la funcion amount_r, y se asigna al duenyo como debtor
		IF :NEW.speed > sp THEN	
			-- la multa se inicia como registrada, pero no hay fecha de envio (sent_date)
			-- que no puede ser NULL, hay que modificar la tabla		
			INSERT INTO tickets
			VALUES (:NEW.nPlate, :NEW.odatetime, 'S', NULL, NULL, NULL, NULL, NULL, package_functions.amount_r(:NEW.speed, sp), id, 'R');
		END IF;
		-------------------------------------------------------------------------------------
		-- multa por velocidad en tramo
		-- la velocidad calculada entre radares consecutivos que distan menos de 5 km es mayor
		-- es mayor que la velocidad limite de la carretera
		--
		-- capturamos la velocidad limite de la carretera que es la que define multa en este caso
		SELECT speed_limit INTO sp FROM roads WHERE :NEW.road = name;
		SELECT owner INTO id FROM vehicles 	WHERE :NEW.nPlate = nPlate;
		-- calulamos la velocidad promedio entre este radar y el anterior usando la funcion o_bef_vehiculo
		obs2 := package_functions.o_bef_vehiculo(:NEW.nPlate, :NEW.odatetime);
		SELECT * INTO obs_anterior FROM observations WHERE nPlate = obs2.P_NPLATE AND odatetime = obs2.P_ODATETIME;
		-- isertar ticket si distancia < 5km y vp > velocidad road
		IF (:NEW.km_point - obs_anterior.km_point) < 5 THEN
			vp := (:NEW.km_point - obs_anterior.km_point)/EXTRACT(HOUR FROM (:NEW.odatetime - obs_anterior.odatetime));
			IF vp > sp THEN
			INSERT INTO tickets
				VALUES (:NEW.nPlate, :NEW.odatetime, 'T', :NEW.nPlate, obs_anterior.odatetime, 
						NULL, NULL, NULL, package_functions.amount_t(:NEW.km_point, :NEW.odatetime, obs_anterior.km_point, obs_anterior.odatetime, sp), id, 'R');
			END IF;
		END IF;
		-------------------------------------------------------------------------------------
		-- multa por distancia minima
		-- si el tiempo entre observaciones del mismo radar es menor que 3.6 segundos
		-- se multa al vehiculo que pertenece a la observacion anterior
		-- obetnemos observacion anterior del mismo radar
		obs2 := package_functions.o_bef_radar(:NEW.odatetime, :NEW.road, :NEW.km_point, :NEW.direction);
		SELECT * INTO obs_anterior FROM observations WHERE nPlate = obs2.P_NPLATE AND odatetime = obs2.P_ODATETIME;
		SELECT owner INTO id FROM vehicles 	WHERE vehicles.nPlate = obs_anterior.nPlate;		
		IF EXTRACT(SECOND FROM (:NEW.odatetime-obs_anterior.odatetime)) < 3.6 THEN
			INSERT INTO tickets
				VALUES (obs_anterior.nPlate, obs_anterior.odatetime,'D', :NEW.nPlate, :NEW.odatetime, 
						NULL, NULL, NULL, package_functions.amount_d(:NEW.odatetime, obs_anterior.odatetime), id, 'R'); 
		END IF;	
	END;

	
	
 /*			b) Procesar alegacion
 */ 
CREATE OR REPLACE TRIGGER allegation 
	FOR INSERT ON allegations
	COMPOUND TRIGGER
		n NUMBER;	
	-- before inserta una nueva alegacion que puede ser R o A
	BEFORE EACH ROW IS
		-- aqui no podemos acceder o modificar la tabla alegaciones
		BEGIN	
			-- averiguamos si el nuevo deudor es un driver assignado
			SELECT COUNT(driver) INTO n FROM assignments WHERE nPlate = :NEW.obs_veh AND driver = :NEW.new_debtor;
			-- si el nuevo deudor no es un conductor asignado, se rechaza
			IF n = 0 THEN
				:NEW.status := 'R'; --cambiamos el default status que es 'U'
				--RAISE rechazada;
				RAISE_APPLICATION_ERROR(-20109,'No hay conductor asignado');
			ELSE
			-- si es nuevo deudor es un conductor asignado, se aprueba inicialmente
				:NEW.status := 'A';
				-- con las alegaciones Aprobadas hay que cambiar el estado del ticket
				-- a registrado y actualizar el deudor
				UPDATE tickets
				SET debtor = :NEW.new_debtor, state = 'R'
				WHERE obs1_veh = :NEW.obs_veh AND obs1_date = :NEW.obs_date AND tik_type = :NEW.tik_type;
			END IF;
	END BEFORE EACH ROW; 
	-- una vez insertada, buscamos si la misma multa ha sido allegada previamente
	AFTER EACH ROW IS
		-- aqui si podemos acceder o modificar la tabla alegaciones
		-- si hay mas de una alegacion para el mismo ticket, cambiamos la alegacion a 'U'
		BEGIN
		SELECT COUNT(reg_date) INTO n FROM allegations WHERE obs_veh = :NEW.obs_veh AND obs_date = :NEW.obs_date
						AND tik_type = :NEW.tik_type;
			IF n > 1 THEN
				UPDATE allegations
				SET status = 'U'
				WHERE obs_veh = :NEW.obs_veh AND obs_date = :NEW.obs_date AND tik_type = :NEW.tik_type AND reg_date = :NEW.reg_date;
			END IF;	
	END AFTER EACH ROW;
END allegation;		
			
	
/*			c) A rey muerto
			IMPORTANTE, nota del enunciado indicanco que se necesita modificar la tabla para admitir NULL :
			ALTER TABLE vehicles DROP constraint FK_VEHICLES2				
			ALTER TABLE vehicles ADD CONSTRAINT FK_VEHICLES2 FOREING KEY (owner) REFERENCES persons ON DELETE SET NULL;
*/

CREATE OR REPLACE TRIGGER rey_muerto
	BEFORE UPDATE OF reg_driver ON vehicles
	FOR EACH ROW
	DECLARE
		n NUMBER;
	BEGIN
		IF :NEW.reg_driver = NULL THEN
			-- asignamos como nuevo conductor el de mas antiguedad de la tabla asignados
			-- para este vehiculo
			SELECT COUNT(driver) INTO n FROM assignments WHERE nPlate = :NEW.nPlate;			
			IF n > 0 THEN
				SELECT driver INTO :NEW.reg_driver
										FROM (
											SELECT assignments.driver, drivers.lic_date
											FROM assignments 
											INNER JOIN drivers ON assignments.driver = drivers.DNI
											WHERE assignments.nPlate = :NEW.nPlate
											ORDER BY lic_date DESC
											)
										WHERE ROWNUM =1;
			ELSE
				RAISE_APPLICATION_ERROR(-20110,'No hay conductor asignado');
			END IF;
		END IF;
	END;

/*			d) Restricciones
				velocidad radar menor o igual general via
				conductores al menos 18 anyos
*/ 
-- velocidad radar menor o igual general via
CREATE OR REPLACE TRIGGER RADAR_SPEED 
	BEFORE INSERT OR UPDATE ON radars
	FOR EACH ROW
	DECLARE
		sp NUMBER(3,0);
	BEGIN
		SELECT speed_limit INTO sp FROM roads WHERE name = :NEW.road;
		IF :NEW.speedlim > sp THEN 
			RAISE_APPLICATION_ERROR(-20111,'Velocidad radar no puede ser mayor que velocidad road');
		END IF;
	END;
	
-- conductores al menos 18 anyos
CREATE OR REPLACE TRIGGER MENOR_EDAD 
	BEFORE INSERT OR UPDATE ON drivers
	FOR EACH ROW
	DECLARE
		bd DATE;
	BEGIN
		SELECT birthdate INTO bd FROM persons WHERE DNI = :NEW.DNI;
		IF FLOOR((SYSDATE - bd)/365) < 18 THEN
			RAISE_APPLICATION_ERROR(-20112, 'Edad no puede ser menor que 18');
		END IF;		
	END;

