INSERT INTO OWNERS (owner_DNI, owner_name, owner_surn1, owner_surn2 , owner_address , owner_town, owner_mobile , owner_email , owner_birth) SELECT DISTINCT NIF_DUENO, NOMBRE_DUENO, APELL_1_DUENO, APELL_2_DUENO , DIRECC_DUENO , CIUDAD_DUENO, TLF_DUENO , EMAIL_DUENO ,CUMPLE_DUENO FROM fsdb.megatable;

INSERT INTO DRIVERS (driver_DNI, driver_name, driver_surn1, driver_surn2 , driver_address , driver_town, driver_mobile , driver_email , driver_birth, driver_license, license_date, driver_age) SELECT DISTINCT NIF_CONDTR, NOMBRE_CONDTR, APELL_1_CONDTR, APELL_2_CONDTR, DIRECC_CONDTR , CIUDAD_CONDTR, TLF_CONDTR, EMAIL_CONDTR, CUMPLE_CONDTR, CARNET_CONDTR, FECHA_CARNET, EDAD_CONDTR  FROM fsdb.megatable WHERE EDAD_CONDTR >= 18;

INSERT INTO VEHICLES (nPlate, VIN, color, make, model, power_, reg_date, MOT_date, owner_DNI,  driver_DNI ) SELECT DISTINCT MATRICULA, VIN, COLOR, MARCA, MODELO, POTENCIA,  FECHA_MATRICULA, FECHA_ITV, NIF_DUENO, NIF_CONDTR FROM fsdb.megatable WHERE EDAD_CONDTR >= 18;

INSERT INTO VEH_DR (driver_DNI,nPlate) SELECT DISTINCT NIF_CONDTR, MATRICULA FROM fsdb.megatable WHERE EDAD_CONDTR >=18;

INSERT INTO OBSERVATIONS (nPlate, road, km_point, direction, date_, time_,speed, speed_limit, radar_speedlim) SELECT DISTINCT MATRICULA, CARRETERA_FOTO, PTO_KM_RADAR, SENTIDO_RADAR, FECHA_FOTO, HORA_FOTO, VELOCIDAD_FOTO, LIMIT_VEL_CTERA, LIMIT_VEL_RADAR FROM fsdb.megatable  WHERE EDAD_CONDTR >= 18;
