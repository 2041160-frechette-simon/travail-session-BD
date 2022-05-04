#--------------------------------------------------------------
#Script de procédure
#
#Fait par Clément Provencher
#
#créé le 21/04/2022
#modifié le 03/05/2022
#
#--------------------------------------------------------------

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
	#Tant que le tous les monstres ou tous les aventuriers sont morts, combat
	WHILE verifier_vitalite_aventurier() = 1 AND verifier_vitalite_monstre_salle(_id_salle, _moment_visite) = 1
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
 */
DELIMITER $$
CREATE PROCEDURE Visite_salle(IN _id_salle INT, IN _id_expedition INT, IN _moment_visite DATETIME)
BEGIN
	DECLARE _intimidation_reussi TINYINT;
    
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
    INSERT INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(_id_salle, _id_expedition, _moment_visite);
	COMMIT; # si une erreur était levée, le code se serait arrèté
    
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
    INSERT INTO Famille_monstre(nom_famille, degats_base, point_vie_maximal)
		VALUES(_nom_famille, _degats_base, _point_vie);
        
	SET _id_famille = (SELECT id_famille FROM Famille_monstre WHERE nom_famille = _nom_famille);
    
	INSERT INTO Mort_vivant(famille, vulnerable_soleil, infectieux)
		VALUES(_id_famille, _soleil, _infectieux);
        
	COMMIT; # si une erreur était levée, le code se serait arrèté
    
END $$
DELIMITER ;
