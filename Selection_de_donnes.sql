# -- L’expédition des « girafes triomphantes » ont vaincu lesmonstres de la salle « salle de repos» et 
# -- récolte maintenant le trésor de la salle, calculez la valeur amassez.
SELECT sum(valeur) FROM Expedition
	INNER JOIN Visite_salle ON expedition = id_expedition
    INNER JOIN Salle ON Visite_salle.salle = id_salle
    INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet
    WHERE nom = 'girafes triomphantes' AND fonction = 'salle de repos';

# -- K   
SELECT code_secret FROM Coffre_tresor
	WHERE code_secret RLIKE '^\\d{0,5}$' 
    OR code_secret RLIKE '^\\d+$'
    OR code_secret RLIKE 'salle';
    
SELECT Salle.* FROM Salle
	INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet;