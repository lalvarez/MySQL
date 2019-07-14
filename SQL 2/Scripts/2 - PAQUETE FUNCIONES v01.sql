-- Nuevos tipos de variables

	CREATE OR REPLACE TYPE OBS_TYPE 
	AS OBJECT (P_NPLATE VARCHAR2(7), P_ODATETIME TIMESTAMP);


-- PAQUETE
-- Consta de dos partes: descripcion e implementacion

-- DESCRIPCION -------------------------------------------------------------------
CREATE OR REPLACE PACKAGE package_functions AS 
	-- Variables acceso externo a este package
	
	--Funciones acceso externo a este package
	FUNCTION AMOUNT_R( VEL_VEH NUMBER, VEL_RAD NUMBER) RETURN NUMBER;
	FUNCTION AMOUNT_T(RAD1_PK NUMBER, RAD1_TIME TIMESTAMP, RAD2_PK NUMBER, RAD2_TIME TIMESTAMP, VEL_ROAD NUMBER) RETURN NUMBER;
	FUNCTION AMOUNT_D(TS1 TIMESTAMP, TS2 TIMESTAMP) RETURN NUMBER;
	FUNCTION O_BEF_RADAR(P_DATETIME TIMESTAMP, P_ROAD VARCHAR2, P_KM_POINT NUMBER, P_DIRECTION VARCHAR2) RETURN OBS_TYPE;
	FUNCTION O_BEF_VEHICULO(P_PLATE VARCHAR2, P_DATETIME TIMESTAMP) RETURN OBS_TYPE;
	
END package_functions;


--IMPLEMENTACION -----------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY package_functions AS
	----------------------------------------------------------------------------------
	-- Cuantia para una sancion de velocidad maxima de radar
	FUNCTION AMOUNT_R( VEL_VEH NUMBER, VEL_RAD NUMBER) 
	RETURN NUMBER IS

	RESULTADO NUMBER;
	BEGIN
			RESULTADO := VEL_VEH - VEL_RAD;
			RESULTADO := CEIL(RESULTADO);
			RESULTADO := RESULTADO*10;
		RETURN RESULTADO;
	END;
	
	-----------------------------------------------------------------------------------
	-- Cuantia para una sancion de velocidad de tramo
	FUNCTION AMOUNT_T(RAD1_PK NUMBER, RAD1_TIME TIMESTAMP, RAD2_PK NUMBER, RAD2_TIME TIMESTAMP, VEL_ROAD NUMBER) 
	RETURN NUMBER IS

	RESULTADO NUMBER;	
	VEL_VEH NUMBER;
	AUX1 NUMBER;
	AUX2 NUMBER;
	BEGIN
			AUX1 := (RAD2_PK) - (RAD1_PK);
			AUX2 := (TO_DATE(RAD2_TIME) - TO_DATE(RAD1_TIME))*24;
			VEL_VEH := AUX1/AUX2;
			RESULTADO := AMOUNT_R (VEL_VEH, VEL_ROAD);
		RETURN RESULTADO;
	END;
	-----------------------------------------------------------------------------------
	-- Cuantia para una sancion de distancia
	FUNCTION AMOUNT_D(TS1 TIMESTAMP, TS2 TIMESTAMP) 
	RETURN NUMBER IS

	RESULTADO NUMBER;	
	SEGUNDOS1 NUMBER;
	SEGUNDOS2 NUMBER;
	BEGIN
			SEGUNDOS1 := EXTRACT(SECOND FROM TS1);
			SEGUNDOS2 := EXTRACT(SECOND FROM TS2);
			SEGUNDOS1 := SEGUNDOS1 - SEGUNDOS2;
			RESULTADO := (3.6 - ABS(SEGUNDOS1))*10*10;
			RETURN RESULTADO;
	END;
	-----------------------------------------------------------------------------------
	-- Observacion inmediatamente anterior a otra observacion (del mismo radar)
	FUNCTION O_BEF_RADAR(P_DATETIME TIMESTAMP, P_ROAD VARCHAR2, P_KM_POINT NUMBER, P_DIRECTION VARCHAR2) 
	RETURN OBS_TYPE IS
		
	MIN_DATETIME TIMESTAMP;
	PLATE_REC VARCHAR2(7);
	CURSOR c1 IS
		SELECT odatetime, nPlate
		FROM OBSERVATIONS
		WHERE P_DATETIME > odatetime AND P_ROAD = road AND P_KM_POINT = km_point AND P_DIRECTION = direction;

	BEGIN
			MIN_DATETIME := '1-JAN-00 01.01.32.700000 AM';
			PLATE_REC := '';
			FOR rec IN c1 
			LOOP
				IF rec.odatetime > MIN_DATETIME THEN
					MIN_DATETIME := rec.odatetime;
					PLATE_REC := rec.nPlate;
				END IF;
			END LOOP;
			RETURN OBS_TYPE(PLATE_REC,MIN_DATETIME);
	END;
	------------------------------------------------------------------------------------
	-- Observacion inmediatamente anterior a otra observacion (del mismo vehiculo)
	FUNCTION O_BEF_VEHICULO(P_PLATE VARCHAR2, P_DATETIME TIMESTAMP) 
	RETURN OBS_TYPE IS
				
	MIN_DATETIME TIMESTAMP;
	PLATE_REC VARCHAR2(7);
	CURSOR c1 IS
		SELECT odatetime, nPlate
		FROM OBSERVATIONS
		WHERE P_DATETIME > odatetime AND P_PLATE = nPlate;

	BEGIN
			MIN_DATETIME := '1-JAN-00 01.01.32.700000 AM';
			PLATE_REC := '';
			FOR rec IN c1 
			LOOP
				IF rec.odatetime > MIN_DATETIME THEN
					MIN_DATETIME := rec.odatetime;
					PLATE_REC := rec.nPlate;
				END IF;
			END LOOP;
			RETURN OBS_TYPE(PLATE_REC,MIN_DATETIME);
	END;
END package_functions;


