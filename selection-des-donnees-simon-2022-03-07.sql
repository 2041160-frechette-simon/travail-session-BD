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
#
# --------------------------------------------------------------------------------------------------------------------
USE DonjonInc;
# --------------------------------------------------------------------------------------------------------------------
# -- test
SELECT * FROM Humanoide;
# -- fin test

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
# -- test
SELECT * FROM Humanoide;

SELECT Monstre.code_employe, Humanoide.arme FROM Humanoide 
INNER JOIN Famille_monstre ON Famille_monstre.id_famille = Humanoide.famille
INNER JOIN Monstre ON Monstre.id_famille = Famille_monstre.id_famille
WHERE Monstre.code_employe = 'A320';
# -- fin test

# -- requete c)
SELECT Humanoide.arme FROM Humanoide 
INNER JOIN Famille_monstre ON Famille_monstre.id_famille = Humanoide.famille
INNER JOIN Monstre ON Monstre.id_famille = Famille_monstre.id_famille
WHERE Monstre.code_employe = 'A320';
#-- fin requete c)
# --------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------

# -- test
SELECT Monstre.nom, Affectation_salle.responsabilite, Salle.fonction FROM Responsabilite 
INNER JOIN Affectation_salle ON Affectation_salle.responsabilite = Responsabilite.id_responsabilite
INNER JOIN Salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'salle des explosifs'
ORDER BY Responsabilite.niveau_responsabilite
LIMIT 1;
# -- fin test

# -- requete d)
SELECT Monstre.nom FROM Responsabilite 
INNER JOIN Affectation_salle ON Affectation_salle.responsabilite = Responsabilite.id_responsabilite
INNER JOIN Salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'salle des explosifs'
ORDER BY Responsabilite.niveau_responsabilite
LIMIT 1;
#-- fin requete d)

# --------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------

# -- test
SELECT Monstre.nom, Salle.fonction, Affectation_salle.debut_affectation FROM Salle 
INNER JOIN Affectation_salle ON Salle.id_salle= Affectation_salle.salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'réfectoire louche' AND month(Affectation_salle.debut_affectation) BETWEEN 05 AND 07;
# -- fin test

# -- requete e)
SELECT Monstre.nom FROM Salle 
INNER JOIN Affectation_salle ON Salle.id_salle= Affectation_salle.salle
INNER JOIN Monstre ON Affectation_salle.monstre = Monstre.id_monstre
WHERE Salle.fonction = 'réfectoire louche' AND month(Affectation_salle.debut_affectation) BETWEEN 05 AND 07
GROUP BY Monstre.nom;
#-- fin requete e)

# --------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------

# -- test
SELECT Monstre.nom, Salle.fonction, Expedition.nom_equipe, Visite_salle.moment_visite, Expedition.depart, Expedition.terminaison FROM Expedition 
INNER JOIN Visite_salle ON Expedition.id_expedition = Visite_salle.expedition
INNER JOIN Salle ON Visite_salle.salle = Salle.id_salle
INNER JOIN Affectation_salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.salle = Monstre.id_monstre;
#WHERE Salle.fonction = 'cachot humide' 
#AND Expedition.nom_equipe = 'girafes triomphantes' 
#AND Visite_salle.moment_visite BETWEEN Expedition.depart AND Expedition.terminaison;
# -- fin test

# -- requete f)
SELECT Monstre.nom FROM Expedition 
INNER JOIN Visite_salle ON Expedition.id_expedition = Visite_salle.expedition
INNER JOIN Salle ON Visite_salle.salle = Salle.id_salle
INNER JOIN Affectation_salle ON Affectation_salle.salle = Salle.id_salle
INNER JOIN Monstre ON Affectation_salle.salle = Monstre.id_monstre
WHERE Salle.fonction = 'cachot humide' 
AND Expedition.nom_equipe = 'girafes triomphantes' 
AND Visite_salle.moment_visite BETWEEN Expedition.depart AND Expedition.terminaison;
#-- fin requete f)

# --------------------------------------------------------------------------------------------------------------------

# -- requete g)
SELECT Expedition.nom_equipe, count(Aventurier.id_aventurier) AS nombre_de_membres, avg(Aventurier.niveau) AS moyenne FROM Expedition_aventurier
INNER JOIN Expedition ON Expedition_aventurier.id_expedition = Expedition.id_expedition
INNER JOIN Aventurier ON Expedition_aventurier.id_aventurier = Aventurier.id_aventurier
GROUP BY Expedition_aventurier.id_expedition;
# -- fin requete g)

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

# -- requete i)
SELECT salle_suivante_copie.fonction FROM Salle
INNER JOIN Salle AS salle_suivante_copie ON Salle.salle_suivante = Salle_suivante_copie.id_salle
WHERE Salle.fonction  = 'entree secrete - ouest';
# -- fin requete i)

# --------------------------------------------------------------------------------------------------------------------
