# ceci est la version brouillon des déclencheurs pour le travail de session de
# bases de données. partie 2
# 
# Auteur: Simon Fréchette
# Langage: SQL
# Date de début: 22 avril 2022

# to do: vérifier les codes d'erreurs


# ------------------------------------------------------------------------------------------------------
# fonction de soutien (déclencheur 2)
# author Alexandre Ouellet 

DROP FUNCTION IF EXISTS elements_opposes_piece;

DELIMITER $$


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


DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# fonction auxiliaire (déclencheur 1)
# author Simon Fréchette


/**
 * Fonction qui vérifie qu'un seul coffre ne contient pas plus de 15 objets ou 300kg de masse totale
 * @param id_coffre_a_verif == le coffre à vérifier 
 * @return 1 si il y a une surcharge, 0 sinon
*/
DROP FUNCTION IF EXISTS verifier_surcharge_coffre;
DELIMITER $$
CREATE FUNCTION verifier_surcharge_coffre(id_coffre_a_verif INT) RETURNS TINYINT READS SQL DATA
BEGIN
	DECLARE masse_totale FLOAT;
    DECLARE nb_obj INT;
    SET nb_obj = (SELECT count(Objet.id_objet) FROM Objet 
				INNER JOIN ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
				INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre.id_coffre_tresor
                WHERE Coffre_tresor.id_coffre_tresor = id_coffre_a_verif
                GROUP BY Coffre_tresor.id_coffre_tresor);
	IF nb_obj > 15 THEN
		RETURN 1;
	END IF;
    
	SET masse_totale = (SELECT sum(Objet.masse * Ligne_coffre.quantite) FROM Objet
						INNER JOIN ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
						INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre.id_coffre_tresor
                        WHERE Coffre_tresor.id_coffre_tresor = id_coffre_a_verif
                        GROUP BY Coffre_tresor.id_coffre_tresor);
	IF masse_totale > 300 THEN 
		RETURN 1;
	END IF;
    RETURN 0;
	
END$$

DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# déclencheur 1

/*
* déclencheur qui vérifie après l'insertion si l'objt ajouté crée une surcharge dans le coffre dans lequel il est.
*/
DROP TRIGGER IF EXISTS coffre_surcharge;
DELIMITER $$
CREATE TRIGGER coffre_surcharge AFTER INSERT ON Objet FOR EACH ROW
BEGIN
	DECLARE id_coffre_a_verif INT;
    
    DECLARE CONTINUE HANDLER FOR 02001
	BEGIN 
	# il s'agit de l'avertissement levé en cas de surcharge. On envoit simplement un message à l'écran
	SET MESSAGE_TEXT = CONCAT(MESSAGE_TEXT," (ID coffre : ",id_coffre_a_verif,")");
	END;
    
	SET id_coffre_a_verif = (SELECT Coffre_tresor.id_coffre_tresor FROM Objet
							INNER JOIN ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
							INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre.id_coffre_tresor
                            WHERE Objet.id_objet = NEW.id_objet);
	
	IF verifier_surcharge_coffre(id_coffre_a_verif) =  1 THEN 
		SIGNAL SQLSTATE '02001'
        SET MESSAGE_TEXT = "Le coffre auquel vous venez d'Ajouter un objet est en surcharge";
	END IF;
END$$	

DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# déclencheur 2

DROP TRIGGER IF EXISTS elements_opposes_dans_piece;
/*
* déclencheur qui vérifie si au moment d'ajouter un monstre dans un salle (affectation_salle) il y a deux éléments opposés dans la salle concernée
*/
DElIMITER $$
CREATE TRIGGER elements_opposes_dans_piece AFTER INSERT ON Affectation_salle FOR EACH ROW
BEGIN
	DECLARE presence_elements_opposes TINYINT;
    DECLARE CONTINUE HANDLER FOR 02001
    BEGIN
		SET MESSAGE_TEXT = concat(MESSAGE_TEXT, " (Pièce ID: ",NEW.salle," Début: ",NEW.debut_affectation," Fin: ",NEW.fin_affectation,")");
    END;
    
    SET presence_elements_opposes = elements_opposes_piece(NEW.salle, NEW.debut_affectation, NEW.fin_affectation);
    IF presence_elements_opposes > 0 THEN
		SIGNAL SQLSTATE '02001';
        SET MESSAGE_TEXT = "Il y a deux élémentaires opposés dans la même pièce !";
    END IF;
END$$
DELIMITER ;

# ------------------------------------------------------------------------------------------------------
#déclencheur 3

/*
* déclencheur qui devance la fin de toutes les affectations de salle reliées à un monstre mort à la date actuelle.
*/

DROP TRIGGER IF EXISTS re_affectation_mortalite;
DELIMITER $$
CREATE TRIGGER re_affectation_mortalite AFTER UPDATE ON Monstre FOR EACH ROW
BEGIN
	DECLARE id_affectation_salle_monstre INT;
    DECLARE date_actuelle DATETIME;
    SET date_actuelle = GETDATE();
    SET  id_affectation_salle_monstre = (SELECT Affectation_salle.id_affectation FROM Affectation_salle
										WHERE Affectation_salle.monstre = OLD.id_monstre
    );
    
	IF NEW.point_vie <= 0 THEN
		UPDATE Affectation_salle
        SET fin_affectation = date_actuelle
        WHERE id_affectation = id_affectation_salle_monstre;
    END IF;
END$$
DELIMITER ;

# ------------------------------------------------------------------------------------------------------
#déclencheur 4
/*
* Déclencheur qui transforme le code secret entré en clair dans un nouveau coffre en une valeur hashée.
*/
DROP TRIGGER IF EXISTS hash_coffre_tresor;
DELIMITER $$
CREATE TRIGGER hash_coffre_tresor AFTER INSERT ON Coffre_tresor FOR EACH ROW
BEGIN
	DECLARE Val_hash CHAR(64);
    SET Val_hash = SHA2(NEW.code_secret, 256);
    UPDATE Coffre_tresor 
    SET Coffre_tresor.code_secret = val_hash
    WHERE Coffre_tresor.id_coffre_tresor = NEW.id_coffre_tresor;
END$$
DELIMITER ;




