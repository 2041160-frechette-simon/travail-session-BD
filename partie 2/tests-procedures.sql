# Ceci est le script de tests pour les procédures
#Author : Clément Provencher et Simon Fréchette
#
# Date :  03/05/22
# Modification: 03/05/22
#Langage: SQL

USE DonjonInc;
#---------------------------------------------------------------------------------------------------------------------------------------
/*
Procédure de test servant à tester le bon fonctionnement de la procédure d'intimidation.
@Dependencies intimidation
*/
DROP PROCEDURE IF EXISTS Test_intimidation;
DELIMITER $$
CREATE PROCEDURE Test_intimidation()
BEGIN
	#variables de test
	DECLARE _intimidation_reussi TINYINT;
    DECLARE _intimidation_echec TINYINT;
    

	#arranger
    INSERT IGNORE INTO Expedition(id_expedition, nom_equipe)
		VALUES(1000, 'reussi'),
			  (2000, 'echec');
	
    INSERT IGNORE INTO Expedition_aventurier(id_expedition, id_aventurier)
		VALUES(1000, 7), #niveau 15
              (2000, 5), #niveau 1
              (2000, 2); #niveau 3
	
	INSERT IGNORE INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(9, 1000, '1082-05-25 00:00:00'),
			  (10, 2000, '1082-05-10 00:00:00');
			
	#agir (tester)
	CALL Intimidation(9, 1000, _intimidation_reussi);
    CALL Intimidation(10, 2000, _intimidation_echec);
    
    #affirmer
    IF(_intimidation_reussi = 0)THEN 
		SELECT "intimidation non réussie alors qu' elle aurait dù être un succès" AS resultat_proc1_intimidation_code_11_N;
	ELSE 
		SELECT "Intimidation appliquée correctement dans une situation appliquable" AS resultat_proc1_intimidation_code_11_P;
	END IF;
    
    IF(_intimidation_echec = 1)THEN 
		SELECT "intimidation réussie alors qu'elle devait avoir échoué" AS resultat_proc1_intimidation_code_12_N;
	ELSE
		SELECT "Intimidation omise correctement dans une situation appliquable" AS resultat_proc1_intimidation_code_12_P;
    END IF;
    
	#mise a zéro des enregistrements de test
    DELETE FROM Visite_salle WHERE (salle = 9 AND expedition = 1000) OR (salle = 10 AND expedition = 2000);
	DELETE FROM Expedition_aventurier WHERE (id_expedition = 1000 AND id_aventurier = 7) OR (id_expedition = 2000 AND id_aventurier = 5) OR (id_expedition = 2000 AND id_aventurier = 2);
	DELETE FROM Expedition WHERE id_expedition = 1000 OR id_expedition = 2000;
END $$
DELIMITER ;

#---------------------------------------------------------------------------------------------------------------------------------------

/*
Procédure de test servant à valider le bon fonctionnement de la procédure de malédiction d'affaiblissement
@dependencies: Malediction_affaiblissement
*/
DROP PROCEDURE IF EXISTS Test_Malediction_affaiblissement;
DELIMITER $$
CREATE PROCEDURE Test_Malediction_affaiblissement()
BEGIN
	# Mise en place des variables de test
	DECLARE _attaque_sans_malédiction_salle_9 INT;
    DECLARE _attaque_sans_malédiction_salle_10 INT;
    DECLARE _attaque_apres_malediction_salle_9 INT;
    DECLARE _attaque_apres_malediction_salle_10 INT;
        
    #insertions
    INSERT IGNORE INTO Expedition(id_expedition, nom_equipe,depart,terminaison)
    VALUES (1000, 'équipe avec mage','2081-05-25 00:00:00','2083-05-25 00:00:00'),
			(2000, 'équipe sans mage','2081-05-25 00:00:00','2083-05-25 00:00:00');
            
	INSERT IGNORE INTO Expedition_aventurier(id_expedition, id_aventurier)
    VALUES(1000, 4), # l'aventurier 4 est un mage
			(2000, 3); # l'aventurier 3 n'est pas un mage
            
	INSERT IGNORE INTO Visite_salle(salle, expedition, moment_visite)
		VALUES(9, 1000, '2082-05-25 00:00:00'), # dans la salle 9, l'expédition avec mage
			  (10, 2000, '2082-05-10 00:00:00'); # dans la salle 10, l'expédition sans mage
              
              
	INSERT IGNORE INTO Monstre(id_monstre,nom,code_employe,point_vie,attaque,numero_ass_maladie,id_famille,experience)
    VALUES 
    (1000,"monstre 1","MON1",10,10,"NUMMON1",9,0),
	(1001,"monstre 2","MON2",10,10,"NUMMON2",9,0);

	INSERT IGNORE INTO Affectation_salle(id_affectation,monstre, responsabilite,debut_affectation,fin_affectation, salle)
    VALUES
    (3000,1000, 1, '2082-04-25 00:00:00','2083-04-25 00:00:00', 9),
	(3001,1001, 1, '2082-04-25 00:00:00','2083-04-25 00:00:00', 10);
	
    # mise en place des données attendues
	SET _attaque_sans_malédiction_salle_9 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 9 AND debut_affectation < '2082-05-25 00:00:00' AND
    fin_affectation > '2082-05-25 00:00:00');
    SET _attaque_sans_malédiction_salle_10 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 10 AND debut_affectation < '2082-05-10 00:00:00' AND
    fin_affectation > '2082-05-10 00:00:00');
    
    # appel de la procédure à tester
    CALL Malediction_affaiblissement(9, 1000);
    CALL Malediction_affaiblissement(10, 2000);
        
    # mise en place des résultats reçus
    SET _attaque_apres_malediction_salle_9 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 9 AND debut_affectation < '2082-05-25 00:00:00' AND
    fin_affectation > '2082-05-25 00:00:00');
    SET _attaque_apres_malediction_salle_10 = (SELECT sum(attaque) FROM Salle INNER JOIN Affectation_salle ON id_salle = salle
    INNER JOIN Monstre ON id_monstre = monstre WHERE id_salle = 10 AND debut_affectation < '2082-05-10 00:00:00' AND
    fin_affectation > '2082-05-10 00:00:00');
        
    # affirmations
    IF(_attaque_sans_malédiction_salle_9 = _attaque_apres_malediction_salle_9)
    THEN 
		SELECT "La malediction d'affaiblissement n'a pas fonctionnée. L'affaiblissement n'a pas affecté un scénario opposant un mage et un humanoïde." AS resultat_proc2_affaiblir_code_21_N;
    ELSE 
		SELECT "La malédiction a été correctement appliquée à un scénario positif opposant un mage et un humanoide" AS resultat_proc2_affaiblir_code_21_P;
    END IF;
    
    IF(_attaque_sans_malédiction_salle_10 = _attaque_apres_malediction_salle_10)
    THEN 
		SELECT "La malédiction d'affaiblissement a été correctement appliquée à un scénario n'opposant pas un humanoide et un mage." AS resultat_proc2_affaiblir_code_22_P;
    ELSE
		SELECT "La malédiction d'affaiblissement n'a pas fonctionnée. Elle a été appliquée à tort dans un scénario sans mage." AS resultat_proc2_affaiblir_code_22_N;
	END IF;
    
	# remise à zéro des enregistrements et des modifications de test   
    DELETE FROM Affectation_salle WHERE id_affectation = 3000 OR id_affectation = 3001;
	DELETE FROM Monstre WHERE id_monstre = 1000 OR id_monstre = 1001;
	DELETE FROM Visite_salle WHERE (salle = 9 AND expedition = 1000) OR (salle = 10 AND expedition = 2000);
	DELETE FROM Expedition_aventurier WHERE (id_expedition = 1000 AND id_aventurier = 4)OR(id_expedition = 2000 AND id_aventurier = 3);
	DELETE FROM Expedition WHERE id_expedition = 1000 OR id_expedition = 2000; 
END $$
DELIMITER ;

# ---------------------------------------------------------------------------------------------------------------------------------------

/*
Procédure de test servant à valider le bon fonctionnement de la procédure de combat
@dependencies: combat, verifier_vitalite_monstre_salle, verifier_vitalite_aventurier_salle, Malediction_affaiblissement
@dependencies: infliger_dommage_aventurier, infliger_dommage_monstre, 
*/
DROP PROCEDURE IF EXISTS Test_combat;
DELIMITER $$
CREATE PROCEDURE Test_combat()
BEGIN
	# Pour tester le bon déroulement du combat nous allons établir un scénario fictif de combat et allons examiner le résultat de ce dernier (qui gagne entre les aventuriers et les monstres) par rapport au résultat attendu.
    # Cela permettra d'affirmer que le combat se déroule correctement.
    
    # déclaration des variables de test
    DECLARE _pv_finaux_monstres INT;
    DECLARE _pv_finaux_aventuriers INT;
    
    DELETE FROM Affectation_salle WHERE salle = 1; # suppression de toutes les affectations reliées à la salle 1
    
    # insertions des nouveaux monstres affectés à la salle 1. Pour tester la procédure d'affaiblissement, il y aura que des humanoides de la famille 9 parmi les monstres affectés.
    #  nom famille : Goblin	
    # p.v max. 7	
    #degats de base: 2
    
    INSERT IGNORE INTO Monstre(id_monstre,nom,code_employe,point_vie,attaque,numero_ass_maladie,id_famille,experience)
    VALUES
    (3000,"humanoide de test 1","HU01",5,5,"NUMHASH1",9,0),
	(3001,"humanoide de test 2","HU02",5,5,"NUMHASH2",9,0);
    
	# dans le cadre du test, la responsabilite sera la même pour tous les monstres. 
    INSERT IGNORE INTO Responsabilite(id_responsabilite, titre, niveau_responsabilite)
    VALUES (4000,"combattant de test",1);
    
    #affectations des monstres à la salle
    INSERT IGNORE INTO affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES
    (5000,3000,4000,1,'1082-01-01 00:00:00','1082-01-10 00:00:00'),
    (5001,3001,4000,1, '1082-01-01 00:00:00','1082-01-10 00:00:00');
    
    #création de l'expédition de test
    INSERT IGNORE INTO Expedition(id_expedition,nom_equipe,depart,terminaison)
    VALUES (6000,"L'expédition de tests de combats",'1082-01-01 00:00:00','1082-01-10 00:00:00');
    
    # création des aventuriers de test
    INSERT IGNORE INTO Aventurier(id_aventurier,nom,classe,niveau,point_vie,attaque) 
    VALUES
    (7000,"le mage affaiblisseur","mage",1,5,5),
    (7001, "l'acolyte incompétent","spectateur",1,3,2);
    
    # mise en place de l'expédition
    INSERT IGNORE INTO Expedition_aventurier(id_expedition,id_aventurier)
    VALUES
    (6000,7000),
    (6000,7001);
    
    # enregistrement manuel de la visite de la salle par l'équipe d'expédition
    INSERT IGNORE INTO Visite_salle(salle,expedition, moment_visite,appreciation)
    VALUES
    (1,6000,'1082-01-03 00:00:00',"à saveur de test");
    
    # initiation du combat 
    CALL Combat(1,6000);

    # comparaison avec les résultats attendus.
    # RAPPEL: chaque monstre doit être affaibli par le mage à tous les tours (tous les monstres sont humanoïdes)
    # donc, le combat se déroulera comme suit:
    
    # ----- TOUR 1
    
    # le mage et son acolyte attaqueront -- 
    # les dégâts totaux s'élèvent à 7
    # en moyenne, chaque monstre se voit donc infligé 4 (3.5 arrondi à la hausse - division entère)
    
    # Les monstres auront les P.V suivants --
    # Monstre 1 : 5-4 == 1
	# Monstre 2 : 5-4 == 1

    # le mage lancera sa malédiction --
    # les deux humanoides auront des dégâts de 4 (5-1)
    
    # les humanoides attaqueront
    # les dégâts totaux s'élèvent à 8
    # en moyenne, chaque aventurier se voit donc infligé 4 points de dégâts.
    
	# Les aventuriers auront les P.V suivants --
    # mage  : 5 - 4 == 1
	# acolyte : 3 -4 == -1     -- L'ACOLYTE MEURT
	
	# ----- FIN TOUR 1
    
	# ----- TOUR 2
    
	# le mage et son acolyte attaqueront -- 
    # les dégâts totaux s'élèvent à 5. L'acolyte est mort, il ne peut plus attaquer
    # en moyenne, chaque monstre se voit donc infligé 3 (2.5 arrondi à la hausse)
    
	# Les monstres auront les P.V suivants --
    # Monstre 1 : 2-3 == -1 -- LE MONSTRE 1 MEURT
	# Monstre 2 : 2-3 == -1 -- LE MONSTRE 2 MEURT
    
	# le mage ne LANCERA PAS sa malédiction (il n'y a aucun monstre en vie) --
	#les humanoides n'attaquent PAS, ils sont tous morts
    
	# ----- FIN TOUR 2
    
    # comme tous les monstres sont morts, la boucle de combat se termine.
	
    # vérification de l'état attendu des monstres et des aventuriers
    
    #monstres
    SET _pv_finaux_monstres = (SELECT sum(Monstre.point_vie) FROM Monstre 
		INNER JOIN Affectation_salle ON id_monstre = monstre
		INNER JOIN Salle ON salle = id_salle
        WHERE Salle.id_salle = 1);
        
	#aventuriers
	SET _pv_finaux_aventuriers = (SELECT sum(Aventurier.point_vie) FROM Aventurier 
		INNER JOIN Expedition_aventurier ON Expedition_aventurier.id_aventurier = Aventurier.id_aventurier
        WHERE id_expedition = 6000);
        
    IF _pv_finaux_monstres <=0 THEN
        SELECT "Les points de vie finaux ont été correctement assignés pour les monstres." AS resultat_proc3_combat_code_31_P;
	ELSE
        SELECT "Les points de vie finaux des monstres sont supérieurs à zéro à tort." AS resultat_proc3_combat_code_31_N;
	END IF;
    
	IF _pv_finaux_aventuriers >= 0 THEN
        SELECT "Les points de vie finaux ont été correctement assignés pour les aventuriers." AS resultat_proc3_combat_code_32_P;
	ELSE
        SELECT "Les points de vie finaux des aventuriers sont supérieurs à zéro à tort." AS resultat_proc3_combat_code_32_N;
	END IF;
    
    #reconstruction des affectations de la salle 1.
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES 
    (1,11,1,1,'1082-06-26 04:00:00','1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
    
    # remise à zéro des enregistrements et des modifications de test
    DELETE FROM visite_salle WHERE salle = 1 AND expedition = 6000 AND moment_visite = '1082-01-03 00:00:00' AND appreciation = "à saveur de test";
	DELETE FROM Expedition_aventurier WHERE (id_expedition = 6000 AND id_aventurier = 7000) OR (id_expedition = 6000 AND id_aventurier = 7001);
	DELETE FROM Aventurier WHERE id_aventurier = 7000 OR id_aventurier = 7001;
	DELETE FROM Expedition WHERE id_expedition = 6000;
	DELETE FROM affectation_salle WHERE id_affectation = 5000 OR id_affectation = 5001;
	DELETE FROM Responsabilite WHERE id_responsabilite = 4000;
	DELETE FROM Monstre WHERE id_monstre = 3000 OR id_monstre = 3001;
END $$
DELIMITER ;

/*
Procédure de test servant à valider le bon fonctionnement de la procédure de visite
 @dependencies : visite_salle, initimidation, piller_salle
*/
DROP PROCEDURE IF EXISTS Test_visite_salle;
DELIMITER $$
CREATE PROCEDURE Test_visite_salle()
BEGIN
	# la procédure de visite visite_salle détermine le comportement d'un groupe d'aventuriers qui visitent une salle.ALTERDans cette procédure, nous n'évalueront
    # pas le combat engendré par la visite. c'est une logique qui est déjà évaluée à l'intérieur de la procédure de test pour combats. 
    #De plus, nous assumeront que la procédure intimidation fonctionne correctement. Elle a été testée dans une autre procédure de test.
    
    # Donc, nous allons d'abord tenter de faire visiter une salle à un moment qui ne correspond pas à l'itinéraire de l'équipe concernée. Si le test est concluant, une exception devrait être levée. Elle est gérée directement dans la fonction.
    #Puis, nous allons faire en sorte que l'équipe d'aventuriers visite duement la salle, puis initmide les monstres qui s'y trouvent. Si le test est concluant, la procédure de pillage devrait alors immédiatement avoir lieu. 
    #Sinon, un combat sera lancé et les aventuriers prériront, empêchant ansi le pillage et déclarant le test non concluant.
	    
	DELETE FROM Affectation_salle WHERE salle = 1; # suppression de toutes les affectations reliées à la salle 1
    
	# insertions des nouveaux monstres affectés à la salle 1. Pour tester la procédure de visite, il n'y aura que des humanoides de la famille 9 parmi les monstres affectés.
    #  nom famille : Goblin	
    # p.v max. 7	
    #degats de base: 2
    
    INSERT IGNORE INTO Monstre(id_monstre,nom,code_employe,point_vie,attaque,numero_ass_maladie,id_famille,experience)
    VALUES
    (3000,"humanoide de test 1","HU01",5,20,"NUMHASH1",9,0),
	(3001,"humanoide de test 2","HU02",5,20,"NUMHASH2",9,0);
    
	# dans le cadre du test, la responsabilite sera la même pour tous les monstres. 
    INSERT IGNORE INTO Responsabilite(id_responsabilite, titre, niveau_responsabilite)
    VALUES (4000,"combattant de test",1);
    
    #affectations des monstres à la salle
    INSERT IGNORE INTO affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES
    (5000,3000,4000,1,'1082-01-01 00:00:00','1082-01-10 00:00:00'),
    (5001,3001,4000,1, '1082-01-01 00:00:00','1082-01-10 00:00:00');
    
    #création de l'expédition de test
    INSERT IGNORE INTO Expedition(id_expedition,nom_equipe,depart,terminaison)
    VALUES (6000,"L'expédition de tests de combats",'1082-01-01 00:00:00','1082-01-10 00:00:00');
    
    # création des aventuriers de test
    INSERT IGNORE INTO Aventurier(id_aventurier,nom,classe,niveau,point_vie,attaque) 
    VALUES
    (7000,"le mage affaiblisseur","mage",10,1,5),
    (7001, "l'acolyte incompétent","spectateur",10,1,2);
    
    # mise en place de l'expédition
    INSERT IGNORE INTO Expedition_aventurier(id_expedition,id_aventurier)
    VALUES
    (6000,7000),
    (6000,7001);
    
    # initiation de la visite 
    
    # visite en dehors de l'itinéraire. Une exception devrait être levée et traitée dans la fonction.
    CALL visite_salle(1,6000,'2022-02-02 00:00:00');
    
    # visite normale. L'intimidation devrait permettre aux aventuriers de piller.
	CALL visite_salle(1,6000,'1082-01-03 00:00:00');
    
    #reconstruction des affectations de la salle 1.
    INSERT INTO Affectation_salle(id_affectation,monstre,responsabilite,salle,debut_affectation,fin_affectation)
    VALUES 
    (1,11,1,1,'1082-06-26 04:00:00','1082-08-06 12:00:00'),
	(2,15,2,1,'1082-06-07 04:45:00','1082-08-22 00:45:00'),
	(39,17,11,1,'1082-09-02 16:45:00','1082-11-28 12:30:00'),
	(40,18,11,1,'1082-08-27 08:30:00','1082-11-20 20:00:00');
    
    # remise à zéro des enregistrements et des modifications de test
    DELETE FROM Expedition_aventurier WHERE (id_expedition = 6000 AND id_aventurier = 7000) OR (id_expedition = 6000 AND id_aventurier = 7001);
	DELETE FROM Aventurier WHERE id_aventurier = 7000 OR id_aventurier = 7001;
	DELETE FROM Visite_salle WHERE salle = 1 AND expedition = 6000;
	DELETE FROM Expedition WHERE id_expedition = 6000;
	DELETE FROM affectation_salle WHERE id_affectation = 5000 OR id_affectation = 5001;
	DELETE FROM Responsabilite WHERE id_responsabilite = 4000;
	DELETE FROM Monstre WHERE id_monstre = 3000 OR id_monstre = 3001;
END $$
DELIMITER ;

/*
Procédure de test servant à valider le bon fonctionnement de la procédure d'embauche
 @dependencies : embauche
*/
DROP PROCEDURE IF EXISTS Test_embauche;
DELIMITER $$
CREATE PROCEDURE Test_embauche()
BEGIN
    #début de la transaction de test
	# embauche d'un monstre à l'aide d'une famille inexistante.
    CALL embauche("gars mêlé",'MELE',"ASS-MAL","famille inexistante");
    # normalement, une exception devrait être levée, traitée et affichée à l'utilisateur.
    
    # embauche d'un monstre à l'intérieur d'une famille existante
	CALL embauche("gars pas mêlé",'MELE',"ASS-MAL","Goblin");
    
    IF (SELECT Monstre.nom FROM Monstre WHERE nom = "gars pas mêlé") = "gars pas mêlé" THEN
		SELECT "l'embauche d'un monstre a réussi" AS resultat_proc5_code_51_P;
	ELSE
		SELECT "L'embauche d'un monstre a échoué." AS resultat_proc5_code_51_N;
    END IF;
    
    #suppression des données de test
    DELETE FROM Monstre WHERE nom = "gars pas mêlé" OR nom = "gars mêlé";
END $$
DELIMITER ;

/*
Procédure de test servant à valider le bon fonctionnement de la procédure de création de famille de mort-vivants.
 @dependencies : creation_famille_mort_vivants
*/
DROP PROCEDURE IF EXISTS Test_creation_famille_mort_vivants;
DELIMITER $$
CREATE PROCEDURE Test_creation_famille_mort_vivants()
BEGIN    
	# tentative de création de famille avec un nom qui existe déjà
    CALL Creation_famille_mort_vivants("Goblin",5,2,1,0);
    # une exception devrait être levée et traitée par la fonction.
    
    # tentative de création de famille avec des P.V max. de 0
	CALL Creation_famille_mort_vivants("Testeurs du Roi Liche",0,2,1,0);
	# une exception devrait être levée et traitée par la fonction.
    
    # tentative de création de famille avec des renseignements nuls
	CALL Creation_famille_mort_vivants("Testeurs du Roi Liche",5,null,null,null);
	# une exception devrait être levée et traitée par la fonction.
    
    # création d'une famille avec des renseignements valides
    CALL Creation_famille_mort_vivants("Famille plausible",5,5,5,5);
    
    # vérifications de l'existance de la famille plausible
    IF (SELECT Famille_monstre.nom_famille FROM Famille_monstre WHERE nom_famille = "Famille plausible") IS NOT NULL THEN
		SELECT "La famille a pu être ajoutée avec succès."AS resultat_proc6_code_61_P;
	ELSE
		SELECT "La famille n'a pas été ajoutée."AS resultat_proc6_code_61_N;
    END IF;
    
    # suppression des données de test
    DELETE FROM Mort_vivant WHERE famille = (SELECT Famille_monstre.id_famille FROM Famille_monstre WHERE nom_famille = "Famille plausible");
    DELETE FROM famille_monstre WHERE nom_famille = "Famille plausible";
END $$
DELIMITER ;

# --------------------------------------------------------------------------------
#appel des procédures de test
DROP PROCEDURE IF EXISTS appel_tests;
DELIMITER $$
CREATE PROCEDURE appel_tests()
BEGIN        
	CALL Test_intimidation();
	CALL Test_Malediction_affaiblissement();
	CALL Test_combat();
	CALL Test_visite_salle();
	CALL Test_embauche();
	CALL Test_creation_famille_mort_vivants();
END$$
DELIMITER ;
CALL appel_tests();
# --------------------------------------------------------------------------------

