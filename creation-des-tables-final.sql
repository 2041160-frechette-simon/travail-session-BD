#-------------------------------------------------------------------------------------------------
#Ceci est le script de création SQL pour les tables suivantes du travail de session "ressources monstrueuses":
#
#
#
# date de début: 3 mars 2022
#
#
#Par: Simon Fréchette et clément Provencher
# langage: SQL
#
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
    fonction VARCHAR(255),
    longueur FLOAT,
    largeur FLOAT ,
    salle_suivante INT,
    
    FOREIGN KEY (salle_suivante) REFERENCES Salle(id_salle)
);
# -- fin Salle

#-------------------------------------------------------------------------------------------------

# -- Famille_monstre
CREATE TABLE Famille_monstre(
id_famille INT PRIMARY KEY AUTO_INCREMENT,
nom_famille VARCHAR(255),
point_vie_maximal INT,
degat_base INT
);
# -- fin Famille_monstre

#-------------------------------------------------------------------------------------------------

# -- Monstre
CREATE TABLE Monstre(
id_monstre INT PRIMARY KEY AUTO_INCREMENT,
nom VARCHAR(255),
code_employe CHAR(4),
point_vie INT,
attaque INT,
numero_ass_maladie BLOB,
id_famille INT,
experience INT,

FOREIGN KEY (id_famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Monstre

#-------------------------------------------------------------------------------------------------

# -- Responsabilite
CREATE TABLE Responsabilite(
id_responsabilite INT PRIMARY KEY AUTO_INCREMENT,
titre VARCHAR(255),
niveau_responsabilite INT
);
# -- fin Responsabilite

#-------------------------------------------------------------------------------------------------

# -- Affectation_salle
CREATE TABLE Affectation_salle (
id_affectation INT PRIMARY KEY AUTO_INCREMENT,
monstre INT,
responsabilite INT,
salle INT,
debut_affectation DATETIME,
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
famille INT,
arme VARCHAR(255),
intelligence INT,

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Humanoide

#-------------------------------------------------------------------------------------------------

# -- Mort_vivant
CREATE TABLE Mort_vivant(
id_Mort_vivant INT PRIMARY KEY AUTO_INCREMENT,
famille INT,
vulnerable_soleil TINYINT,
infectieux TINYINT,

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Mort_vivant

#-------------------------------------------------------------------------------------------------

# -- Elementaire
CREATE TABLE Elementaire(
id_elementaire INT PRIMARY KEY AUTO_INCREMENT,
famille INT,
element ENUM("air","feu","terre","eau"),
taille ENUM("rikiki","moyen","grand","colossal"),

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Elementaire

#-------------------------------------------------------------------------------------------------
#
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
    nom VARCHAR(255),
    valeur INT,
    masse FLOAT
    );
# -- fin Objet

#-------------------------------------------------------------------------------------------------

# -- Ligne_coffre
CREATE TABLE Ligne_coffre(
	coffre INTEGER,
    objet INTEGER,
    quantite INTEGER,
    
    PRIMARY KEY(coffre, objet),
    FOREIGN KEY (coffre) REFERENCES Coffre_tresor(id_coffre_tresor),
    FOREIGN KEY (objet) REFERENCES Objet(id_objet)
    );
# -- fin Objet

#-------------------------------------------------------------------------------------------------

# -- Expedition
CREATE TABLE Expedition(
	id_expedition INTEGER AUTO_INCREMENT PRIMARY KEY,
    nom_equipe VARCHAR(255),
    depart DATETIME,
    terminaison DATETIME
    );
# -- fin Expedition

#-------------------------------------------------------------------------------------------------

# -- Visite_salle
CREATE TABLE Visite_salle(
	salle INTEGER,
    expedition INTEGER,
    moment_visite DATETIME,
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
    nom VARCHAR(255),
    classe VARCHAR(255),
    niveau TINYINT,
    point_vie INTEGER,
    attaque INTEGER
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
