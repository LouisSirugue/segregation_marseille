
library(data.table)
library(tidyverse)
library(sf)

# Recensement
rp <- fread("src/FD_LOGEMTZE_2022.csv", colClasses = "character", 
              select = c("COMMUNE", "ARM", "IRIS", "IMMIM")) %>% 
  filter(COMMUNE =="13055" & IMMIM != "Y") %>% 
  mutate(pct_arr = mean(IMMIM == "1"), .by = c("COMMUNE", "ARM")) %>% 
  summarise(pct = mean(IMMIM == "1"), pct_arr = unique(pct_arr),
            .by = c("COMMUNE", "ARM", "IRIS")) %>% 
  mutate(INSEE_COM = ifelse(ARM != "ZZZZZ", ARM, COMMUNE),
         IRIS = ifelse(IRIS == "ZZZZZZZZZ", paste0(COMMUNE, "0000"), IRIS))

# Fonds de carte
iris <- read_sf("src/CONTOURS-IRIS.shp") %>% 
  filter(INSEE_COM %chin% rp$INSEE_COM)
iris <- st_transform(iris, crs = st_crs("EPSG:2154"))

com <- read_sf("src/COMMUNE.shp") %>% filter(NOM == "Marseille")
com <- st_transform(com, crs = st_crs("EPSG:2154"))

# Appariement
map_iris <- iris %>% 
  left_join(rp %>% select(CODE_IRIS = IRIS, pct), by = "CODE_IRIS") 

# Carte
ggplot(map_iris, aes(fill = pct)) +
  geom_sf(color = alpha("white", .15), linewidth = .1) +
  geom_sf(data = map_iris %>% summarise(geometry = st_union(geometry), .by = INSEE_COM), 
          inherit.aes = F, fill = "transparent", color = alpha("white", .33)) +
  scale_fill_gradient(name = "Proportion d'immigrés", low = "black", high = "white", 
                      space = "Lab", na.value = "transparent", breaks = seq(0, .7, .1), 
                      labels = paste0(seq(0, 70, 10), " %")) +
  theme_void(base_size = 11) +
  guides(fill = guide_colorbar(barwidth = 20, barheight = 0.5, title.position = "top")) +
  theme(legend.direction = "horizontal", legend.position = "bottom", 
        legend.title = element_text(hjust = .5))

ggsave("out/marseille.tif", width = 4.5, height = 4.5, dpi = 300)
ggsave("out/marseille.jpeg", width = 4.5, height = 4.5, dpi = 300)
ggsave("out/marseille.png", width = 4.5, height = 4.5, dpi = 300)

ggplot(map_iris, aes(fill = pct)) +
  geom_sf(color = NA) +
  geom_sf(data = map_iris %>% summarise(geometry = st_union(geometry), .by = INSEE_COM), 
          inherit.aes = F, fill = "transparent", color = alpha("white", .5)) +
  scale_fill_viridis_c(name = "Proportion d'immigrés", option = "A", na.value = "transparent", 
                       breaks = seq(0, .7, .1), labels = paste0(seq(0, 70, 10), " %")) +
  theme_void(base_size = 11) +
  guides(fill = guide_colorbar(barwidth = 20, barheight = 0.5, title.position = "top"))+
  theme(legend.direction = "horizontal", legend.position = "bottom", 
        legend.title = element_text(hjust = .5))

ggsave("out/marseille.pdf", width = 4.5, height = 4.5)
