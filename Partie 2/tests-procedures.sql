# Ceci est le script de tests pour les procédures
#Author : Clément Provencher
#
# Date :  03/05/22
# Modification: 03/05/22
#Langage: SQL

USE DonjonInc;

CALL Test_intimidation();

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
              (2000, 5), #niveau 1
              (2000, 2); #niveau 3
	INSERT INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(9, 1000, '1082-05-25 00:00:00'),
			  (10, 2000, '1082-05-10 00:00:00');
			
	#agir
	CALL Intimidation(9, 1000, _intimidation_reussi);
    CALL Intimidation(10, 2000, _intimidation_echec);
    
    #affirmer
    IF(_intimidation_reussi = 0)
    THEN SELECT 'intimidation non réussi alors qu\' elle aurait dù'; END IF;
    
    IF(_intimidation_echec = 1)
    THEN SELECT 'intimidation réussi alors qu\'elle devrait avoir échoué'; END IF;
    ROLLBACK;
END $$
DELIMITER ;

SELECT * FROM Aventurier NATURAL JOIN Expedition WHERE id_expedition = 3; #4 4 mage  3 5 pas mage
SELECT * FROM Monstre NATURAL JOIN Humanoide;

CALL Test_Malediction_affaiblissement();

DROP PROCEDURE IF EXISTS Test_Malediction_affaiblissement;
#Test de la procédure 2 : Malediction_affaiblissement
DELIMITER $$
CREATE PROCEDURE Test_Malediction_affaiblissement()
BEGIN
	
	#arranger
	DECLARE _attaque_sans_malédiction_1 INT;
    DECLARE _attaque_sans_malédiction_2 INT;
    DECLARE _attaque_premiere_expedition INT;
    DECLARE _attaque_deuxieme_expedition INT;
    START TRANSACTION;
    INSERT INTO Expedition(id_expedition, nom_equipe)
    VALUES(1000, 'mage'),
			(2000, 'pas de mage');
            
	INSERT INTO Expedition_aventurier(id_expedition, id_aventurier)
    VALUES(1000, 4),
			(2000, 3);
            
	INSERT INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(9, 1000, '1082-05-25 00:00:00'),
			  (10, 2000, '1082-05-10 00:00:00');
              
	INSERT INTO Affectation_salle(monstre, responsabilite,debut_affectation, salle)
    VALUES(1, 1, '1082-04-25 00:00:00', 9);
              
	SET _attaque_sans_malédiction_1 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 9 AND debut_affectation < '1082-05-25 00:00:00' AND
    fin_affectation > '1082-05-25 00:00:00');
    SET _attaque_sans_malédiction_2 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 10 AND debut_affectation < '1082-05-10 00:00:00' AND
    fin_affectation > '1082-05-10 00:00:00');
    
    CALL Malediction_affaiblissement(9, 1000);
    CALL Malediction_affaiblissement(10, 2000);
    
    SET _attaque_premiere_expedition = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 9 AND debut_affectation < '1082-05-25 00:00:00' AND
    fin_affectation > '1082-05-25 00:00:00');
    SET _attaque_deuxieme_expedition = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 10 AND debut_affectation < '1082-05-10 00:00:00' AND
    fin_affectation > '1082-05-10 00:00:00');
    
    IF(_attaque_sans_malédiction_1 = _attaque_premiere_expedition)
    THEN SELECT 'malédiction pas fonctionnée'; END IF;
    
    IF(_attaque_sans_malédiction_2 > _attaque_deuxieme_expedition)
    THEN SELECT 'malédiction fonctionnée sans mage'; END IF;
    ROLLBACK;
END $$
DELIMITER ;