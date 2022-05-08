# Ceci est le script de tests pour les fonctions 1 à 6
#Author : Simon Fréchette
#
# Date : 30 avril 2022
#Langage: SQL

USE DonjonInc;
# ---------------------------------------------------------------------------------------------------------------------------
# fonction 1 ET 2
#RAPPEL
/*
 fonction qui crypte et décrypte en utilisant le mot de passe mortauxheros.
 @param chaine_a_crypter TEXT
 @return valeur cryptée BLOB
*/
/*
Cette fonction décrypte un contenu crypté en utilisant la clé de cryptage définie ci-dessus. Elle 
retourne le texte clair prêt à être lu par un être humain.
@param chaine_a_decrypter BLOB
@return valeur en clair TEXT
*/
# ---------------------------------------------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS test_fonction_1_2;
DELIMITER $$
CREATE PROCEDURE test_fonction_1_2()
BEGIN
    # si nous sommes en mesure d'encrypter et de décrypter une chaîne en utilisant la même clé, le processus fonctionne.
    DECLARE _chaine_originale VARCHAR(255);
    DECLARE _chaine_cryptee BLOB;
    DECLARE _message_resultat TEXT;
    DECLARE _chaine_finale VARCHAR(255);
    
    SET _chaine_originale = "Ceci est un test.";
    SET _chaine_cryptee = crypter_data(_chaine_originale);
    SET _chaine_finale = decrypter_data(_chaine_cryptee);
    
    IF _chaine_finale = _chaine_originale THEN
		SET _message_resultat = CONCAT("La chaîne de caractère '",_chaine_originale,"' a pu être décryptée à l'aide de la clé mortauxheros");
	ELSE
		SET _message_resultat = CONCAT("La chaîne de caractère décryptée ne correspond pas à l'originale. ORIGINALE: ",_chaine_originale," RESULTAT: ",_chaine_finale);
	END IF;
    SELECT _message_resultat AS resultat_fonc1_2;
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 3
#RAPPEL
/*
Cette fonction accepte la fonction d’une salle et un objet de type DATETIME et retourne l’identifiant 
du monstre qui en est responsable (plus haut niveau de responsabilité).
@param fonction_salle VARCHAR(255)
@param  date_a_verif DATETIME 
@return id du responsable
*/
# ---------------------------------------------------------------------------------------------------------------------------
/*
Procédure qui teste la valeur de retour de la fonction vérifiant le responsable d'une salle à un moment donné.
Cette fonction ajoute un monstre de niveau de responsabilite abherrant à la salle pour vérifier la réactivite de la fonction.
*/
DROP PROCEDURE IF EXISTS test_fonction_3_salle_peuplee;
DELIMITER $$
CREATE PROCEDURE test_fonction_3_salle_peuplee()
BEGIN
    DECLARE _fonction_salle_1 VARCHAR(255);
    DECLARE _responsable_trouve INT;
    DECLARE _message_resultat TEXT;
    
	#suppression des données de test
	DELETE FROM Affectation_salle WHERE monstre = 2000;
    DELETE FROM Monstre WHERE id_monstre = 2000;
    DELETE FROM Responsabilite WHERE id_responsabilite = 2000;
        
	# il faut d'abord trouver la fonction de la salle 1. C'est elle que l'on utilise pour le test
    SET _fonction_salle_1 = (SELECT Salle.fonction FROM Salle WHERE id_salle = 1);
    
    #ajout du monstre de test
    INSERT INTO Monstre(id_monstre,nom,code_employe,point_vie,attaque,numero_ass_maladie,id_famille,experience)
    VALUES (2000,"Monstre de test","TEST",100,1,"NUM",1,1);
    
    #ajout de la responsabilité
    INSERT INTO Responsabilite(id_responsabilite,titre,niveau_responsabilite)
    VALUES (2000,"test",1000);
    
    #affectation à la salle 1
    INSERT INTO Affectation_salle(monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES(2000,2000,1,'2020:05:01 00:00:00','2042:05:01 00:00:00');
    
    #vérification du plus haut niveau de responsabilite
    SET _responsable_trouve = trouver_responsable_salle(_fonction_salle_1,'2040:05:01 00:00:00');
    
    IF _responsable_trouve = 2000 THEN
		SET _message_resultat = "Le responsable de la salle a été retrouvé avec succès !";
	ELSE
		SET _message_resultat = 
        CONCAT("Le responsable de la salle ayant la fonction: '",_fonction_salle_1,"' n'a pas été retrouvé correctement. Le monstre '",_responsable_trouve," a été trouvé à tort");
	END IF;
    SELECT _message_resultat AS resultat_fonction_3_salle_peuplee;
	
	#suppression des données de test
	DELETE FROM Affectation_salle WHERE monstre = 2000;
    DELETE FROM Monstre WHERE id_monstre = 2000;
    DELETE FROM Responsabilite WHERE id_responsabilite = 2000;
END$$
DELIMITER ;
/*
Procédure qui teste la valeur de retour de la fonction vérifiant le responsable d'une salle à un moment donné.
Cette fonction retire toutes les affectations à une salle pour tester la réactivité de la fonction.
*/
DROP PROCEDURE IF EXISTS test_fonction_3_affectation_inexistante;
DELIMITER $$
CREATE PROCEDURE test_fonction_3_affectation_inexistante()
BEGIN
	DECLARE _id_responsable_trouve INT;
    DECLARE _fonction_salle_1 VARCHAR(255);
    DECLARE _code INT;
    DECLARE _message TEXT;
        
    # La classe d'erreur 40 a été utilisée pour substituer la classe 01 (warning). Puisque la procédure retourbe une valeur, les warnings sont effacés à la sortie. Voir l'article ci-dessous:
    # https://dev.mysql.com/doc/refman/8.0/en/signal.html
    DECLARE EXIT HANDLER FOR SQLSTATE '40001'
    BEGIN
		GET DIAGNOSTICS CONDITION 1
			_code = RETURNED_SQLSTATE,
			_message = MESSAGE_TEXT;
        #SELECT _code,_message;
        SELECT "Le test a réussi, la salle sans affectation a été signalée" AS resultat_fonction_3_affectation_inexistante;
    END;
    
	#suppression des affectations reliées à la salle 1 selon l'insertion donnée.
	DELETE FROM Affectation_salle WHERE salle = 1;
    
    START TRANSACTION;
		# il faut d'abord trouver la fonction de la salle 1. C'est elle que l'on utilise pour le test
		SET _fonction_salle_1 = (SELECT Salle.fonction FROM Salle WHERE id_salle = 1);
		SET _id_responsable_trouve = trouver_responsable_salle(_fonction_salle_1,'2040-05-01 00:00:00');

		
		#à ce stade-ci, une exception devrait avoir été levée
		SELECT _id_responsable_trouve, "Aucune exception n'a été levée. Le test a échoué" AS resultat_fonc3_affectation_inexistante;
    COMMIT;
    
    #re-construction des affectations reliées à la salle 1 selon l'insertion donnée
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES
    (1,11,1,1,'1082-06-26 04:00:00', '1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 4
#RAPPEL
/*
La fonction retourne l’aventurier qui possède le plus haut niveau dans l’expédition.
@param nom_expedition VARCHAR(255)
@return id de l'aventurier de plus haut niveau.
*/
# ---------------------------------------------------------------------------------------------------------------------------
/*
Procédure testant la fonction trouvant l'aventurier le plus haut niveau dans une expédition donnée.
*/
DROP PROCEDURE IF EXISTS test_fonction_4;
DELIMITER $$
CREATE PROCEDURE test_fonction_4()
BEGIN
	DECLARE _plus_haut_niveau_trouve INT;
    DECLARE _nom_expedition_1 VARCHAR(255);
    DECLARE _message_resultat TEXT;
    
	#suppression des données de test
    DELETE FROM Expedition_aventurier WHERE id_expedition = 1 AND id_aventurier = 2000;
    DELETE FROM Aventurier WHERE id_aventurier = 2000;
    
	# pour bien tester la fonction, nous allons introduire un aventurier abherrant dans une expédition existante (celle d'ID 1)
	SET _nom_expedition_1 = (SELECT Expedition.nom_equipe FROM Expedition WHERE id_expedition = 1);
            
    #création de l'aventurier
    INSERT INTO Aventurier(id_aventurier,nom,classe,niveau,point_vie,attaque)
    VALUES (2000,"test","test_classe",100,1000,1000);
    
    #jumelage de l'aventurier et l'expédition.
    INSERT INTO Expedition_aventurier(id_expedition,id_aventurier)
    VALUES (1,2000);
    
    # vérification de l'aventurier de plus haut niveau dans l'expedition
	SET _plus_haut_niveau_trouve = plus_haut_niveau_expedition(_nom_expedition_1);
    IF _plus_haut_niveau_trouve = 2000 THEN
		SET _message_resultat = "L'aventurier de plus haut niveau a été retrouvé avec succès !";
	ELSE
		SET _message_resultat = 
        CONCAT("Le plus haut niveau de l'expédition ayant le nom: '",_nom_expedition_1,"' n'a pas été retrouvé correctement. Le monstre '",_plus_haut_niveau_trouve," a été trouvé à tort");
	END IF;
    SELECT _message_resultat AS resultat_fonc4;
    
	#suppression des données de test
    DELETE FROM Expedition_aventurier WHERE id_expedition = 1 AND id_aventurier = 2000;
    DELETE FROM Aventurier WHERE id_aventurier = 2000;
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 5
#RAPPEL
/*
La fonction vérifie si au moins un monstre est en vie dans une salle donnée. Un monstre vivant possède un 
nombre de points de vie strictement plus grand que 0. Si la vérification s’effectue sur une salle qui 
n’est pas dans la BD ou qu’aucun monstre n’est affecté à la date demandée, une erreur est lancée.
@param id_salle INT
@param date_a_verif DATETIME
@return 0 si tous les monstres sont morts, 1 sinon.
*/
# ---------------------------------------------------------------------------------------------------------------------------
/*
Cette procédure de test se charge de vérifier si la fonction arrive bel et bien a détecter la vitalité dans les salles 
existantes où il y a des monstres d'affectés.
*/
DROP PROCEDURE IF EXISTS test_fonction_5_salle_peuplee;
DELIMITER $$
CREATE PROCEDURE test_fonction_5_salle_peuplee()
BEGIN
	
	# reconstruction des affectations de la salle 1
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation) VALUES
	(1,11,1,1,'1082-06-26 04:00:00','1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,	11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
    
	#Pour ce test, nous allons prendre une salle existante où il y a des monstres d'affectés. Aussi, on s'assurera que les monstres affectés sont en vie.
    # le tout est vérifié à l'aide de la requête suivante:
    #SELECT salle,debut_affectation,fin_affectation, Monstre.point_vie FROM Affectation_salle 
    #INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
    #WHERE Affectation_salle.salle = 1 AND Monstre.point_vie >0;
    # avec l'insertion fournie, on peut en conclure que en '1082:06:26 04:00:00' un monstre en vie a été affecté à la salle 1.
    
    IF verifier_vitalite_monstre_salle(1,'1082-06-27 00:00:00') = 1 THEN
		SELECT "La vitalité a été correctement déclarée" AS resultat_fonc5_salle_peuplee;
	ELSE
		SELECT "La vitalité a été déclare fausse à tort" AS resultat_fonc5_salle_peuplee;
    END IF;
END$$
DELIMITER ;

/*
Cette procédure de test se charge de vérifier si la fonction lève une exception appropriée lorsque la vérification 
est effectuée sur une salle existante mais non-affectée.
*/
DROP PROCEDURE IF EXISTS test_fonction_5_salle_non_affectee;
DELIMITER $$
CREATE PROCEDURE test_fonction_5_salle_non_affectee()
BEGIN
	# pour effectuer ce test, nous allons supprimmer toutes les affectations  de la salle 1 avant de la soumettre à la fonction.
    DECLARE _vitalite_trouve TINYINT;
    DECLARE _code INT;
    DECLARE _message TEXT;
    
	DECLARE EXIT HANDLER FOR SQLSTATE '02002'
    BEGIN
		GET DIAGNOSTICS CONDITION 1
			_code = RETURNED_SQLSTATE,
            _message = MESSAGE_TEXT;
		#SELECT _code,_message;
        SELECT "Le test a réussi ! La vitalité d'une salle non-affectée a déclenché une exception." AS resultat_fonc5_salle_non_affectee;
        ROLLBACK;
    END;
    
	# suppression des affectations de la salle 1
    DELETE FROM Affectation_salle WHERE salle = 1;
    
    START TRANSACTION;
		#vérifications de la vitalité
		SET _vitalite_trouve = verifier_vitalite_monstre_salle(1,'1082-06-27 04:00:00');
		
		# à ce stade-ci, une exception devrait avoir été levée
		SELECT "Aucune exception n'a été levée. Le test a échoué" AS resultat_fonc5_salle_non_affectee;
    COMMIT;
    
	# reconstruction des affectations de la salle 1
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation) VALUES
	(1,11,1,1,'1082-06-26 04:00:00','1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,	11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
END$$
DELIMITER ;

/*
Cette procédure de test se charge de vérifier si la fonction lève une exception appropriée lorsque la vérification 
est effectuée sur une salle inexistante.
*/
DROP PROCEDURE IF EXISTS test_fonction_5_salle_inexistante;
DELIMITER $$
CREATE PROCEDURE test_fonction_5_salle_inexistante()
BEGIN
	DECLARE _code INT;
    DECLARE _message TEXT;
    DECLARE _vitalite_trouve TINYINT;
    DECLARE EXIT HANDLER FOR SQLSTATE '02001'
    BEGIN
		GET DIAGNOSTICS CONDITION 1
			_code = RETURNED_SQLSTATE,
			_message = MESSAGE_TEXT;
		#SELECT _code,_message;
		SELECT "Le test a réussi ! La vérification de la vitalité sur une salle inexistante a levé une exception" AS resultat_fonc5_salle_inexistante;
		ROLLBACK;    
    END;
    START TRANSACTION;
		SET _vitalite_trouve = verifier_vitalite_monstre_salle(5000,'1082-06-26 04:00:00');

        #à ce stade-ci, une exception devrait avoir été levée
		SELECT "Aucune exception n'a été levée. Le test a échoué" AS resultat_fonc5_salle_inexistante;
    COMMIT;
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 6
#RAPPEL
/*
La fonction vérifie si un aventurier est en vie dans une expédition donnée. Un aventurier vivant 
possède un nombre de points de vie strictement plus grand que 0. Si la vérification s’effectue sur une 
expédition qui n’est pas dans la BD, une erreur est lancée.
@param id_expedition INT
@return 0 si tous les aventuriers sont morts, 1 sinon.
*/
# ---------------------------------------------------------------------------------------------------------------------------
/*
Procédure de test permettant de vérifier si la fonction de vitalité d'expédition vérifie correctement dans une expédition existante
*/
DROP PROCEDURE IF EXISTS test_fonction_6_expedition_existante;
DELIMITER $$
CREATE PROCEDURE test_fonction_6_expedition_existante()
BEGIN
	#nous allons prendre une expédition qui, selon l'instertion initiale, est peuplée d'aventuriers et où il y en  a au moins 1 en vie. L'expédition 1 est idéale.
    # Le tout a été vérifié à l'aide de la requête suivante:
    #SELECT * FROM Aventurier 
    #INNER JOIN Expedition_aventurier ON Expedition_aventurier.id_aventurier = Aventurier.id_aventurier
    #INNER JOIN Expedition ON Expedition_aventurier.id_expedition = Expedition.id_expedition
    #WHERE Expedition.id_expedition = 1 AND Aventurier.point_vie >0;
    #en ayant au moins un résultat suite à cette requête, on s'assure que l'expédition 1 est peuplée de vivants.
    
    #vérification vitalité
    IF verifier_vitalite_aventurier_expedition(1) = 1 THEN
		SELECT "La vitalité a été correctement déclarée pour une expedition existante" AS resultat_fonc6_expedition_existante;
	ELSE
		SELECT "La vitalité a été déclarée négative à tort pour une expédition existante" AS resultat_fonc6_expedition_existante;
	END IF;
END$$
DELIMITER ;

/*
Procédure de test permettant de vérifier si la fonction de vitalité d'expédition vérifie correctement dans une expédition inexistante
*/
DROP PROCEDURE IF EXISTS test_fonction_6_expedition_inexistante;
DELIMITER $$
CREATE PROCEDURE test_fonction_6_expedition_inexistante()
BEGIN
	DECLARE _vitalite_trouve TINYINT;
    DECLARE _code INT;
    DECLARE _message TEXT;
    
	DECLARE EXIT HANDLER FOR SQLSTATE '02001'
    BEGIN
		GET DIAGNOSTICS CONDITION 1
			_code = RETURNED_SQLSTATE,
            _message = MESSAGE_TEXT;
		#SELECT _code,_message;
		SELECT "Le test a réussi ! La vérification de la vitalité sur une expédition inexistante a déclenché une exception"AS resultat_fonc6_expedition_inexistante;
    END;
    
	START TRANSACTION;
		SET _vitalite_trouve = verifier_vitalite_aventurier_expedition(3000);
        
		#à ce stade-ci, une exception devrait avoir été levée
		SELECT "Aucune exception n'a été levée. Le test a échoué" AS resultat_fonc6_expedition_inexistante;
    COMMIT;
END$$
DELIMITER ;

# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
#Appel des tests
START TRANSACTION;
	# -- fonction 1 2
	CALL test_fonction_1_2();
    
	# -- fonction 3
    CALL test_fonction_3_salle_peuplee();
    CALL test_fonction_3_affectation_inexistante();
    
	# -- fonction 4
	CALL test_fonction_4();
    
	# -- fonction 5
	CALL test_fonction_5_salle_peuplee();
    CALL test_fonction_5_salle_non_affectee();
    CALL test_fonction_5_salle_inexistante();
    
	# -- fonction 6
	CALL test_fonction_6_expedition_existante();
    CALL test_fonction_6_expedition_inexistante();
COMMIT;
# ---------------------------------------------------------------------------------------------------------------------------

