/**
 * Vérifie si deux élémentaires d'éléments opposés (eau et feu) sont affectés en même temps 
 * dans une même salle.
 *
 * @param _id_salle 				l'identifiant de la salle dans laquelle vérifier s'il y a des élémentaires opposés
 * @param _debut_affectaion 		début de la période pendant laquelle vérifier s'il y a des élémentaires opposés
 * @param _fin_affectaion 			fin de la période pendant laquelle vérifier s'il y a des élémentaires opposés
 * @return 	1 s'il y a un conflit entre deux types d'élémentaires, 0 sinon
 */
CREATE FUNCTION elements_opposes_piece (_id_salle INT, _debut_affectaion DATETIME, _fin_affectation DATETIME) RETURNS TINYINT READS SQL DATA
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
					_debut_affectaion BETWEEN debut_affectation AND fin_affectation
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
					_debut_affectaion BETWEEN debut_affectation AND fin_affectation
					OR _fin_affectation BETWEEN debut_affectation AND fin_affectation
					OR (_debut_affectation < debut_affectation AND _fin_affectation > fin_affectation)
				)
    );
    
    RETURN _nombre_elementaires_feu > 0 AND _nombre_elementaires_eau > 0;
END $$