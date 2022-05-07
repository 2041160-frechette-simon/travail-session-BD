USE DonjonInc;
DROP PROCEDURE IF EXISTS test;
DELIMITER $$
CREATE PROCEDURE test()
BEGIN
DECLARE _nombre_affectations INT;

SET _nombre_affectations = (SELECT count(Affectation_salle.id_affectation) FROM Salle INNER JOIN Affectation_salle ON Salle.id_salle = Affectation_salle.salle WHERE salle.fonction = "salle des explosifs");

	IF _nombre_affectations <=0 THEN 
		SIGNAL SQLSTATE '01001'
			SET MESSAGE_TEXT = "Il n'y a aucun responsable dans la salle choisie au moment fourni.";
	END IF;
END$$
DELIMITER ;

CALL test();

            
            	# suppression des affectations de la salle 1
    DELETE FROM Affectation_salle WHERE salle = 1;
    
    	# reconstruction des affectations de la salle 1
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation) VALUES
	(1,11,1,1,'1082-06-26 04:00:00','1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,	11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
    
    SELECT Salle.fonction FROM Salle WHERE id_salle = 1;