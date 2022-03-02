#-------------------------------------------------------------------------------------------------
#Ceci est le script de création SQL pour les tables suivantes du travail de session "ressources monstrueuses":
#
#Salle
#Affectation_salle
#Monstre
#Responsabilite
#Famille_monstre
#
#Humanoide
#Mort_vivant
#Elementaire
#
# Il s'agit des requêtes situées dans le haut du schéma, à l'horizontal.
#
# date de début: 3 mars 2022
#
#
#Par: Simon Fréchette
# langage: SQL
#
#TODO: mettre les valeurs d'enum
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
id_responsable INT PRIMARY KEY AUTO_INCREMENT,
titre VARCHAR(255),
niveau_responsabilite INT
);
# -- fin Responsabilite

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
CREATE TABLE Humanoide(
id_elementaire INT PRIMARY KEY AUTO_INCREMENT,
famille INT,
element ENUM("1","2"),
taille ENUM("1","2"),

FOREIGN KEY (famille) REFERENCES Famille_monstre(id_famille)
);
# -- fin Elementaire

#-------------------------------------------------------------------------------------------------

