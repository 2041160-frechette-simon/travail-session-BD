# Ceci est une version BROUILLON des fonctions 1 à 6 de la section C
# 
# AUTHOR : Simon Fréchette
# langage : SQL 
# date de début : 19 avril 2022

USE DonjonInc;

# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 1
/*
 fonction qui crypte en utilisant le mot de passe mortauxheros.
 @param chaine_a_crypter TEXT
 @return valeur cryptée BLOB
*/
DROP FUNCTION IF EXISTS crypter_data;
DELIMITER $$
CREATE FUNCTION crypter_data(chaine_a_crypter TEXT) RETURNS BLOB DETERMINISTIC CONTAINS SQL
BEGIN
	RETURN AES_ENCRYPT(chaine_a_crypter, UNHEX(SHA2('mortauxheros',256)));
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 2
/*
Cette fonction décrypte un contenu crypté en utilisant la clé de cryptage définie ci-dessus. Elle 
retourne le texte clair prêt à être lu par un être humain.
@param chaine_a_decrypter BLOB
@return valeur en clair TEXT
*/
DROP FUNCTION IF EXISTS decrypter_data;
DELIMITER $$
CREATE FUNCTION decrypter_data(chaine_a_decrypter BLOB) RETURNS TEXT DETERMINISTIC CONTAINS SQL
BEGIN
	RETURN CAST(AES_DECRYPT(chaine_a_decrypter, UNHEX(SHA2('mortauxheros', 256))) AS CHAR);
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 3
/*
Cette fonction accepte une fonction d’une salle et un objet de type DATETIME et retourne l’identifiant 
du monstre qui en est responsable (plus haut niveau de responsabilité).
@param fonction_salle VARCHAR(255)
@param  date_a_verif DATETIME 
@return id du responsable
*/
DROP FUNCTION IF EXISTS trouver_responsable_salle;
DELIMITER $$
CREATE FUNCTION trouver_responsable_salle(fonction_salle VARCHAR(255),date_a_verif DATETIME) RETURNS INT NOT DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE _id_monstre_responsable INT;
    DECLARE _fonction_salle_existante VARCHAR(255);
    DECLARE _nombre_affectations INT;
    
    SET _fonction_salle_existante = (SELECT Salle.fonction FROM Salle WHERE Salle.fonction = fonction_salle);
    
    IF _fonction_salle_existante <> fonction_salle THEN
		SIGNAL SQLSTATE '01002'
			SET MESSAGE_TEXT = "La salle dont vous tentez de trouver le responsable n'existe pas.";
		RETURN 0;
    END IF;
    
    # si il n'y a aucune salle d'affectée, le count retournera 0
    SET _nombre_affectations = (SELECT count(Affectation_salle.id_affectation) FROM Salle INNER JOIN Affectation_salle ON Salle.id_salle = Affectation_salle.salle WHERE salle.fonction = _fonction_salle_existante);
    
	IF _nombre_affectations =0 THEN 
		SIGNAL SQLSTATE '01001'
			SET MESSAGE_TEXT = "Il n'y a aucun responsable dans la salle choisie au moment fourni.";
	END IF;
    
    SET _id_monstre_responsable = (SELECT Affectation_salle.monstre FROM Responsabilite
			INNER JOIN Affectation_salle ON Responsabilite.id_responsabilite = Affectation_salle.responsabilite
            INNER JOIN Salle ON Affectation_salle.salle = Salle.id_salle
			WHERE Salle.fonction = fonction_salle AND date_a_verif BETWEEN 	Affectation_salle.debut_affectation AND Affectation_salle.fin_affectation
            ORDER BY Responsabilite.niveau_responsabilite DESC
			LIMIT 1);
            

	RETURN  _id_monstre_responsable;
END$$
DELIMITER ; 
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
#fonction 4
/*
La fonction retourne l’aventurier qui possède le plus haut niveau dans l’expédition.
@param nom_expedition VARCHAR(255)
@return id de l'aventurier de plus haut niveau.
*/
DROP FUNCTION IF EXISTS plus_haut_niveau_expedition;
DELIMITER $$
CREATE FUNCTION plus_haut_niveau_expedition(nom_expedition VARCHAR(255)) RETURNS INT NOT DETERMINISTIC READS SQL DATA
BEGIN
	RETURN (SELECT Aventurier.id_aventurier FROM Aventurier
			INNER JOIN Expedition_aventurier  ON Aventurier.id_aventurier = Expedition_aventurier.id_aventurier
			INNER JOIN Expedition ON Expedition_aventurier.id_expedition = Expedition.id_expedition
			WHERE Expedition.nom_equipe = nom_expedition
			ORDER BY Aventurier.niveau DESC
			LIMIT 1
	);
END $$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 5
/*
La fonction vérifie si au moins un monstre est en vie dans une salle donnée. Un monstre vivant possède un 
nombre de points de vie strictement plus grand que 0. Si la vérification s’effectue sur une salle qui 
n’est pas dans la BD ou qu’aucun monstre n’est affecté à la date demandée, une erreur est lancée.
@param id_salle INT
@param date_a_verif DATETIME
@return 0 si tous les monstres sont morts, 1 sinon.
*/
DROP FUNCTION IF EXISTS verifier_vitalite_monstre_salle ;
DELIMITER $$
CREATE FUNCTION verifier_vitalite_monstre_salle(id_salle INT,date_a_verif DATETIME) RETURNS INT NOT DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE _nb_monstres_en_vie_dans_salle INT;
    DECLARE nb_monstres_affectés INT;
	DECLARE _salle_existe INT; # null si la salle n'existe pas.
	
	SET _salle_existe = (SELECT Salle.id_salle FROM Salle
						WHERE Salle.id_salle = id_salle);
	SET nb_monstres_affectés = (SELECT count(Affectation_salle.monstre) FROM Affectation_salle
                                        WHERE Affectation_salle.salle = id_salle AND date_a_verif BETWEEN Affectation_salle.debut_affectation AND Affectation_salle.fin_affectation);

	IF _salle_existe IS NULL THEN 
		SIGNAL SQLSTATE '02001' SET MESSAGE_TEXT = "La salle dont vous tentez de vérifier la vitalité n'existe pas";
	END IF;
    
    IF nb_monstres_affectés <=0 THEN
				SIGNAL SQLSTATE '02002' SET MESSAGE_TEXT = "La salle dont vous tentez de vérifier la vitalité n'a aucun monstre d'affecté au moment fourni.";
    END IF;
	
# si aucun code d'eRReur n'a été levé, le code se poursuit

	SET _nb_monstres_en_vie_dans_salle = (SELECT count(Monstre.id_monstre) FROM Monstre
										INNER JOIN Affectation_salle ON Monstre.id_monstre = Affectation_salle.monstre
										INNER JOIN Salle ON Affectation_salle.salle = Salle.id_salle
										WHERE Salle.id_salle = id_salle AND Monstre.point_vie > 0 AND date_a_verif BETWEEN Affectation_salle.debut_affectation AND Affectation_salle.fin_affectation
										GROUP BY Salle.id_salle);
	
	IF _nb_monstres_en_vie_dans_salle > 0 THEN
		RETURN 1;
	END IF;
	RETURN 0;
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------------
# fonction 6
/*
La fonction vérifie si un aventurier est en vie dans une expédition donnée. Un aventurier vivant 
possède un nombre de points de vie strictement plus grand que 0. Si la vérification s’effectue sur une 
expédition qui n’est pas dans la BD, une erreur est lancée.
@param id_expedition INT
@return 0 si tous les aventuriers sont morts, 1 sinon.
*/
DROP FUNCTION IF EXISTS verifier_vitalite_aventurier_expedition;
DELIMITER $$
CREATE FUNCTION verifier_vitalite_aventurier_expedition(id_expedition INT) RETURNS INT NOT DETERMINISTIC READS SQL DATA
BEGIN
	DECLARE _nombre_aventuriers_vivant INT;
    DECLARE _expedition_existe INT; # null si elle n'existe pas, 1 sinon.
    
	
    SET _expedition_existe = (SELECT Expedition_aventurier.id_expedition FROM Expedition_aventurier 
								WHERE Expedition_aventurier.id_expedition = id_expedition
                                );
	
    IF _expedition_existe IS NULL THEN
		SIGNAL SQLSTATE '02001'
		SET MESSAGE_TEXT = "l'expédition dont vous tentez de vérifier la vitalité n'existe pas";
    END IF;
    
	# si aucune erreur n'est lancée, le code se poursuit
	SET _nombre_aventuriers_vivant = (SELECT count(Aventurier.id_aventurier) FROM Aventurier
									INNER JOIN 	Expedition_aventurier ON Aventurier.id_aventurier = Expedition_aventurier.id_aventurier
									INNER JOIN Expedition ON Expedition_aventurier.id_expedition = Expedition.id_expedition
									WHERE Expedition.id_expedition = id_expedition AND Aventurier.point_vie > 0
									GROUP BY Expedition.id_expedition);
                                    
	IF _nombre_aventuriers_vivant > 0 THEN
		RETURN 1;
    END IF;
	RETURN 0;
END$$
DELIMITER ;
# ---------------------------------------------------------------------------------------------------------------------------

