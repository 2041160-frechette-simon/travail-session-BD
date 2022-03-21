# -- J
SELECT sum(quantite * valeur) AS valeur_salle_objets FROM Expedition
	INNER JOIN Visite_salle ON expedition = id_expedition
    INNER JOIN Salle ON Visite_salle.salle = id_salle
    INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet
    WHERE nom_equipe = 'girafes triomphantes' AND fonction = 'salle de repos';

# -- K   
SELECT code_secret FROM Coffre_tresor
	WHERE code_secret RLIKE '^\\w{0,5}$' 
    OR code_secret RLIKE '^\\d+$'
    OR code_secret RLIKE 'salle';
    
# -- L
SELECT Salle.* FROM Salle
	INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet
    GROUP BY Salle
    HAVING sum(valeur * quantite) > 2000 AND salle_suivante IS NOT NULL;
    
# -- M
SELECT nom, sum(datediff(fin_affectation, debut_affectation)) AS temps_affectation_total FROM Monstre
	INNER JOIN Affectation_salle ON monstre = id_monstre
    GROUP BY nom
    ORDER BY temps_affectation_total DESC
    LIMIT 1;
    
# -- N
SELECT count(moment_visite BETWEEN debut_affectation AND fin_affectation) AS nb_combats, nom FROM Affectation_salle
	INNER JOIN Salle ON id_salle = Affectation_salle.salle
    INNER JOIN Visite_salle ON id_salle = Visite_salle.salle
    INNER JOIN Monstre ON monstre = id_monstre
    GROUP BY monstre
    ORDER BY nb_combats;