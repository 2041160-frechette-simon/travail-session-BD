# Ceci est le script de sélection SQL pour le travail de session par Clément Provencher et Simon Fréchette
# 
# 
#
# auteur: Simon Fréchette et Clément provencher
# date: mars 2022
# langage: SQL
# 
# 
#
# NOTE: enlever les rubriques encadrées par les commentaires "test" avant la remise
#TODO Requete h) Check la sum. Donne 8.05 pile mais MYSQL Donne 8.0500000000060...
# --------------------------------------------------------------------------------------------------------------------
USE DonjonInc;
# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete a)
SELECT Monstre.nom, Monstre.numero_ass_maladie FROM Humanoide 
INNER JOIN Famille_monstre ON Humanoide.famille = Famille_monstre.id_famille
INNER JOIN Monstre ON Monstre.id_famille = Famille_monstre.id_famille;
#-- fin requete a)
# --------------------------------------------------------------------------------------------------------------------




# --------------------------------------------------------------------------------------------------------------------
# -- requete b)
SELECT Salle.fonction,Salle.largeur*Salle.longueur AS aire FROM Salle 
ORDER BY aire DESC LIMIT 1;
#-- fin requete b)
# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete c)
SELECT Humanoide.arme FROM Humanoide 
INNER JOIN Famille_monstre ON Famille_monstre.id_famille = Humanoide.famille
INNER JOIN Monstre ON Monstre.id_famille = Famille_monstre.id_famille
WHERE Monstre.code_employe = 'A320';
#-- fin requete c)
# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete d)
SELECT Monstre.nom FROM Responsabilite 
INNER JOIN Affectation_salle ON Affectation_salle.responsabilite = Responsabilite.id_responsabilite
INNER JOIN Salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'salle des explosifs'
ORDER BY Responsabilite.niveau_responsabilite DESC
LIMIT 1;
#-- fin requete d)

# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete e)
SELECT Monstre.nom FROM Salle 
INNER JOIN Affectation_salle ON Salle.id_salle= Affectation_salle.salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'réfectoire louche' AND month(Affectation_salle.debut_affectation) BETWEEN 05 AND 07
GROUP BY Monstre.nom;
#-- fin requete e)

# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete f)
SELECT Monstre.nom FROM Expedition
INNER JOIN Visite_salle ON Expedition.id_expedition = Visite_salle.expedition
INNER JOIN Salle ON Visite_salle.salle = Salle.id_salle
INNER JOIN Affectation_salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Expedition.nom_equipe = 'girafes triomphantes'
AND Salle.fonction = 'cachot humide'
AND Visite_salle.moment_visite BETWEEN Affectation_salle.debut_affectation AND Affectation_salle.fin_affectation 
GROUP BY Affectation_salle.monstre;
#-- fin requete f)

# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete g)
SELECT Expedition.nom_equipe, count(Aventurier.id_aventurier) AS nombre_de_membres, avg(Aventurier.niveau) AS moyenne FROM Expedition_aventurier
INNER JOIN Expedition ON Expedition_aventurier.id_expedition = Expedition.id_expedition
INNER JOIN Aventurier ON Expedition_aventurier.id_aventurier = Aventurier.id_aventurier
GROUP BY Expedition_aventurier.id_expedition;
# -- fin requete g)
# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete h)
SELECT sum(ligne_coffre.quantite*Objet.masse) FROM Ligne_coffre 
INNER JOIN Objet ON Objet.id_objet = Ligne_coffre.objet
INNER JOIN Coffre_tresor ON Coffre_tresor.id_coffre_tresor = Ligne_coffre.coffre
INNER JOIN Salle ON Coffre_tresor.salle = Salle.id_salle
WHERE Salle.fonction = 'caserne des goblins'
GROUP BY Ligne_coffre.coffre;
# -- fin requete h)

# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete i)
SELECT salle_suivante_copie.fonction FROM Salle
INNER JOIN Salle AS salle_suivante_copie ON Salle.salle_suivante = Salle_suivante_copie.id_salle
WHERE Salle.fonction  = 'entree secrete - ouest';
# -- fin requete i)

# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------

# -- requete j)
SELECT sum(quantite * valeur) AS valeur_salle_objets FROM Expedition
	INNER JOIN Visite_salle ON expedition = id_expedition
    INNER JOIN Salle ON Visite_salle.salle = id_salle
    INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet
    WHERE nom_equipe = 'girafes triomphantes' AND fonction = 'salle de repos';
# -- fin requet j)
# --------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------

# -- requete k)
SELECT code_secret FROM Coffre_tresor
	WHERE code_secret RLIKE '^\\w{0,5}$' 
    OR code_secret RLIKE '^\\d+$'
    OR code_secret RLIKE 'salle';
# -- fin requete k)
# --------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------
# ici, comme il était question de sélectionner les salles, toutes les colonnes des salles ont été sélectionnées
# -- requete l)
SELECT Salle.* FROM Salle
	INNER JOIN Coffre_tresor ON Coffre_tresor.salle = id_salle
    INNER JOIN Ligne_coffre ON coffre = id_coffre_tresor
    INNER JOIN Objet ON objet = id_objet
    GROUP BY Salle
    HAVING sum(valeur * quantite) > 2000 AND salle_suivante IS NOT NULL;
# -- fin requete l)
# --------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------
# -- requete m)
SELECT nom, sum(datediff(fin_affectation, debut_affectation)) AS temps_affectation_total FROM Monstre
	INNER JOIN Affectation_salle ON monstre = id_monstre
    GROUP BY nom
    ORDER BY temps_affectation_total DESC
    LIMIT 1;
# -- fin requete m)
# --------------------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------------------
# -- requete n)
SELECT count(Visite_salle.moment_visite) AS nb_combats, nom, id_salle FROM Affectation_salle
	INNER JOIN Salle ON id_salle = Affectation_salle.salle
    INNER JOIN Visite_salle ON Salle.id_salle = Visite_salle.salle
    INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
    WHERE Visite_salle.moment_visite BETWEEN Affectation_salle.debut_affectation AND Affectation_salle.fin_affectation 
    GROUP BY Monstre.id_monstre, Salle.id_salle
    ORDER BY nb_combats, id_salle;
# -- fin requete n)
# --------------------------------------------------------------------------------------------------------------------


