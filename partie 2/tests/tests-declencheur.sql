#Ceci est le document de tests pour les déclencheurs du travail de session, partie 2 en BD
#auteur : Simon Fréchette
#langage: SQL
#date: 28 avril 2022

#TODO regarder le exception handling du déclencheur 1. Faire la vérification avec 15 objets+.
#TODO regarder le fonctionnement du déclencheur 2.
#TODO vérifier l'usage de la fonction CURRENT_TIMESTAMP() pour le datetime
#STATUS déclencheur 4: testé


USE DonjonInc;

# ----------------------------------------------------------------------------------------------------------------------
# déclencheur 1
#RAPPEL
/*
* déclencheur qui vérifie après l'insertion si l'objet ajouté crée une surcharge dans le coffre dans lequel il est.
* @Dependecies: verifier_surcharge_coffre()
* @Dependencies: Ligne_coffre, Coffre_tresor, Objet
*/
# ----------------------------------------------------------------------------------------------------------------------
/*
La procédure de test vérifie si les deux conditions d'ajout sont respectées en ajoutant d'abord un objet trop lourd (305kg au total)
puis, en ajoutant au-dessus de 15 objets.
*/
DROP PROCEDURE IF EXISTS procedure_test_surcharge_coffre_masse;
DELIMITER $$
CREATE PROCEDURE procedure_test_surcharge_coffre_masse()
	BEGIN 
		DECLARE _code CHAR(5);
		DECLARE _message TEXT;
		# déclaration des gestions d'exception
        
        # exception si il contient 300kg de masse ou plus.
		DECLARE EXIT HANDLER FOR 02001
		BEGIN
			GET DIAGNOSTICS CONDITION 1
				_Code = RETURNED_SQLSTATE,
				_message= MESSAGE_TEXT;
			SELECT _code,_message;
            SELECT "coffre trop lourd !";
            ROLLBACK;
		END;
        
		# exception si il contient 15 objets ou plus.
		DECLARE EXIT HANDLER FOR 02002
		BEGIN
			GET DIAGNOSTICS CONDITION 1
				_Code = RETURNED_SQLSTATE,
				_message= MESSAGE_TEXT;
			SELECT _code,_message;
            SELECT "coffre ayant trop d'objets!";
            ROLLBACK;
		END;
                        
        START TRANSACTION;
			# création des enregistrements de test. Le coffre de test sera affilié à la salle 13 existante
			INSERT INTO Coffre_tresor(id_coffre_tresor,code_secret,salle)
			VALUES (1000,"secret",13);
			INSERT INTO Objet(id_objet,nom,valeur,masse)
			VALUES (1000,"objet initial",10,290);
			INSERT INTO Objet(id_objet,nom,valeur,masse)
			VALUES (1001,"objet de trop",10,20);
			INSERT INTO Ligne_coffre(coffre,objet,quantite)
			VALUES (1000,1000,1);
			INSERT INTO Ligne_coffre(coffre,objet,quantite)
			VALUES (1000,1001,1);

			# à l'insertion de cet objet, une exception devrait être levée. Le trigger devrait aussi être fait avant l'insertion, 
			#de sorte que l'exception rendrait la BD en "état instable" avant que l'objet fautif puisse s'insérer.
			
			# select pour vérifier. Normalement, le handler devrait empêcher ces lignes de s'éxécuter.
			SELECT Ligne_coffre.coffre, Ligne_coffre.quantite,Objet.nom,Objet.id_objet,Objet.masse FROM Ligne_coffre 
            INNER JOIN Objet ON Ligne_coffre.objet = Objet.id_objet
			WHERE coffre = 1000
			ORDER BY Ligne_coffre.objet;
            
			# mise à zéro des enregistrements de test créés:
			DELETE FROM Ligne_coffre WHERE Ligne_coffre.coffre = 1000 AND Ligne_coffre.objet = 1000;
			DELETE FROM Ligne_coffre WHERE Ligne_coffre.coffre = 1000 AND Ligne_coffre.objet = 1001;
			DELETE FROM Coffre_tresor WHERE Coffre_tresor.id_coffre_tresor = 1000;
			DELETE FROM Objet WHERE Objet.id_objet = 1000;
			DELETE FROM Objet WHERE Objet.id_objet = 1001;
		COMMIT; 
    END$$
DELIMITER ;

/*
Procédure auxiliaire pour visualiser l'état du contenu d'un coffre.
*/
DROP PROCEDURE IF EXISTS vérification_etat_coffre;
DELIMITER $$
CREATE PROCEDURE vérification_etat_coffre(IN id_coffre_a_verif INT)
BEGIN
		DECLARE _id_coffre_a_verif INT;
		DECLARE _nb_obj INT;
        DECLARE _masse_totale INT;
        
		SET _id_coffre_a_verif = (SELECT Coffre_tresor.id_coffre_tresor FROM Coffre_tresor
			WHERE Coffre_tresor.id_coffre_tresor = id_coffre_a_verif);

		SET _nb_obj = (SELECT sum(Ligne_coffre.quantite) FROM Ligne_coffre
					INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre_tresor.id_coffre_tresor
					WHERE Coffre_tresor.id_coffre_tresor = _id_coffre_a_verif);
		
		SET _masse_totale = (SELECT sum(Objet.masse * Ligne_coffre.quantite) FROM Objet
					INNER JOIN ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
					INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre_tresor.id_coffre_tresor
					WHERE Coffre_tresor.id_coffre_tresor = _id_coffre_a_verif);

		SELECT _id_coffre_a_verif,_nb_obj,_masse_totale;
END$$
DELIMITER ;


# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
#déclencheur 2
#RAPPEL
/*
* déclencheur qui vérifie si au moment d'ajouter un monstre dans un salle (affectation_salle) il y a deux éléments opposés dans la salle concernée.
*@dependencies: elements_opposes_piece()
*@dependencies: Elementaire, Monstre, Affectation_salle
*/
# ----------------------------------------------------------------------------------------------------------------------
/*
Procédure qui place volontairement deux élémentaires oppposés dans la même pièce pour tester le déclencheur.
*/
DROP PROCEDURE IF EXISTS elements_opposes_pièce_test;
DELIMITER $$
CREATE PROCEDURE elements_opposes_pièce_test()
BEGIN
	
END$$
DELIMITER ;
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# déclencheur 3
#RAPPEL
/*
* déclencheur qui devance la fin de toutes les affectations de salle reliées à un monstre mort à la date actuelle.
* @Dependencies: Monstre, Affectation_salle
*/
# ----------------------------------------------------------------------------------------------------------------------
/*
* Procédure qui affecte d'abord un monstre à une salle, qui le tue et qui vérifie le devancement de sa date de fin d'affectation.
*/
DROP PROCEDURE IF EXISTS re_affectation_mortalite_test;
DELIMITER $$
CREATE PROCEDURE re_affectation_mortalite_test()
BEGIN
    
    # création d'un monstre affecté à une famille déjà existante (la famille 1)
    INSERT INTO Monstre(id_monstre,nom,code_employe,point_vie,attaque,numero_ass_maladie,id_famille,experience)
    VALUES(1000,"monsieur test",'204A',10,1,'G4V2',1,1);
    
    # création d'une nouvelle responsabilité pour le monstre. Pour la lisibilité, le ID est à 1000.
    INSERT INTO Responsabilite(id_responsabilite,titre,niveau_responsabilite)
    VALUES (1000,"Testeur pro",1);
    
    #affectation à une salle existante (salle 1). Pour la lisibilité, le ID est à 1000.
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES(1000,1000,1000,1,'2022-04-30 15:00:00','2052-05-30 15:00:00');
    
    # mise à jour des points de vie du monstre
    UPDATE Monstre SET Monstre.point_vie = 0 WHERE Monstre.id_monstre = 1000;
    
    # À ce stade, l'affectation reliée au monstre devrait avoir changé sa date de fin pour la date actuelle.
    SELECT * FROM Affectation_salle AS resultat_dec3 WHERE id_affectation = 1000; 
    
	# suppression des données de test existantes
    DELETE FROM Affectation_salle WHERE monstre = 1000;
    DELETE FROM Monstre WHERE id_monstre = 1000;
	DELETE FROM Responsabilite WHERE id_responsabilite = 1000;
END$$
DELIMITER ;
CALL re_affectation_mortalite_test();

# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# déclencheur 4
#RAPPEL
/*
* Déclencheur qui transforme le code secret entré en clair dans un nouveau coffre en une valeur hashée.
*@dependencies: Coffre_tresor
*/
# ----------------------------------------------------------------------------------------------------------------------
/*
Procédure qui crée simplement un nouveau coffre puis qui examine le mot de passe qui aura été défini par le déclencheur après insertion pour vérifier si il est coorect.
*/
DROP PROCEDURE IF EXISTS hash_coffre_test;
DELIMITER $$
CREATE PROCEDURE hash_coffre_test()
BEGIN
	DECLARE _hash_attendu CHAR(64); # Le hash que l'on s'attend à obtenir. 
    DECLARE _hash_obtenu CHAR(64); # le hash qu'on obtiendra par le biais du trigger.
    SET _hash_attendu = SHA2("code test",256);
        
    #création du coffre de test. Il sera affilié à la salle 1.
	INSERT INTO Coffre_tresor(id_coffre_tresor,code_secret,salle)
	VALUES(1001,"code test",1);
	
    #vérification de la validité du mot de passe
    SET _hash_obtenu = (SELECT code_secret FROM Coffre_tresor WHERE id_coffre_tresor = 1001);
    IF _hash_obtenu = _hash_attendu THEN
		SELECT "Le hash a été effectué avec succès" AS resultat_dec4;
    ELSE
		SELECT "Le hash a échoué" AS resultat_dec4;
	END IF;
    
	# suppression des données de test
    DELETE FROM Coffre_tresor WHERE id_coffre_tresor = 1001;
END$$
DELIMITER ;
CALL hash_coffre_test();
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
#Appel des tests
DROP PROCEDURE IF EXISTS appel_tests_declencheurs;

DELIMITER $$
CREATE PROCEDURE appel_tests_declencheurs()
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "Une erreur est survenue lors de l'éxécution des tests des déclencheurs";
        ROLLBACK;
	END;
	START TRANSACTION;
		# -- déclencheur 1
		CALL vérification_etat_coffre(1000);

		# -- déclencheur 2
		CALL elements_opposes_pièce_test();

		# -- déclencheur 3
		CALL re_affectation_mortalite_test();

		# -- déclencheur 4
		CALL hash_coffre_test();
    COMMIT;
END$$
DELIMITER ;

# ----------------------------------------------------------------------------------------------------------------------


