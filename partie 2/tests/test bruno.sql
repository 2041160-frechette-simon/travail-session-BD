USE DonjonInc;
DELIMITER $$
DROP PROCEDURE IF EXISTS test;
CREATE PROCEDURE test()
BEGIN 

	# mise à zéro des enregistrements de test créés:
	DELETE FROM Ligne_coffre WHERE Ligne_coffre.coffre = 1000 AND Ligne_coffre.objet = 1000;
	DELETE FROM Coffre_tresor WHERE Coffre_tresor.id_coffre_tresor = 1000;
	DELETE FROM Objet WHERE Objet.id_objet = 1000;
    
			# création des enregistrements de test. Le coffre de test sera affilié à la salle 13 existante
		INSERT INTO Coffre_tresor(id_coffre_tresor,code_secret,salle)
		VALUES (1000,"secret",13);
		INSERT INTO Objet(id_objet,nom,valeur,masse)
		VALUES (1000,"objet initial",10,290);
		INSERT INTO Ligne_coffre(coffre,objet,quantite)
		VALUES (1000,1000,1);
        
	SELECT sum(Objet.masse * Ligne_coffre.quantite) FROM Objet
						INNER JOIN Ligne_coffre ON Objet.id_objet = Ligne_coffre.objet
						INNER JOIN Coffre_tresor ON Ligne_coffre.coffre = Coffre_tresor.id_coffre_tresor
                        WHERE Coffre_tresor.id_coffre_tresor = 1000;
END$$
DELIMITER ;
 ## 
CALL test();

