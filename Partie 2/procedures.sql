#--------------------------------------------------------------
#Script de procédure
#
#Fait par Clément Provencher
#
#créé le 21/04/2022
#modifié le 21/04/2022
#
#--------------------------------------------------------------

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
	DECLARE _monstre_haut_xp INT;
    DECLARE _aventurier_bas_niveau INT;
    DECLARE _difference_niveau_xp INT;
    SET _monstre_haut_xp = (
		SELECT id_monstre FROM Affectation_salle
			INNER JOIN Monstre ON monstre = id_monstre
			WHERE salle = _id_salle
			ORDER BY experience DESC
			LIMIT 1
        );
	SET _aventurier_bas_niveau = (
		SELECT id_aventurier FROM Expedition_aventurier
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