#--------------------------------------------------------------
#Script de procédure
#
#Fait par Clément Provencher et Simon Fréchette
#
#créé le 21/04/2022
#modifié le 03/05/2022
#
#--------------------------------------------------------------


USE DonjonInc;

DROP PROCEDURE IF EXISTS Intimidation;
DROP PROCEDURE IF EXISTS Malediction_affaiblissement;
DROP PROCEDURE IF EXISTS Combat;
DROP PROCEDURE IF EXISTS Visite_salle;
DROP PROCEDURE IF EXISTS Embauche;
DROP PROCEDURE IF EXISTS Creation_famille_mort_vivants;

/**
 * Procédure d'intimidation
 * si l'intimidation est réussi, les aventuriers peuvent pillier sans tuer les monstres
 * ça se base sur le niveau d'expérience
 *
 * @param _id_salle IN
 * @param _id_expedition IN
 * @param _intimidation_reussi OUT           0 ou 1
 * @dependencies: intimidation
 */
DELIMITER $$
CREATE PROCEDURE Intimidation(IN _id_salle INT, IN _id_expedition INT, OUT _intimidation_reussi TINYINT)
BEGIN
	DECLARE _moment_visite DATETIME;
	DECLARE _monstre_haut_xp INT;
    DECLARE _aventurier_bas_niveau INT;
    DECLARE _difference_niveau_xp INT;
    SET _moment_visite = (SELECT moment_visite FROM Visite_salle WHERE
							expedition = _id_expedition AND
                            salle = _id_salle
		);
    SET _monstre_haut_xp = (
		SELECT experience FROM Affectation_salle
			INNER JOIN Monstre ON monstre = id_monstre
			WHERE salle = _id_salle AND
            debut_affectation < _moment_visite AND
            fin_affectation > _moment_visite
			ORDER BY experience DESC
			LIMIT 1
        );
	SET _aventurier_bas_niveau = (
		SELECT niveau FROM Expedition_aventurier
			NATURAL JOIN Aventurier
            WHERE id_expedition = _id_expedition
            ORDER BY niveau
            LIMIT 1
		);
	SET _difference_niveau_xp = _aventurier_bas_niveau - _monstre_haut_xp / 10;
    
    IF(_difference_niveau_xp > 3)
    THEN
		SET _intimidation_reussi = 1;
    ELSE
		SET _intimidation_reussi = 0;
    END IF;
END $$
DELIMITER ;

/**
 *Procédure de malédiction de débilitation
 *Si un mage attaque un monstre humanoïde, il le maudit
 *les mages comportent "mage", "magicien" ou "enchanteur"
 *
 *@param _id_salle IN
 *@param _id_expedition IN
 *@dependencies: affaiblissement_monstres
 */
DELIMITER $$
CREATE PROCEDURE Malediction_affaiblissement(IN _id_salle INT, IN _id_expedition INT)
BEGIN
	DECLARE _id_mage INT;
    DECLARE _id_humanoide INT;
    DECLARE _moment_visite DATETIME;
    SET _id_mage = (SELECT id_aventurier FROM Expedition
						NATURAL JOIN Expedition_aventurier
                        NATURAL JOIN Aventurier
                        WHERE id_expedition = _id_expedition
                        AND classe RLIKE '(?i)^mage$|^magicien(ne)?$|^enchanteure?$'
                        LIMIT 1);
	SET _id_humanoide = (SELECT id_humanoide FROM Salle
							INNER JOIN Affectation_salle ON salle = id_salle
                            INNER JOIN Monstre ON id_monstre = monstre
                            INNER JOIN Humanoide ON id_famille = famille
                            WHERE salle = _id_salle
                            LIMIT 1);
	SET _moment_visite = (SELECT moment_visite FROM Visite_salle
							WHERE salle = _id_salle
                            AND expedition = _id_expedition);
                            
	IF(_id_mage IS NOT NULL AND _id_humanoide IS NOT NULL)
    THEN 
		CALL affaiblissement_monstres (_id_salle, _moment_visite);
	END IF;
END $$
DELIMITER ;

/**
 *procédure de combat
 *Les combats se déroulent comme suit : 
 *- Les aventuriers attaquent 
 *- Les magiciens lancent leur malédiction
 *- Les montres attaquent
 *
 *@param _id_salle IN
 *@param _id_expedition IN
 *@dependencies: verifier_vitalite_aventurier_salle, verifier_vitalite_monstre_salle, Malediction_affaiblissement
 *@dependencies: infliger_dommage_monstre, infliger_dommage_aventurier
 */
 DELIMITER $$
CREATE PROCEDURE Combat(IN _id_salle INT, IN _id_expedition INT)
BEGIN
	DECLARE _moment_visite DATETIME;
    DECLARE _degats_aventuriers INT;
    DECLARE _degats_monstres INT;
    DECLARE _monstres_en_vie INT;
    DECLARE _aventuriers_en_vie INT;
    SET _moment_visite = (SELECT moment_visite FROM Visite_salle
							WHERE salle = _id_salle
                            AND expedition = _id_expedition);
                            
	#Tant que le tous les monstres ou tous les aventuriers ne sont pas morts, combat
	WHILE verifier_vitalite_aventurier_salle() = 1 AND verifier_vitalite_monstre_salle(_id_salle, _moment_visite) = 1
    DO
		SET _degats_aventuriers = (SELECT sum(attaque) FROM Expedition
									NATURAL JOIN Expedition_aventurier
                                    NATURAL JOIN Aventurier
                                    WHERE point_vie > 0
                                    AND id_expedition = _id_expedition
                                    GROUP BY id_expedition);
		SET _degats_monstres = (SELECT sum(attaque) FROM Salle
									INNER JOIN Affectation_salle ON salle = id_salle
                                    INNER JOIN Monstre ON monstre = id_monstre
                                    WHERE point_vie > 0
                                    AND debut_affectation <= _moment_visite
                                    AND fin_affectation >= _moment_visite
                                    GROUP BY Salle);
                                    
		SET _monstres_en_vie = (SELECT count(id_monstre) FROM Monstre WHERE point_vie > 0);
        SET _aventuriers_en_vie = (SELECT count(id_aventurier) FROM Aventurier WHERE point_vie > 0);
        
		CALL infliger_dommage_monstre(_id_salle, _moment_visite, _degats_aventuriers / _montres_en_vie);
        CALL Malediction_affaiblissement(_id_salle, _id_expedition);
        CALL infliger_dommage_aventurier(_id_expedition, _degats_monstres / _aventuriers_en_vie);
    END WHILE;
END $$
DELIMITER ;

/**
 *procédure de visite salle
 *D’abord les aventuriers tentent d’intimider les monstres. Si l’intimidation réussit, alors les aventuriers pillent la salle
 *Si l’intimidation ne réussit pas, alors un combat est engagé. 
 *Si les aventuriers sont victorieux, alors ils pillent la salle.
 *
 *@param _id_salle IN
 *@param _id_expedition IN
 *@param _moment_visite IN
 *@dependencies : visite_salle, initimidation, piller_salle
 */
DELIMITER $$
CREATE PROCEDURE Visite_salle(IN _id_salle INT, IN _id_expedition INT, IN _moment_visite DATETIME)
BEGIN
	DECLARE _intimidation_reussi TINYINT;
    
    #variables gestion erreur
	DECLARE _code CHAR(5);                      
    DECLARE _message TEXT; 
    
    #gestion d'erreur globale.
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1            
				_code = RETURNED_SQLSTATE,          
				_message = MESSAGE_TEXT;
			SELECT _code, _message;
		ROLLBACK;
    END;
    
    START TRANSACTION;
    
    IF NOT _moment_visite BETWEEN (SELECT depart FROM Expedition WHERE Expedition.id_expedition = _id_expedition) AND (SELECT terminaison FROM Expedition WHERE Expedition.id_expedition = _id_expedition)THEN 
		SIGNAL SQLSTATE '02001'
			SET MESSAGE_TEXT = "Le moment de visite choisi ne correpond pas aux dates d'itinéraire de l'expédition choisie";
    END IF;
    
    INSERT INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(_id_salle, _id_expedition, _moment_visite);
	COMMIT; # si une erreur était levée, le code se serait arrêté
    
	CALL Intimidation(_id_salle, _id_expedition, _intimidation_reussi);
    
    IF(_intimidation_reussi = 1)
    THEN
		CALL Piller_salle(_id_salle, _id_expedition);
	ELSE
		CALL Combat(_id_salle, _id_expedition);
        
        #si les aventuriers sont victorieux
        IF(verifier_vitalite_aventurier() = 1)
        THEN
			CALL Piller_salle(_id_salle, _id_expedition);
        END IF;
    END IF;
END $$
DELIMITER ;

/**
*Procédure pour l'embauche
*ajoute un nouvel employé au système
*
*@param _nom IN
*@param _code_employe IN
*@param _num_assurance_mal IN
*@param _nom_famille IN
*@dependencies: embauche
*/
DELIMITER $$
CREATE PROCEDURE Embauche(IN _nom VARCHAR(255), IN _code_employe CHAR(4), IN _num_assurance_mal BLOB, IN _nom_famille VARCHAR(255))
BEGIN
	DECLARE _id_famille INT;
    DECLARE _point_vie INT;
    DECLARE _attaque INT;
    
	#variables gestion erreur
	DECLARE _code CHAR(5);                      
    DECLARE _message TEXT; 
    
    #gestion d'erreur
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1            
				_code = RETURNED_SQLSTATE,          
				_message = MESSAGE_TEXT;
			SELECT _code, _message;
		ROLLBACK;
    END;
    
    IF (SELECT Famille_monstre.nom_famille FROM Famille_monstre WHERE Famille_monstre.nom_famille = _nom_famille) <> _nom_famille THEN
		SIGNAL SQLSTATE '02001'
			SET MESSAGE_TEXT = "La famille désignée n'existe pas";
    END IF;
    
    SET _id_famille = (SELECT id_famille FROM Famille_monstre WHERE nom_famille = _nom_famille);
    
    SET _point_vie = (SELECT point_vie FROM Famille_monstre WHERE id_famille = _id_famille);
    SET _attaque = (SELECT attaque FROM Famille_monstre WHERE id_famille = _id_famille);
    
    START TRANSACTION;
    INSERT INTO Monstre(nom, code_employe, point_vie, attaque, numero_assurance_maladie, id_famille, experience)
     VALUES(_nom, _code_employe, _point_vie, _attaque, _num_assurance_mal, _id_famille, 0);
     
	COMMIT;  # si une erreur était levée, le code se serait arrèté
END $$
DELIMITER ;

/**
 *procédure qui ajoute une nouvelle famille de morts-vivants
 *
 *@param _nom_famille IN
 *@param _point_vie IN
 *@param _degats_base IN
 *@param _soleil IN 		s'il est vulnerable au soleil
 *@param _infectieux IN 		s'il es infectieux
 *@dependencies: Creation_famille_mort_vivants
 */
DELIMITER $$
CREATE PROCEDURE Creation_famille_mort_vivants(IN _nom_famille VARCHAR(255), IN _point_vie INT, IN _degats_base INT, In _soleil TINYINT, IN _infectieux TINYINT)
BEGIN
    DECLARE _id_famille INT;
    
	#variables gestion erreur
	DECLARE _code CHAR(5);                      
    DECLARE _message TEXT; 
    
    #gestion d'erreur
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1            
				_code = RETURNED_SQLSTATE,          
				_message = MESSAGE_TEXT;
			SELECT _code, _message;
            ROLLBACK;
    END;
    
    START TRANSACTION;
    
    IF _point_vie <= 0 THEN
		SIGNAL SQLSTATE '02001'
			SET MESSAGE_TEXT = "Une famille ne peut pas avoir des points de vie maximaux de 0";
    END IF;
    
    INSERT INTO Famille_monstre(nom_famille, degats_base, point_vie_maximal)
		VALUES(_nom_famille, _degats_base, _point_vie);
        
	SET _id_famille = (SELECT id_famille FROM Famille_monstre WHERE nom_famille = _nom_famille);
    
    IF _soleil > 0 THEN
		SET _soleil = 1;
	END IF;
    
	IF _infectieux > 0 THEN
		SET _infectieux = 1;
	END IF;
    
    
	INSERT INTO Mort_vivant(famille, vulnerable_soleil, infectieux)
		VALUES(_id_famille, _soleil, _infectieux);
        
	COMMIT; # si une erreur était levée, le code se serait arrêté.
END $$
DELIMITER ;

/**
 *procédure qui pille la salle lors d'une visite.
 *
 *@param _id_salle IN
 *@param _id_expedition IN
 *@dependencies: piller_salle
 */
 DELIMITER $$
 DROP PROCEDURE IF EXISTS piller_salle;
 CREATE PROCEDURE piller_salle(IN _id_salle INT, IN _id_expedition INT)
 BEGIN
	SELECT "Le pillage de la salle a été initié, mais il n'a pas été implémenté."AS pillage_non_implemente;
 END$$
DELIMITER ;

#--------------------------------------------------------------
# fonctions  et procédures fournies

DELIMITER $$

DROP PROCEDURE IF EXISTS infliger_dommage_monstre $$
DROP PROCEDURE IF EXISTS infliger_dommage_aventurier $$
DROP PROCEDURE IF EXISTS affaiblissement_monstres $$

/**
 * Inflige des dommages à tous les monstres dans une salle.
 *
 * @param _id_salle				IN		identifiant de la salle dans laquelle les monstres subissent un dommage
 * @param _moment_expedition	IN		le moment auquel les dommages sont infliges
 * @param _dommages_infliges	IN 		la quantite de dommande à infliger à chaque monstre
 */
CREATE PROCEDURE infliger_dommage_monstre(IN _id_salle INTEGER, IN _moment_expedition INTEGER, IN _dommages_infliges INTEGER)
BEGIN
	DECLARE _id_monstre INTEGER;
    DECLARE _termine BOOLEAN DEFAULT FALSE;

	-- Curseur pour parcourir tous les monstres de la salle
	DECLARE _it_monstres CURSOR FOR 
		SELECT monstre FROM Affectation_salle
			INNER JOIN Monstre ON id_monstre = monstre
			WHERE salle = _id_salle 
				AND _moment_expedition BETWEEN debut_affectation AND fin_affectation
				AND point_vie > 0;
    
    -- Quand le curseur est vide, on indique que _termine est vrai
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _termine = TRUE;
            
	-- On part le curseur
	OPEN _it_monstres;
    
    -- Met à jour chaque monstre
    WHILE NOT _termine DO
		FETCH _it_monstres INTO _id_monstre;
        IF _id_monstre IS NOT NULL THEN
			UPDATE Monstre 
				SET vie = vie - _dommages_infliges 
                WHERE id_monstre = _id_monstre;
        END IF;
    END WHILE;
    
    -- On ferme le curseur
    CLOSE _it_monstres;
END $$

/**
 * Inflige des dommages à tous les aventuriers dans une expédition
 *
 * @param _id_expedition 			IN 			l'identifiant de l'expédition qui reçoit des dommages
 * @param _dommages_infliges		IN			la quantite de dommande reçu par membre de l'expédition
 */
CREATE PROCEDURE infliger_dommage_aventurier(IN _id_expedition INTEGER, IN _dommages_infliges INTEGER)
BEGIN
	DECLARE _id_aventurier INTEGER;
    DECLARE _termine BOOLEAN DEFAULT FALSE;

	-- Curseur pour parcourir tous les monstres de la salle
	DECLARE _it_aventuriers CURSOR FOR 
		SELECT id_aventurier 
			FROM Expedition_aventurier
			NATURAL JOIN Aventurier
			WHERE id_expedition = _id_expedition 
            AND point_vie > 0;
   
    -- Quand le curseur est vide, on indique que _termine est vrai
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _termine = TRUE;
            
	-- On part le curseur
	OPEN _it_aventuriers;
    
    -- Met à jour chaque monstre
    WHILE NOT _termine DO
		FETCH _it_aventuriers INTO _id_aventurier;
        IF _id_aventurier IS NOT NULL THEN
			UPDATE Aventurier 
				SET vie = vie - _dommages_infliges 
                WHERE id_aventurier = _id_aventurier;
        END IF;
    END WHILE;
    
    -- On ferme le curseur
    CLOSE _it_aventuriers;
END $$

CREATE PROCEDURE affaiblissement_monstres (IN _id_salle INTEGER, IN _moment_visite DATETIME)
BEGIN
	DECLARE _id_monstre INTEGER;				-- Id courrant
	DECLARE _termine BOOLEAN DEFAULT FALSE;		-- Fin du curseur
    
    -- Curseur qui parcours les monstres qui sont en vie et qui ont encore une attaque
	DECLARE _it_monstres CURSOR FOR 
		SELECT monstre FROM Affectation_salle 
			INNER JOIN Monstre ON monstre = id_monstre
            WHERE _moment_visite BETWEEN debut_affectation AND fin_affectation
			AND id_salle = _id_salle
            AND point_vie > 0
            AND attaque > 0;
    
    -- Gère la fermeture du curseur
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET _termine = TRUE;

	-- Ouverture du curseur
    OPEN _it_monstres;
    
    -- Tant que le curseur est ouvert
    WHILE NOT _termine DO
		FETCH _it_monstres INTO _id_monstre;		-- On récupère le prochain monstre
        UPDATE Monstre 								-- On met à jour son attaque
			SET attaque = attaque - 1	
            WHERE id_monstre = _id_monstre;
    END WHILE;
    
    CLOSE _it_monstres;								-- Fermeture du curseur
END $$

#--------------------------------------------------------------
