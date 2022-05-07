# ceci est la version brouillon des déclencheurs pour le travail de session de
# bases de données. partie 2
# 
# Auteur: Simon Fréchette
# Langage: SQL
# Date de début: 22 avril 2022

# to do: vérifier les codes d'erreurs

USE DonjonInc;


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

DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# fonction auxiliaire (déclencheur 1)
# author Simon Fréchette


/**
 * Fonction qui vérifie qu'un seul coffre ne contient pas plus de 15 objets ou 300kg de masse totale
 * @param id_coffre_a_verif == le coffre à vérifier 
 * @return 1 si il y a une surcharge, 0 sinon
 * Si il y a une surcharge, une exception est lançée. Cette dernière interrompt le processus et rensigne l'utilisateur de l'erreur
 *(Supérieur à 300 de masse ou supérieur à 15 objets).
 * L'utilisateur doit être mis au courant de laquelle des deux contraintes n'est pas respectée.
*/
DROP FUNCTION IF EXISTS verifier_surcharge_coffre;
DELIMITER $$
CREATE FUNCTION verifier_surcharge_coffre(id_coffre_a_verif INT,masse_objet_ajoute INT, quantite_ligne_ajoutee INT) RETURNS TINYINT READS SQL DATA
BEGIN    
	DECLARE _masse_totale INT;
    DECLARE _nb_obj INT;
    
    
	SET _masse_totale = (SELECT sum(Objet.masse * Ligne_coffre.quantite) FROM Objet
						INNER JOIN Ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
						INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre_tresor.id_coffre_tresor
                        WHERE Coffre_tresor.id_coffre_tresor = id_coffre_a_verif);
	
	# on ajoute la masse totale de la ligne qui s'apprête à être ajoutée
	IF _masse_totale IS NULL THEN
		SET _masse_totale = (masse_objet_ajoute * quantite_ligne_ajoutee);
	ELSE
		SET _masse_totale = _masse_totale + (masse_objet_ajoute * quantite_ligne_ajoutee);
	END IF;

	IF _masse_totale > 300 THEN 
		SIGNAL SQLSTATE '02002'
			SET MESSAGE_TEXT = "En ajoutant un objet dans ce coffre, vous excédez la capacité totale de ce dernier (300kg)";
		RETURN 1;
	END IF;
    
    
    SET _nb_obj = (SELECT sum(Ligne_coffre.quantite) FROM Ligne_coffre
				INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre_tresor.id_coffre_tresor
                WHERE Coffre_tresor.id_coffre_tresor = id_coffre_a_verif);

	# on ajoute le nombre d'objets associé à la ligne qui s'apprête à être ajoutée
	IF _nb_obj IS NULL THEN 
		SET _nb_obj = quantite_ligne_ajoutee;
	ELSE
		SET _nb_obj = _nb_obj + quantite_ligne_ajoutee;
	END IF;

	IF _nb_obj > 15 THEN
		SIGNAL SQLSTATE '02001'
			SET MESSAGE_TEXT = "le coffre auquel vous tentez d'ajouter un objet contient déjà 15 objets.";
		RETURN 1;
	END IF; 
    	
    RETURN 0;
END$$

DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# déclencheur 1

/*
* déclencheur qui vérifie après l'insertion si la ligne ajoutée crée une surcharge dans le coffre dans lequel elle est.
* @Dependencies: verifier_surcharge_coffre()
* @Dependencies: Ligne_coffre, Coffre_tresor, Objet
*/
DROP TRIGGER IF EXISTS coffre_surcharge_nouvelle_ligne;
DELIMITER $$
CREATE TRIGGER coffre_surcharge_nouvelle_ligne BEFORE INSERT ON Ligne_coffre FOR EACH ROW
BEGIN
	DECLARE _masse_objet_a_verif INT;
    DECLARE _quantite_objet INT;
    DECLARE _etat_surcharge INT;
	SET _quantite_objet = NEW.quantite;
	SET _masse_objet_a_verif = (SELECT Objet.masse FROM Objet WHERE Objet.id_objet = NEW.objet);
	SET _etat_surcharge = verifier_surcharge_coffre(NEW.coffre,_masse_objet_a_verif,_quantite_objet); # on vérifie l'état de surcharge du coffre. Si le coffre est surchargé, une exception sera lancée dans la fonction.
END$$	

DELIMITER ;

/*
* déclencheur qui vérifie après la mise à jour d'une ligne si la quantité a été changée et que cela crée une surcharge dans le coffre dans lequel elle est.
* @Dependencies: verifier_surcharge_coffre()
* @Dependencies: Ligne_coffre, Coffre_tresor, Objet
*/
DROP TRIGGER IF EXISTS coffre_surcharge_update_ligne;
DELIMITER $$
CREATE TRIGGER coffre_surcharge_update_ligne BEFORE UPDATE ON Ligne_coffre FOR EACH ROW
BEGIN
	DECLARE _masse_objet_a_verif INT;
    DECLARE _quantite_objet INT;
    DECLARE _etat_surcharge INT;
	SET _quantite_objet = NEW.quantite-OLD.quantite;
    SET _masse_objet_a_verif = (SELECT Objet.masse FROM Objet INNER JOIN Ligne_coffre ON Ligne_coffre.objet = id_objet WHERE Ligne_coffre.objet = NEW.objet AND Ligne_coffre.coffre = NEW.coffre);
	SET _etat_surcharge = verifier_surcharge_coffre(NEW.coffre,_masse_objet_a_verif,_quantite_objet); # on vérifie l'état de surcharge du coffre. Si le coffre est surchargé, une exception sera lancée dans la fonction.
END$$	

DELIMITER ;

# ------------------------------------------------------------------------------------------------------
# déclencheur 2

DROP TRIGGER IF EXISTS elements_opposes_dans_piece;
/*
* déclencheur qui vérifie si au moment d'ajouter un monstre dans un salle (affectation_salle) il y a deux éléments opposés dans la salle concernée.
*@dependencies: elements_opposes_piece()
*@dependencies: Elementaire, Monstre, Affectation_salle
*/
DElIMITER $$
CREATE TRIGGER elements_opposes_dans_piece AFTER INSERT ON Affectation_salle FOR EACH ROW
BEGIN
	DECLARE _presence_elements_opposes TINYINT;
    DECLARE _message_exception VARCHAR(255);
    
    SET _message_exception = "Il y a deux éléments dans la même pièce !";
    SET _message_exception = CONCAT(_message_exception," (Pièce ID: ",NEW.salle," Début: ",NEW.debut_affectation," Fin: ",NEW.fin_affectation,")");
    SET _presence_elements_opposes = elements_opposes_piece(NEW.salle, NEW.debut_affectation, NEW.fin_affectation);
    
    # Si deux éléments opposés sont dans la même pièce, une exception de la classe avertissement est lancée:
    IF _presence_elements_opposes = 1 THEN
		SIGNAL SQLSTATE '40001'
			SET MESSAGE_TEXT = _message_exception;
    END IF;
END$$
DELIMITER ;

# ------------------------------------------------------------------------------------------------------
#déclencheur 3
/*
* déclencheur qui devance la fin de toutes les affectations de salle reliées à un monstre mort à la date actuelle.
* @Dependencies: Monstre, Affectation_salle
*/
DROP TRIGGER IF EXISTS re_affectation_mortalite;

DELIMITER $$
CREATE TRIGGER re_affectation_mortalite AFTER UPDATE ON Monstre FOR EACH ROW
BEGIN
    DECLARE _date_actuelle DATETIME;
    SET _date_actuelle = CURRENT_TIMESTAMP(); # pour avoir une valeur de type DATETIME correspondant à la date et à l'heure actuelle.
    
	IF NEW.point_vie <= 0 THEN
		UPDATE Affectation_salle
        SET fin_affectation = _date_actuelle
        WHERE monstre = NEW.id_monstre;
    END IF;
END$$
DELIMITER ;

# ------------------------------------------------------------------------------------------------------
#déclencheur 4
/*
* Déclencheur qui transforme le code secret entré en clair dans un nouveau coffre en une valeur hashée.
*@dependencies: Coffre_tresor
*/
DROP TRIGGER IF EXISTS hash_coffre_tresor;
DELIMITER $$
CREATE TRIGGER hash_coffre_tresor BEFORE INSERT ON Coffre_tresor FOR EACH ROW
BEGIN
	DECLARE _val_hash CHAR(64);
    SET _val_hash = SHA2(NEW.code_secret, 256);
    SET NEW.code_secret = _val_hash;
END$$
DELIMITER ;




