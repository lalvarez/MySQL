drop table more_clust;
drop table tickets_clust;
drop index clstr_index;
drop cluster tickets_and_more;




--RESULTS AT 29-APR-18
--TIME CONSUMPTION: 773616 milliseconds.
--CONSISTENT GETS: 37435980 blocks

--RESULTS AT 30-APR-18
--TIME CONSUMPTION: 1155414 milliseconds.
--CONSISTENT GETS: 28922446,3 blocks

--RESULTS AT 01-MAY-18
--TIME CONSUMPTION: 2051170 milliseconds.
--CONSISTENT GETS: 37374832,1 blocks

--RESULTS AT 03/05/18
--TIME CONSUMPTION: 2495703 milliseconds.
--CONSISTENT GETS: 37283400 blocks



--haciendo el index de pay_date:

CREATE INDEX tickets_ix ON TICKETS(pay_date);

--RESULTS AT 01-MAY-18
--TIME CONSUMPTION: 1125742 milliseconds.
--CONSISTENT GETS: 18375780,3 blocks

--RESULTS AT 01-MAY-18
--TIME CONSUMPTION: 800443 milliseconds.
--CONSISTENT GETS: 9549906,8 blocks



-- new_ticket

CREATE CLUSTER obs_radars_cluster (road VARCHAR2(5));
CREATE INDEX obs_rdrs_clstr_ix ON CLUSTER obs_radars_cluster;
CREATE TABLE obs_clust CLUSTER obs_radars_cluster (road) as
	select * from OBSERVATIONS;
CREATE TABLE rdrs_clust CLUSTER obs_radars_cluster (road) as
	select * from RADARS;

	
-- hay 50000 observaciones y 47114 tickets
CREATE INDEX tickets_ix ON TICKETS(state, amount, pay_date);
CREATE INDEX nplate_ix ON OBSERVATIONS (nplate);


--RESULTS AT 02-MAY-18
--TIME CONSUMPTION: 948912 milliseconds.
--CONSISTENT GETS: 37385967,8 blocks