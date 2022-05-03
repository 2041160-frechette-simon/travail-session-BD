# Ceci est le script de tests pour les procédures
#Author : Clément Provencher
#
# Date :  03/05/22
# Modification: 03/05/22
#Langage: SQL

USE DonjonInc;

SELECT * FROM Monstre INNER JOIN Affectation_salle ON monstre = id_monstre;

#Test de la procédure 1 : Intimidation
DELIMITER $$
CREATE PROCEDURE Test_intimidation()
BEGIN
	DECLARE _intimidation_reussi TINYINT;
    DECLARE _intimidation_echec TINYINT;
	START TRANSACTION;
	#arranger
    INSERT INTO Expedition(id_expedition, nom_equipe)
		VALUES(1000, 'reussi'),
			  (2000, 'echec');
	
    INSERT INTO Expedition_aventurier(id_expedition, id_aventurier)
		VALUES(1000, 7), #niveau 15
			  (1000, 5), #niveau 1
              (2000, 5),
              (2000, 2);  #niveau 3
    ROLLBACK;
END $$
DELIMITER ;