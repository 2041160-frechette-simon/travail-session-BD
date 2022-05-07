USE DonjonInc;
DELIMITER $$
DROP PROCEDURE IF EXISTS test;
CREATE PROCEDURE test()
BEGIN 
	DECLARE _result INT;
    DECLARE _flag TINYINT;
    SET _flag = 0;
	SET _result = (SELECT count(Affectation_salle.id_affectation) FROM Salle 
    INNER JOIN Affectation_salle ON Salle.id_salle = Affectation_salle.salle 
    WHERE salle.fonction = "salle des explosifs"
    AND '2022-04-04 00:00:00' BETWEEN debut_affectation AND fin_affectation);
    
    
    IF _result <=0 THEN
		SET _flag = 1;
    END IF;
    
    SELECT _flag, _result;
END$$
DELIMITER ;
 ## 
CALL test();

