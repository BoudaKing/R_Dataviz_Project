# R_Dataviz_Project
# Le Tour de France en Chiffres

## Noureddine BOUDALI

## Sommaire
1. User Guide
2. Developper Guide

## 1. User guide

Ce projet est le projet de fin de l'unité 'DSIA_4101C R et DataViz'.
Il a pour sujet les différentes édition du Tour de France. Les données sont extraites de https://www.kaggle.com/datasets/pablomonleon/tour-de-france-historic-stages-data , elles présentent la Grande Boucle sur 3 fichiers csv différents, qui représentent l'épreuve à différentes échelles. 
Le premier, ```tdf_winners.csv```, représente des données sur les 106 premières éditions du Tour, de 1903 à 2019. Il contient notamment des données sur les gagnants de chacune des éditions, avec le temps de parcours, l'écart avec le second au classment général, le nombre d'étapes avec le maillot jaune, etc. 
Le second, ```tdf_stages.csv```, contient autant d'observations que d'étapes, et contient les lieux de départ et d'arrivée des différentes étapes, le vainqueur du jour, le type de l'étape, etc.
Le troisième, ```stage_data.csv```, contient des informations plus précises sur l'étape, comme les différents participants à l'étape et leur rang à l'arrivée.

Il faut donc croiser certaines données entre les 3 datasets, car la donnée n'est pas uniformisée entre les 3, le code pour nettoyer les données et les croiser est commenté dans la première partie "Global" du code.

Pour pouvoir géolocaliser les départs et arrivées d'étapes, on a également eu recours au dataset ```communes_departement_regions.csv``` de https://www.data.gouv.fr/fr/datasets/communes-de-france-base-des-codes-postaux/. Ce dataset contient notamment les coordonnées GPS des communes en France ainsi que leurs noms. On a donc du le croiser avec ```tdf_stages``` pour obtenir les géolocalisations des départs et arrivées d'étapes.

### 1.1 Déploiement

Pour déployer le projet, il faut d'abord le cloner sur la machine:
```git clone git@github.com:BoudaKing/R_Dataviz_Project.git```

Puis ouvrir le fichier ```app.R``` dans RStudio.

Ensuite, pour chacun des packages inclus dans le fichier ```requirements.txt```, les installer à l'aide de la commande ```install.packages(<PACKAGE EN QUESTION>)``` dans le terminal de RStudio.

Enfin, lancer le dashboard en entrant la commande ```shiny::runApp()``` dans le terminal RStudio ou bien en cliquant sur 'Run App'.

Alternativement, vous pouvez aller dans ```File > Open Project```, puis ouvrir le fichier ```R_dataviz_Project.Rproj```. Puis lancer ```shiny::runApp()```.

L'application du projet devrait alors se lancer dans Rstudio, mais vous pouvez aussi y accéder sur un navigateur à ```localhost:6742```.

### 1.2 Les données

Au lancement de l'application, on voit 3 graphiques.

#### 1-Les distances des étapes
Le premier graphique montre un histogramme représentant la distribution des distances des étapes selon le type d'étape parmi:
-Les contre-la-montre individuels
-Les étapes plates
-Les étapes de moyenne montagne
-Les étapes de haute montagne
-Les contre-la-montre en montagne
-Les contre-la-montre par équipes

On peut sélectionner le manière dont la distribution est représentée à l'aide des boutons de radio en haut, d'une part en histogramme, d'autre part en boite à moustaches. 
On peut également sélectionner quels types d'étapes on souhaite voir dans le graphique à l'aide des checkbox. 

On constate deux catégories d'étapes, les étapes en ligne et les contre-la-montre. Les étapes en ligne tournent autour des 200km, tandis que les CLM tournent plutôt à 75km. C'est normal, car dans une étape en ligne, on court avec le peloton et on peut donc être dans l'aspiration de celui-ci. Il faut noter que quand on est protégé du vent, c'est jusqu'à 40% de l'effort qui est économisé. Donc les étapes en lignes sont conçues pour être plus longues que les CLM, car la majorité de l'effort fourni par les coureurs est économisé, et l'énergie consommée lors d'une étape en ligne est comparable à un CLM, même si ce dernier est beaucoup moins long.
Par ailleurs, les CLM par équipes sont plus longs que les individuels pour cette même raison, car les équipiers se relaient pour protéger les autres du vent.

#### 2-Données géolocalisées
On peut voir les données géolocalisées sur 2 cartes auxquelles on peut accéder avec les boutons. 
La première visualisation montre les nombres de départs et d'arrivées des étapes du Tour. Selon le nombre de passages de la Grande Boucle, le point est plus ou moins large. On peut avoir les données plus précises en cliquant dessus pour obtenir le nom de la villes, et le nombre de passages.
La seconde carte montre les Types des étapes. Les contre-la-montres sont affichés en nuances de bleu (en fonction du type de CLM) et les étapes en lignes vont du vert au rouge en fonction du dénivelé. On peut également voir les données précises de chaque étape en cliquant sur le point.

On distingue pour les départs/arrivées les différentes grandes métropoles de France qui ont un point plus grand que les autres, car le Tour passe fréquemment dans les grande villes. À noter que les données sont biaisées car certaines arrivées du Tour arrivent dans des grands cols, qui ne sont pas renseignés dans ```communes_departements_regions```, donc pour les grands cols récurrents du tour, on devrait avoir des gros points à ces endroits-là. Par exemple, il est indiqué que le Tour est arrivé 29 fois à l'Alpe d'Huez, qui n'est pas renseigné par ```communes_departements_regions```. 
On peut également souligner qu'il pourrait être intéressant d'avoir le liste des montées/cols par lesquels passent chaque étape (une étape de montagne n'a pas nécessairement une arrivée au sommet, c'est même souvent l'inverse).
Pour les types d'étapes, les étapes de montagne coïncident avec les massifs montagneux Français, tels que les Vosges, le Jura, les Alpes, le Massif central et les Pyrénées.

#### 3-Vitesses moyennes
On a un scatterplot des temps de parcours du vainqueur chaque édition, en fonction de la distance. On peut sélectionner les années des éditions qu'on souhaite étudier. On semble distinguer une relation linéaire (logique, car en principe à vitesses égales le temps et la distance sont proportionnels) , donc on trace également une régression linéaire entre les deux variables. On peut également voir les vitesses moyennes de la sélection. 
On remarque tout d'abord qu'il y a deux éditions très courtes en distance par rapport aux autres, et qui ont été complétées en un temps anormalement grand pour la distance (25.5 km/h de moyenne). Il s'agit des deux premières éditions du Tour en 1903 et 1904. La raison de cette faible vitesse est liée à la longueur des étapes, en effet, le Tour comptait alors seulement 6 étapes, en comparaison avec les 21 d'aujourd'hui, mais ces étapes étaient extrèmement longues et excédaient presque toutes les 350 km (avec par exemple la titanesque étape Paris-Lyon, 467km) https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Tour_de_France_1903_schema.png/300px-Tour_de_France_1903_schema.png. Ces étapes sont donc si longues qu'il est facile d'imaginer que les coureurs ne savaient pas gérer leur effort car le Tour était alors le seul grand Tour à étapes. Par la suite, les éditions ont augmenté le nombre d'étapes (15 en 1913) et raccourci la longueur des étapes, qui tournaient plus vers les 250km. 
On remarque en bougeant le slider que même s'il y a une relation linéaire entre la distance et le temps, la vitesse moyenne du Tour n'a eu de cesse d'augmenter (27km/h en 1913 et 40km/h en 2019). De plus, on remarque que la distance totale des Tours était à son pic dans les années 1915-1925, avec plus de 5000 km (sachant qu'on était encore à des Tours à 15 étapes), tandis qu'au 21eme siècle elles sont entre 3300 et 3700km.

## 2. Developper guide

À la racine du projet on peut trouver:
-Le fichier du code ```App.R```
-Le répertoire ```archive``` qui contient les 4 fichiers csv utilisés pour le projet
-Le fichier ```requirements.txt``` qui contient tous les packages additionnels
-Le fichier ```README.md```
-Le fichier ```R_Dataviz_Project.Rproj```

Le code est structuré en 3 parties, GLOBAL, UI et SERVER. 

#### GLOBAL
La partie GLOBAL est chargée de nettoyer les données et de les croiser entre elles

#### UI 
UI contient 3 zones, une pour chaque graphique et est chargée de l'organisation de l'affichage du dashboard.

Petite spécification par rapport à la carte, on utilise le package Leaflet, qui utilise les données Openstreetmap pour afficher des données géolocalisées.

#### SERVER
SERVER se charge du rendu des visualisations et des interactions entre les inputs et les outputs. 
L'interaction input-output se fait via des ```reactiveValues``` qui sont des variables qui peuvent changer au cours de l'exécution de l'app. Elles sont stockées dans ```v```. Pour les changer, on utilise des ```observeEvent``` sur chaque élément d'input. 
À l'intérieur de ces ```observeEvent```, on définit comment les ```reactiveValues``` changent.

Donc pour les maps, on a une variable ```CurrentMap``` qui vaut soit 1 soit 2 selon la carte choisie.
Et on choisit de faire le rendu de l'une ou de l'autre car les 2 sont stockées dans des variables statiques.

Pour l'Histogramme/Boxplot, on a 2 variables ```reactiveValues```, ```radio_buttons_selection``` qui contient une string, soit ```"Histogram"```, soit ```"Boxplot"``` et qui désigne le type de graphique que l'on souhaite afficher, et ```data_distances``` qui désigne les types d'étapes que l'on souhaite afficher.

Pour le scatterplot, on a ```sliderData``` qui contient le maximum et le minimum du slider. On effectue ensuite un filtre pour les éditions se déroulant entre le min et le max.
