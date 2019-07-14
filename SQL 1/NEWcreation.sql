CREATE TABLE OWNERS (
owner_name VARCHAR2(35) NOT NULL,
owner_surn1 VARCHAR2(15) NOT NULL,
owner_surn2 VARCHAR2(15) NOT NULL,
owner_address VARCHAR2(42) NOT NULL,
owner_town VARCHAR2(35) NOT NULL,
owner_mobile VARCHAR2(9),
owner_email VARCHAR2(50),
owner_birth VARCHAR2(10) NOT NULL,
owner_DNI VARCHAR2(9) PRIMARY KEY NOT NULL
);

CREATE TABLE DRIVERS (
driver_name VARCHAR2(35) NOT NULL,
driver_surn1 VARCHAR2(15) NOT NULL,
driver_surn2 VARCHAR2(15) NOT NULL,
driver_address VARCHAR2(42) NOT NULL,
driver_town VARCHAR2(35) NOT NULL,
driver_mobile VARCHAR2(9),
driver_email VARCHAR2(50),
driver_birth VARCHAR2(10) NOT NULL,
driver_license VARCHAR2(3) NOT NULL,
license_date VARCHAR2(10) NOT NULL,
driver_age NUMBER(2) NOT NULL,
driver_DNI VARCHAR2(9) PRIMARY KEY NOT NULL
);

CREATE TABLE VEHICLES (
nPlate VARCHAR2(7) NOT NULL,
VIN VARCHAR2(17) NOT NULL,
color VARCHAR2(25) NOT NULL,
make VARCHAR2(10) NOT NULL,
model VARCHAR2(12) NOT NULL,
power_ VARCHAR(6) NOT NULL,
reg_date VARCHAR2(10) NOT NULL,
MOT_date VARCHAR2(10) NOT NULL,
owner_DNI VARCHAR2(9) NOT NULL,
driver_DNI VARCHAR2(9) NOT NULL,
CONSTRAINT Pk_Vehicles PRIMARY KEY (nPlate),
CONSTRAINT Fk_Vehicle_ownerDNI FOREIGN KEY (owner_DNI) REFERENCES OWNERS (owner_DNI),
CONSTRAINT Fk_Vehicle_driverDNI FOREIGN KEY (driver_DNI) REFERENCES DRIVERS (driver_DNI)
);

CREATE TABLE VEH_DR (
driver_DNI VARCHAR2(9) NOT NULL,
nPlate VARCHAR2(7) NOT NULL,
CONSTRAINT Pk_Veh_Dr PRIMARY KEY (driver_DNI, nPlate),
CONSTRAINT Fk_Veh_Dr_driver_DNI FOREIGN KEY (driver_DNI) REFERENCES DRIVERS (driver_DNI),
CONSTRAINT Fk_Veh_Dr_nPlate FOREIGN KEY (nPlate) REFERENCES VEHICLES (nPlate)
);

CREATE TABLE OBSERVATIONS(
nPlate VARCHAR2(7) NOT NULL,
road VARCHAR2(5) NOT NULL,
km_point NUMBER(3) NOT NULL,
direction VARCHAR2(3) NOT NULL,
date_ VARCHAR2(10) NOT NULL,
time_ VARCHAR2(12) NOT NULL,
speed NUMBER(3) NOT NULL,
speed_limit NUMBER(3) NOT NULL,
radar_speedlim NUMBER(3) NOT NULL,
CONSTRAINT Pk_Observations PRIMARY KEY (road,km_point,direction,date_,time_),
CONSTRAINT Fk_Observations_vehicles FOREIGN KEY (nPlate) REFERENCES VEHICLES (nPlate) ON DELETE CASCADE
);

CREATE TABLE SANCTIONS (
nPlate VARCHAR2(7) NOT NULL,
owner_DNI VARCHAR2(9) NOT NULL,
driver_DNI VARCHAR2(9) NOT NULL,
date_ VARCHAR2(10) NOT NULL,
time_ VARCHAR2(12) NOT NULL,
date_send VARCHAR2(10) NOT NULL,
date_max VARCHAR2(10) NOT NULL,
pay_way  VARCHAR2(35) NOT NULL,
status  VARCHAR2(10) NOT NULL,
amount VARCHAR2(5) NOT NULL,
penalty NUMBER(10) NOT NULL,
date_payment VARCHAR2(10),
CONSTRAINT Pk_Sanctions PRIMARY KEY (nPlate,date_,time_),
CONSTRAINT Fk_Sanctions_vehicles FOREIGN KEY (nPlate) REFERENCES VEHICLES (nPlate),
CONSTRAINT Fk_Sanctions_ownerDNI FOREIGN KEY (owner_DNI) REFERENCES OWNERS (owner_DNI),
CONSTRAINT Fk_Sanctions_driverDNI FOREIGN KEY (driver_DNI) REFERENCES DRIVERS (driver_DNI),
CONSTRAINT cons_Sanctions_status CHECK (status IN ('issued','received', 'registered', 'paid', 'not_paid')),
CONSTRAINT cons_Sanctions_pay_way CHECK (pay_way IN ('transfer', 'card_payment', 'bank'))
);

CREATE TABLE PLEADS (
owner_DNI VARCHAR2(9) NOT NULL,
dni_guilty VARCHAR2(9) NOT NULL,
register_date VARCHAR2(10) NOT NULL,
status  VARCHAR2(10) NOT NULL,
execution_date VARCHAR2(10),
nPlate VARCHAR2(7) NOT NULL,
date_ VARCHAR2(10) NOT NULL,
time_ VARCHAR2(12) NOT NULL,
CONSTRAINT Pk_Pleads PRIMARY KEY (owner_DNI,date_,time_),
CONSTRAINT Fk_Pleads_ownerDNI FOREIGN KEY (owner_DNI) REFERENCES OWNERS (owner_DNI),
CONSTRAINT Fk_Pleads_sanction FOREIGN KEY (nPlate,date_,time_) REFERENCES SANCTIONS (nPlate,date_,time_),
CONSTRAINT Fk_Pleads_dni_guilty FOREIGN KEY (dni_guilty) REFERENCES DRIVERS (driver_DNI),
CONSTRAINT cons_Pleads_status CHECK (status IN ('approved','rejected', 'under study'))
);