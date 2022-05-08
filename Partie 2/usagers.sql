#-----------------------------------------------------------
#Script de création des utilisateurs
#Fait par Clément
#
#créé le 21/04/2022
#modifié le 21/04/2022
#
#-----------------------------------------------------------

#Clean up --------------------------------------------------

DROP ROLE IF EXISTS administrateur_systeme;
DROP ROLE IF EXISTS responsable_visites;
DROP ROLE IF EXISTS responsable_entretient;
DROP ROLE IF EXISTS service_ressources_monstrueuses;

DROP USER IF EXISTS daenerys;
DROP USER IF EXISTS jon;
DROP USER IF EXISTS baelish;

#Création des rôles ----------------------------------------

CREATE ROLE administrateur_systeme;
CREATE ROLE responsable_visites;
CREATE ROLE responsable_entretient;
CREATE ROLE service_ressources_monstrueuses;

#Attribution des privilèges --------------------------------

GRANT ALL ON * TO administrateur_systeme;

GRANT INSERT, UPDATE, DELETE, SELECT ON Visite_salle TO responsable_visites;
GRANT INSERT, UPDATE, DELETE, SELECT ON Expedition_aventurier TO responsable_visites;
GRANT INSERT, UPDATE, DELETE, SELECT ON Inventaire_expedition TO responsable_visites;
GRANT INSERT, UPDATE, DELETE, SELECT ON Aventurier TO responsable_visites;

GRANT INSERT, UPDATE, DELETE, SELECT ON Coffre_tresor TO responsable_entretient;
GRANT INSERT, UPDATE, DELETE, SELECT ON Ligne_coffre TO responsable_entretient;
GRANT INSERT, UPDATE, DELETE, SELECT ON Objet TO responsable_entretient;

GRANT INSERT, UPDATE, DELETE, SELECT ON Humanoide TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Mort_vivant TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Elementaire TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Famille_monstre TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Monstre TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Responsabilite TO service_ressources_monstrueuses;
GRANT INSERT, UPDATE, DELETE, SELECT ON Affectation_salle TO service_ressources_monstrueuses;

#Création des utilisateurs --------------------------------

CREATE USER daenerys IDENTIFIED BY 'dragons3' DEFAULT ROLE administrateur_systeme;
CREATE USER jon IDENTIFIED BY 'Jenesaisrien' DEFAULT ROLE responsable_entretient, responsable_visites;
CREATE USER baelish IDENTIFIED BY 'lord' DEFAULT ROLE service_ressources_monstrueuses;