/* PROCEDIMIENTOS

Generar sanciones cometidas por dia
Este procedimiento toma las multas del dia anterior en estado
"Registrada", muestra un mensaje en pantalla,
y cambia el estado a "Enviada"
*/

CREATE OR REPLACE PROCEDURE envia_sanciones IS
  -- Declaración de variables locales
	CURSOR c1 IS
		SELECT * 
		FROM tickets
		WHERE state = 'R' AND TRUNC(obs1_date, 'DATE') = TRUNC(SYSTIMESTAMP-1, 'DATE');	
	BEGIN
		-- cursor que recorre cada fila de la tabla para aquellas multas
		-- en estado 'R' y cuya fecha  es del dia anterior al actual

		-- For Loop para mostrar en pantalla las multas del dia anterior
		FOR rec in c1
		LOOP
			-- actualiza las columnas: state y sent_date
			rec.state := 'E';
			rec.sent_date := SYSDATE;
			DBMS_OUTPUT.PUT_LINE ('Vehiculo: ' || rec.obs1_veh || '; Fecha: ' || rec.obs1_date || 'Tipo multa: ' || rec.tik_type);
			DBMS_OUTPUT.PUT_LINE ('Conductor: ' || rec.debtor );
			DBMS_OUTPUT.PUT_LINE ('Cuantia multa: ' || rec.amount || '; Fecha limite pago: ' || SYSDATE + 20);
			DBMS_OUTPUT.PUT_LINE ('------------------------------------------------------------------');	
		END LOOP;
	END;