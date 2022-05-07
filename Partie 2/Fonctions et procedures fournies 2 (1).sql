/**
 * Auteur : 		Alexandre Ouellet
 * Date :			29 avril 2022
 * Langage : 		SQL
 * Fichier : 		Fonctions et procédures stockées.sql
 * Description :	Fonctions et procédures en soutien au procédures et fonctions qu'il vous est demandé
 * 					de coder. Appelez ces fonctions au endroit indiqué dans l'énoncé.
 *					
 *					NE PAS MODIFIER CE FICHIER
 *
 */
DELIMITER $$

DROP FUNCTION IF EXISTS elements_opposes_piece $$
DROP PROCEDURE IF EXISTS infliger_dommage_monstre $$
DROP PROCEDURE IF EXISTS infliger_dommage_aventurier $$
DROP PROCEDURE IF EXISTS affaiblissement_monstres $$

/**
 * Vérifie si deux élémentaires d'éléments opposés (eau et feu) sont affectés en même temps 
 * dans une même salle.
 *
 * @param _id_salle 				l'identifiant de la salle dans laquelle vérifier s'il y a des élémentaires opposés
 * @param _debut_affectaion 		début de la période pendant laquelle vérifier s'il y a des élémentaires opposés
 * @param _fin_affectaion 			fin de la période pendant laquelle vérifier s'il y a des élémentaires opposés
 * @return 	1 s'il y a un conflit entre deux types d'élémentaires, 0 sinon
 */
CREATE FUNCTION elements_opposes_piece (_id_salle INT, _debut_affectation DATETIME, _fin_affectation DATETIME) RETURNS TINYINT READS SQL DATA
BEGIN
	DECLARE _nombre_elementaires_feu INTEGER;
    DECLARE _nombre_elementaires_eau INTEGER;
    
    SET _nombre_elementaires_feu = (
		SELECT count(*) FROM Elementaire
			INNER JOIN Famille_monstre ON id_famille = famille
            NATURAL JOIN Monstre
            INNER JOIN Affectation_salle ON id_monstre = monstre
            WHERE salle = _id_salle 
				AND element = 'feu'
				AND ( -- Vérifie l'intersection entre deux intervalles de date
					_debut_affectation BETWEEN debut_affectation AND fin_affectation
					OR _fin_affectation BETWEEN debut_affectation AND fin_affectation
					OR (_debut_affectation < debut_affectation AND _fin_affectation > fin_affectation)
				)
    );
    
    SET _nombre_elementaires_eau = (
		SELECT count(*) FROM Elementaire
			INNER JOIN Famille_monstre ON id_famille = famille
            NATURAL JOIN Monstre
            INNER JOIN Affectation_salle ON id_monstre = monstre
            WHERE salle = _id_salle 
                AND element = 'eau'
				AND ( -- Vérifie l'intersection entre deux intervalles de date
					_debut_affectation BETWEEN debut_affectation AND fin_affectation
					OR _fin_affectation BETWEEN debut_affectation AND fin_affectation
					OR (_debut_affectation < debut_affectation AND _fin_affectation > fin_affectation)
				)
    );
    
    RETURN _nombre_elementaires_feu > 0 AND _nombre_elementaires_eau > 0;
END $$

/**
 * Inflige des dommages à tous les monstres dans une salle.
 *
 * @param _id_salle				IN		identifiant de la salle dans laquelle les monstres subissent un dommage
 * @param _moment_expedition	IN		le moment auquel les dommages sont infliges
 * @param _dommages_infliges	IN 		la quantite de dommande à infliger à chaque monstre
 */
CREATE PROCEDURE infliger_dommage_monstre(IN _id_salle INTEGER, IN _moment_expedition DATETIME, IN _dommages_infliges INTEGER)
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
    FETCH _it_monstres INTO _id_monstre;
    
    -- Met à jour chaque monstre
    WHILE NOT _termine DO
		UPDATE Monstre 
			SET point_vie = point_vie - _dommages_infliges 
			WHERE id_monstre = _id_monstre;
        FETCH _it_monstres INTO _id_monstre;
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
    FETCH _it_aventuriers INTO _id_aventurier;
    
    -- Met à jour chaque monstre
    WHILE NOT _termine DO
		UPDATE Aventurier 
			SET point_vie = point_vie - _dommages_infliges 
			WHERE id_aventurier = _id_aventurier;
			
		FETCH _it_aventuriers INTO _id_aventurier;
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
			AND salle = _id_salle
            AND point_vie > 0
            AND attaque > 0;
    
    -- Gère la fermeture du curseur
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET _termine = TRUE;

	-- Ouverture du curseur
    OPEN _it_monstres;
    FETCH _it_monstres INTO _id_monstre;		-- On récupère le prochain monstre
    
    -- Tant que le curseur est ouvert
    WHILE NOT _termine DO
        UPDATE Monstre 								-- On met à jour son attaque
			SET attaque = attaque - 1	
            WHERE id_monstre = _id_monstre;
		FETCH _it_monstres INTO _id_monstre;		-- On récupère le prochain monstre
    END WHILE;
    
    CLOSE _it_monstres;								-- Fermeture du curseur
END $$

DELIMITER ;