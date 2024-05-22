#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(tidyverse)
library(tidyr)
library(dplyr)
library(lubridate)
library(stringr)
library(shiny)
library(leaflet)
library(ggthemes)

##GLOBAL

##Lecture des communes
#(pour la geoloc)
communes_data <- read_csv("archive/communes_departement_region.csv")
communes_data <- select(communes_data, c("nom_commune_complet","latitude","longitude"))
communes_data <- communes_data %>% mutate(nom_commune_complet = str_squish(str_remove_all(nom_commune_complet, "[0-9]")))
communes_data <- communes_data %>% distinct(nom_commune_complet, .keep_all = TRUE)
#On enleve les caracteres numeriques de communes_data , ainsi Paris 12 devient Paris, 
#On supprime ensuite les villes qui apparaissent plusieurs fois, puisque Paris 12 et Paris 13 deviennent Paris

##Lecture de stage_data
stage_data <- read.csv("archive/stage_data.csv")
#On utilise read.csv car le csv contient des apostrophes, qui ne sont pas gerees par read.table
stage_data <- as_tibble(stage_data)
colnames(stage_data)[3] <- "stage_id"
stage_data <- stage_data %>% mutate(stage_id = paste(year,stage_id,sep="-"), rank = as.numeric(rank), team = na_if(team,""))
#Il peut paraitre judicieux d'identifier chaque etape par un code de la forme
#"<Annee de l'edition>-stage-<Numero d'etape>
stage_data <- stage_data %>% select(-c(bib_number,elapsed,time))
#On supprime le numero de dossard

switch_names <- function(full_name) {
  words <- str_split(full_name, " ")[[1]]
  switched_name <- paste(c(words[length(words)],words[-length(words)]), collapse = " ")
}

stage_data <- stage_data %>% mutate(rider = sapply(rider,switch_names))
#Les noms dans stage_data sont stockes sous la forme "Nom Prenom", alors que 
#dans stages et winners c'est "Prenom Nom". On change donc le format dans
#stage_data. A noter que ce n'est pas satisfaisant pour les noms composes
#qui sont separes par un espace, exemple " Serrano Marcos Antonio". On ne sait
#pas s'il s'appelle Antonio Serrano Marcos  ou Marcos Antonio Serrano. Je
#vous laisse imaginer pour les coureurs Flamands, qui sont nombreux, car
#le cyclisme est un sport très populaire en Flandres. Exemple: quel est le vrai
#nom de Van der Poel Mathieu, le champion du monde 2023 de course en ligne?
#Ici on optera pour une structure "Prenom Nom", avec la possibilite d'avoir des noms composes et non des prenoms
#Ainsi, Pointet Jean Marc s'appellera Marc Pointet Jean, mais Van Aert Wout
#s'appellera Wout Van Aert
stage_data <- stage_data %>% mutate(rider = as_factor(rider))

#Lecture de tdf_winners

winners <- read.csv("archive/tdf_winners.csv")
winners <- select(winners, c("edition","start_date","winner_name","distance","time_overall","time_margin","stage_wins","stages_led","age","born","nationality"))
winners <- as_tibble(winners)

winners <- mutate(winners,start_date= year(as.Date(start_date)), winner_name = as_factor(winner_name), nationality = as_factor(nationality), time_margin = time_margin*60)
colnames(winners)[2] <- "Year"
colnames(winners)[6] <- "Time_Margin_Minutes"
#On utilise as.Date car la date de depart de l'edition etait stockee comme <chr>
#Pour des raisons de simplicite, On utilise desormais l'annee de l'edition a la place du jour de depart de l'epreuve (a part dans des cas rarissimes, le Tour commence fin juin-debut juillet tous les ans)


##Lecture de tdf_stages
stages <- read.csv("archive/tdf_stages.csv")
stages <- as_tibble(stages)

stages <- mutate(stages, Date = as.Date(stages$Date))

stages <- filter(stages,!str_detect(Winner, "Cancelled"))
#Petite subtilite pour certaines etapes qui se sont vues annuler, on doit donc
#filtrer les apparitions du mot "cancelled"

stages <- mutate(stages, stage_id = paste(year(Date),"stage",Stage,sep="-"))
#De meme que pour stage_data, on utilise une id d'etape

stages <- mutate(stages, Winner = if_else(stages$Type == "Team time trial", NA,Winner),Winner_Country = if_else(stages$Type == "Team time trial" | Winner_Country == "",NA,Winner_Country))
#On a une subtilite avec les victoires d'etapes ici: dans la grande majorite des
#cas, les etapes sont classiques et individuelles (un seul gagnant pour l'etape)
#En revanche, il existe un type d'etape bien specifique: le contre-la-montre par
#equipes. Ici, ce n'est pas un coureur qui gagne la course mais bien une equipe entiere.
#Ainsi, on supprime le gagnant de l'etape lorsqu'il s'agit d'un CLM par equipes (dans le csv c'est l'equipe victorieuse qui est renseignee)
simplified_Type <- function(old_Type) {
  if (old_Type == "High mountain stage" || old_Type == "Mountain stage" || old_Type == "Stage with mountain(s)" || old_Type == "Mountain Stage" || old_Type == "Stage with mountain"){
    simplified_Type <- "Mountain stage"
  }
  else if (old_Type == "Flat cobblestone stage" || old_Type == "Transition stage" || old_Type == "Flat Stage" || old_Type == "Flat stage" || old_Type == "Plain stage" || old_Type == "Half Stage" || old_Type == "Intermediate stage" || old_Type == "Plain stage with cobblestones"){
    simplified_Type <- "Flat stage"
  }
  else if (old_Type == "Hilly stage" || old_Type == "Medium mountain stage"){
    simplified_Type <- "Medium mountain stage"
  }
  else simplified_Type <- old_Type
}
stages <- stages %>% 
  mutate(Type = sapply(Type,simplified_Type))


stages <- left_join(stages, communes_data, by = c("Origin" = "nom_commune_complet"))
stages <- stages %>% rename(lat_origin = latitude, long_origin = longitude)
stages <- left_join(stages, communes_data, by = c("Destination" = "nom_commune_complet"))
stages <- stages %>% rename(lat_destination = latitude, long_destination = longitude)
#Pour avoir les coordonnees gps des departs et arrivees des etapes, on merge communes_data et
#stages. On eut avoir des problemes pour les etapes ne se deroulant pas en France (il y en a en general
#une ou deux par edition), ou bien pour les arrivees
stages <- mutate(stages, Origin = as_factor(Origin), Destination = as_factor(Destination), Type = as_factor(Type),Winner = as_factor(Winner), Winner_Country = as_factor(Winner_Country))


Origins <- data.frame(table(stages$Origin)) %>%
  rename(nom_commune = Var1, departs = Freq)
Destinations <- data.frame(table(stages$Destination)) %>%
  rename(nom_commune = Var1, arrivees = Freq)

communes <- full_join(Origins, Destinations, by = "nom_commune")
rm(Origins)
rm(Destinations)
communes[is.na(communes$departs), "departs"] <- 0
communes[is.na(communes$arrivees), "arrivees"] <- 0
communes <- left_join(communes, communes_data, by = c("nom_commune" = "nom_commune_complet"))

# UI
ui <- fluidPage(
  titlePanel("Projet DSIA_4101C: Le Tour de France en Chiffres"),
  verticalLayout(
    sidebarLayout(
      sidebarPanel(
        radioButtons(
          "rb_distance_plot",
          "Affichage",
          choices = c("Histogram","Boxplot")
        ),
        checkboxGroupInput(
          "Checkbox_stages",
          "Types d'Étapes",
          levels(stages$Type),
          selected = levels(stages$Type),
          inline = FALSE
        )
      ),
      mainPanel(
        plotOutput("distHistogram")
      )
    ),
    
    titlePanel("Carte des Étapes"),
    sidebarLayout(
      sidebarPanel(
        actionButton("ButtonMap1", "Départs/Arrivées"),
        actionButton("ButtonMap2", "Type d'Étape")
      ),
      mainPanel(
        leafletOutput("Map1")
      )
    ),
    
    titlePanel("Vitesses moyennes des éditions"),
    verticalLayout(
      mainPanel(
        plotOutput("Scatterplot")
      ),
      sidebarPanel(
        sliderInput("Slider",
                    "Années",
                    min=min(winners$Year),
                    max=max(winners$Year),
                    value=c(min(winners$Year),max(winners$Year)),
                    step=1,
                    sep = " ",
                    animate = TRUE)
      )
    )
  )  
)


# SERVER
server <- function(input, output) {
  
  v <- reactiveValues(CurrentMap=1,
                      data_distances = levels(stages$Type),
                      sliderData = winners %>%
                        select(c("distance","time_overall")),
                      radio_buttons_selection = "Histogram")
  
#Cartes  
  map1 <- leaflet() %>%
    addCircleMarkers(data = communes,
                     popup = paste(sep = "<br/>",
                                   communes$nom_commune,
                                   paste("Départs: ",communes$departs," - ","Arrivées: ",communes$arrivees,sep="")
                     ),
                     color = "navy",
                     radius = (communes$departs + communes$arrivees)/10
    ) %>%
    addTiles() %>%
    setView(lng = 2.4, lat = 46.53, zoom = 5)  
  
  map2 <- leaflet() %>%
    addCircleMarkers(data = stages,
                     lat = stages$lat_destination,
                     lng = stages$long_destination,
                     popup = paste(sep = "<br/>",
                                   paste("Date: ", stages$Date),
                                   paste("Départ: ",stages$Origin,", Arrivée: ", stages$Destination),
                                   paste("<b>Type:",stages$Type,"<b>")
                     ),
                     color = ifelse(stages$Type == "Individual time trial","cyan",ifelse(stages$Type == "Mountain time trial","#100681",ifelse(stages$Type == "Team time trial","#8AABEB",ifelse(stages$Type == "Flat stage","#84BD1B",ifelse(stages$Type == "Medium mountain stage","#FCA50AFF",ifelse(stages$Type == "Mountain stage","#D02E10","cyan")))))),
                     stroke = TRUE,
                     fillOpacity = 0.5
                     
    ) %>%
    addTiles() %>%
    setView(lng = 2.4, lat = 46.53, zoom = 5)  
  
  observeEvent(input$ButtonMap1, {
    v$CurrentMap <- 1
  })
  
  observeEvent(input$ButtonMap2, {
    v$CurrentMap <- 2
  })
  
  output$Map1 <- renderLeaflet({
    if (v$CurrentMap == 1) map1
    else map2
  })
  
  
#Histogramme/Boxplot
  observeEvent(input$rb_distance_plot, {
    v$radio_buttons_selection <- input$rb_distance_plot
  })
  
  observeEvent(input$Checkbox_stages, {
    v$data_distances <- input$Checkbox_stages
  })
  
  output$distHistogram <- renderPlot({
    if (v$radio_buttons_selection == "Histogram") {
      filter(stages, Type %in% v$data_distances) %>% 
        ggplot(aes(x=Distance,fill = Type)) +
        geom_histogram(binwidth = 10)+
        labs(x = "Distance (km)", y = "Fréquence", title="Distance des étapes")+
        theme_economist()+
        scale_fill_economist()
    }
    else {
      filter(stages, Type %in% v$data_distances) %>% 
        ggplot(aes(x = Type, y=Distance, fill = Type)) +
        geom_boxplot(outlier.shape = NA)+
        labs(y = "Distance (km)", title="Distance des étapes")+
        theme_economist()+
        scale_fill_economist()
    }
  })
  
  
#Scatterplot 
  observeEvent(input$Slider,{
    v$sliderData <- winners %>%
      filter(Year >= input$Slider[1] & Year <= input$Slider[2] & !is.na(time_overall)) %>%
      select(c("distance","time_overall"))
  })
  
  output$Scatterplot <- renderPlot({
    v$sliderData %>%
      ggplot(aes(x=distance,y=time_overall)) +
      geom_point()+
      geom_smooth(method="lm",formula = "y ~ x")+
      labs(x = "Distance (km)", y = "Temps de parcours (km)", title = "Distances et temps de parcours", subtitle = paste("Vitesse moyenne des éditions: ", mean(v$sliderData$distance/v$sliderData$time_overall), "km/h"))+
      theme_economist() +
      scale_fill_economist()
    
    
  })
}

shinyApp(ui,server)
