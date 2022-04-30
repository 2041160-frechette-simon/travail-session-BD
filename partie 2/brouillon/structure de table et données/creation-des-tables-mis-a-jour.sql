#-------------------------------------------------------------------------------------------------
#Ceci est le script de création SQL du travail de session "ressources monstrueuses": La partie 2
#Ce n'est qu'une modification de celui de la partie 1
#
# date de début: 3 mars 2022
# date de modification: 21 avril 2022 (partie 2)
#
#
#Par: Clément Provencher et Simon Fréchette
# langage: SQL
#
#-------------------------------------------------------------------------------------------------

#  -- use database
DROP DATABASE IF EXISTS DonjonInc;
CREATE DATABASE DonjonInc;
USE DonjonInc;
#  -- fin use database

#-------------------------------------------------------------------------------------------------

# -- Salle
CREATE TABLE Salle(
	id_salle INT PRIMARY KEY AUTO_INCREMENT,
    fonction VARCHAR(255) NOT NULL,
    longueur FLOAT NOT NULL,
    largeur FLOAT NOT NULL,
    salle_suivante INT UNIQUE,
    
    FOREIGN KEY (salle_suivante) REFERENCES Salle(id_salle),
    CONSTRAINT fonction_min_5_chars CHECK (length(fonction) >= 5)
);
# -- fin Salle

#-------------------------------------------------------------------------------------------------

# -- Famille_monstre
CREATE TABLE Famille_monstre(
id_famille INT PRIMARY KEY AUTO_INCREMENT,
nom_famille VARCHAR(255) UNIQUE NOT NULL,
point_vie_maximal INT NOT NULL,
degat_base INT NOT NULL,

CONSTRAINT vie_max_superieure_zero CHECK (point_vie_maximal > 0),
CONSTRAINT degat_base_superieur_zero CHECK (degat_base > 0)
);
# -- fin Famille_monstre

#-------------------------------------------------------------------------------------------------

# -- Monstre
CREATE TABLE Monstre(
id_monstre INT PRIMARY KEY AUTO_INCREMENT,
nom VARCHAR(255) NOT NULL,
code_employe CHAR(4) NOT NULL,
point_vie INT NOT NULL,
attaque INT NOT NULL,
numero_ass_maladie BLOB NOT NULL,
id_famille INT NOT NULL,
experience INT NOT NULL,

FOREIGN KEY (id_famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Monstre

#-------------------------------------------------------------------------------------------------

# -- Responsabilite
CREATE TABLE Responsabilite(
id_responsabilite INT PRIMARY KEY AUTO_INCREMENT,
titre VARCHAR(255) NOT NULL,
niveau_responsabilite INT NOT NULL,

CONSTRAINT niveau_responsabilite_positif CHECK (niveau_responsabilite >= 0)
);
# -- fin Responsabilite

#-------------------------------------------------------------------------------------------------

# -- Affectation_salle
CREATE TABLE Affectation_salle (
id_affectation INT PRIMARY KEY AUTO_INCREMENT,
monstre INT NOT NULL,
responsabilite INT NOT NULL,
salle INT NOT NULL,
debut_affectation DATETIME NOT NULL,
fin_affectation DATETIME,

FOREIGN KEY (monstre) REFERENCES Monstre(id_monstre),
FOREIGN KEY (responsabilite) REFERENCES Responsabilite(id_responsabilite),
FOREIGN KEY (salle) REFERENCES Salle(id_salle)
);
# -- fin Affectation_salle

#-------------------------------------------------------------------------------------------------

# -- Humanoide
CREATE TABLE Humanoide(
id_humanoide INT PRIMARY KEY AUTO_INCREMENT,
famille INT NOT NULL,
arme VARCHAR(255),
intelligence INT NOT NULL,

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille),
CONSTRAINT intelligence_positive CHECK (intelligence >= 0)
);
# -- fin Humanoide

#-------------------------------------------------------------------------------------------------

# -- Mort_vivant
CREATE TABLE Mort_vivant(
id_Mort_vivant INT PRIMARY KEY AUTO_INCREMENT,
famille INT NOT NULL,
vulnerable_soleil TINYINT NOT NULL,
infectieux TINYINT NOT NULL,

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille),
CONSTRAINT vulnerable_soleil_bool CHECK (vulnerable_soleil BETWEEN 0 AND 1),
CONSTRAINT infectieux_bool CHECK (infectieux BETWEEN 0 AND 1)
);
# -- fin Mort_vivant

#-------------------------------------------------------------------------------------------------

# -- Elementaire
CREATE TABLE Elementaire(
id_elementaire INT PRIMARY KEY AUTO_INCREMENT,
famille INT NOT NULL,
element ENUM("air","feu","terre","eau") NOT NULL,
taille ENUM("rikiki","moyen","grand","colossal") NOT NULL,

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Elementaire

#-------------------------------------------------------------------------------------------------

# -- Coffre_tresor
CREATE TABLE Coffre_tresor(
	id_coffre_tresor INTEGER AUTO_INCREMENT PRIMARY KEY,
    code_secret CHAR(64),
    salle INTEGER,
    
    FOREIGN KEY (salle) REFERENCES Salle(id_salle)
    );
# -- fin Coffre_tresor

#-------------------------------------------------------------------------------------------------

# -- Objet
CREATE TABLE Objet(
	id_objet INTEGER AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) UNIQUE NOT NULL,
    valeur INT NOT NULL,
    masse FLOAT NOT NULL,
    
    CONSTRAINT masse_superieure_zero CHECK (masse > 0),
    CONSTRAINT valeur_superieure_zero CHECK (valeur > 0)
    );
# -- fin Objet

#-------------------------------------------------------------------------------------------------

# -- Ligne_coffre
CREATE TABLE Ligne_coffre(
	coffre INTEGER,
    objet INTEGER,
    quantite INTEGER NOT NULL,
    
    PRIMARY KEY(coffre, objet),
    FOREIGN KEY (coffre) REFERENCES Coffre_tresor(id_coffre_tresor),
    FOREIGN KEY (objet) REFERENCES Objet(id_objet),
    CONSTRAINT ligne_quantite_superieure_zero CHECK (quantite > 0)
    );
# -- fin Objet

#-------------------------------------------------------------------------------------------------

# -- Expedition
CREATE TABLE Expedition(
	id_expedition INTEGER AUTO_INCREMENT PRIMARY KEY,
    nom_equipe VARCHAR(255) UNIQUE NOT NULL,
    depart DATETIME,
    terminaison DATETIME
    );
# -- fin Expedition

#-------------------------------------------------------------------------------------------------

# -- Visite_salle
CREATE TABLE Visite_salle(
	salle INTEGER,
    expedition INTEGER,
    moment_visite DATETIME NOT NULL,
    appreciation TEXT,
    
    PRIMARY KEY(salle, expedition),
    FOREIGN KEY (salle) REFERENCES Salle(id_salle),
    FOREIGN KEY (expedition) REFERENCES Expedition(id_expedition)
    );
# -- fin Visite_salle

#-------------------------------------------------------------------------------------------------

# -- Aventurier
CREATE TABLE Aventurier(
	id_aventurier INTEGER AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    classe VARCHAR(255) NOT NULL,
    niveau TINYINT NOT NULL,
    point_vie INTEGER NOT NULL,
    attaque INTEGER NOT NULL,
    
    CONSTRAINT niveau_superieur_zero CHECK (niveau > 0)
    );
# -- fin Aventurier

#-------------------------------------------------------------------------------------------------

# -- Expedition_aventurier
CREATE TABLE Expedition_aventurier(
	id_expedition INTEGER,
    id_aventurier INTEGER,
    
    PRIMARY KEY(id_expedition, id_aventurier),
    FOREIGN KEY (id_expedition) REFERENCES Expedition(id_expedition),
    FOREIGN KEY (id_aventurier) REFERENCES Aventurier(id_aventurier)
    );
# -- fin Expedition_aventurier

#-------------------------------------------------------------------------------------------------

# -- Inventaire_expedition
CREATE TABLE Inventaire_expedition(
	id_expedition INTEGER,
    objet INTEGER,
    quantite INTEGER NOT NULL,
    
    PRIMARY KEY(id_expedition, objet), 
    FOREIGN KEY (id_expedition) REFERENCES Expedition(id_expedition),
    FOREIGN KEY (objet) REFERENCES Objet(id_objet),
    CONSTRAINT inventaire_quantite_superieure_zero CHECK (quantite > 0)
    );
# -- fin Inventaire_expedition

#-------------------------------------------------------------------------------------------------