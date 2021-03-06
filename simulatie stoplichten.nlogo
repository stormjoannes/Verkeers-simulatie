extensions [csv]

breed [cars car]

globals [  line_1 line_2 line_3 line_4
  average
  time
  flow-car-way-1 flow-car-way-2 flow-car-way-3 flow-car-way-4
  flow-car-way-5 flow-car-way-6 flow-car-way-7 flow-car-way-8
  color_1 color_2
  switch-checked
  total_amount_cars]

cars-own [
  speed
  speed-limit ;; max snelheid
  number
]

to setup-crossing-lights
  clear-all
  reset-ticks
  ; maak het kruispunt
  ask patches [ create-crossing-lights ]
  make-cars amount-cars-way-1 1
  make-cars amount-cars-way-2 2
  make-cars amount-cars-way-3 3
  make-cars amount-cars-way-4 4
  set flow-car-way-1 one-of cars with [ number = 1 ]
  set flow-car-way-2 one-of cars with [ number = 2 ]
  set flow-car-way-3 one-of cars with [ number = 3 ]
  set flow-car-way-4 one-of cars with [ number = 4 ]
end


to create-crossing-lights
  if pycor < 3 and pycor > -3 [ set pcolor white ] ;; mooie witte streep als "weg"
  if pxcor < 3 and pxcor > -3 [ set pcolor white ] ;; mooie witte streep als "weg"
  set color_1 red
  set color_2 red
  if traffic-lights = True [
  set_traffic_lights
  ]
end

to set_traffic_lights
  ; dit zijn de locaties van de stoplichten op de weg
  if pycor > 0 and pycor < 3 and pxcor = 3 [ set pcolor color_1 ]
  if pycor > -3 and pycor < 0 and pxcor = -3 [ set pcolor color_1 ]
  if pxcor > 0 and pxcor < 3 and pycor = -3 [ set pcolor color_2 ]
  if pxcor > -3 and pxcor < 0 and pycor = 3 [ set pcolor color_2 ]
end

to check
  ; elke 200 ticks veranderen de stoplichten van kleur en elke 400 ticks (200 ticks later) worden de kleuren nogmaals omgedraaid
  if ticks mod 200 = 0 [ set color_1 lime set color_2 red]
  if ticks mod 400 = 0 [ set color_1 red set color_2 lime ]
  set_traffic_lights
end

to make-cars [ amount road-num]
  create-cars amount [
    set number road-num
    set size 1.5
    ; set heading x, x staat voor graden waarmee we aangeven welke kant de auto opkijkt
    ask cars [
      if number = 1 [ set heading 270 set shape "car_left"]
      if number = 2 [ set heading 180 set shape "car_down"]
      if number = 3 [ set heading 90 set shape "car_right"]
      if number = 4 [ set heading 0 set shape "car_up"]
    ]
    ; Road 1 en 3 zijn horizontaal, 2 en 4 zijn verticaal. Zo laten we de auto's random op de baan spawen
    if road-num = 1 [ setxy random-xcor 1 ]
    if road-num = 2 [ setxy -1 random-ycor ]
    if road-num = 3 [ setxy random-xcor -1 ]
    if road-num = 4 [ setxy 1 random-ycor ]
    set speed 0
    set speed-limit 0.6; door de waarde bij de auto te zetten krijgt de weg een maximum snelheid
    set total_amount_cars count cars
    seperate
  ]
end


to seperate
  ; met deze functie geven we elke auto een spot op de weg waar ze minimaal een bepaalde afstand (2 patches link 2 rechts) van andere auto's zitten
  if any? other cars in-radius 2 [
    fd 1
    seperate
  ]
end


to line_crosses_count [ line_check_color ]
  ; per baan berekenen ze voor 1 auto wat de doorstroom is.
  ; dit word berekend door de al berekende doorstroom plus de huidige speed wanneer de auto over een uitgekozen patch rijd.
  ; deze patch is als de stoplichten aan staan de lime kleurige patch, anders is het de grijzen.
  ask flow-car-way-1 [
    if ([pcolor] of patch-here = line_check_color) [ set line_1 line_1 + speed ]
  ]
  ask flow-car-way-2 [
    if ([pcolor] of patch-here = line_check_color) [ set line_2 line_2 + speed ]
  ]
  ask flow-car-way-3 [
    if ([pcolor] of patch-here = line_check_color) [ set line_3 line_3 + speed ]
  ]
  ask flow-car-way-4 [
    if ([pcolor] of patch-here = line_check_color) [ set line_4 line_4 + speed ]
  ]
end


to go
  ; Dit is voor de switch, want bij de stoplichten gelden andere regels dan bij een gelijkwaardig kruispunt
  ; als de traffic lights is ingeschakeld (True) zorg dat ie checkt welk stoplicht op dat moment rood en groen moeten zijn
  ifelse traffic-lights = True
  [ ask patches [check] ]
  ;;else zet de stoplichten grijs, zodat ze niet meedoen aan het verkeer. Een gelijkwaardig kruispunt
  [ set color_1 gray
    set color_2 gray
    ;;pas kleuren aan van de patches
    ask patches [ set_traffic_lights ] ]
  ask cars[
    ;;kijkt of er een rode patch voor zich zit (rode stoplicht), zo ja: stop de auto
    ifelse ([pcolor] of patch-ahead 1 = red) [ set speed 0]
    [
    ;; is er een auto 2 patches voor je
    let car-infront one-of cars-on patch-ahead 2
    ifelse car-infront = nobody
    ;; nee..versnel
    [ speed-up ]
    ;; ja..versloom
    [ slow-down car-infront]
    ]

    ; als traffic-lights false is voeren we de verkeersregels in van een gelijkwaardig kruispunt
    if traffic-lights = False [
      ; controleer op welke baan de auto staat
      ; Elke auto (auto A) moet kijken of er rechts van hem een auto (auto B) aankomt. Dit moeten we aangeven door middel van patchsets
        if number = 1 [
        ; stop patches zijn alle patches waar als een auto B daar momenteel is de auto A stopt en dus voorrang verleent
          let stop_patches (patch-set patch -1 0 patch -1 1 patch -1 2 patch -1 3 patch -1 4  patch -1 5 patch -1 6 patch 1 1 patch 1 0 patch 1 -1)
        ; go patches zijn zijn alle patches waar als daar een auto B staat van een bepaalde baan auto A door kan rijden (ook al staan er auto's rechts) meer hierover in de check-lane functie
          let go_patches (patch-set patch -2 -1 patch -1 -1 patch 0 -1 patch 1 -1 patch 2 -1 patch 1 1 patch 0 1 patch -1 1)
        ; look range geeft aan vanaf welk punt de auto A gaat kijken naar wat er voor hem gebeurd
          let look_range [2 4]
          check-lane number stop_patches go_patches look_range "x" 3
        ]
      ; bij de andere checks gebeurt hetzelfde alleen met andere waardes

        if number = 2 [
          let stop_patches (patch-set patch -6 -1 patch -5 -1 patch -4 -1 patch -3 -1 patch -2 -1 patch -1 -1  patch 0 -1 patch -1 1 patch 1 1 patch 2 1)
          let go_patches (patch-set patch 1 2 patch 1 1 patch 1 0 patch 1 -1 patch 1 -2 patch -1 1 patch -1 0 patch -1 -1)
          let look_range [2 4]
          check-lane number stop_patches go_patches look_range "y" 4
        ]

        if number = 3 [
          let stop_patches (patch-set patch 1 0 patch 1 -1 patch 1 -2 patch 1 -3 patch 1 -4  patch 1 -5 patch 1 -6 patch -1 -1 patch -1 0 patch -1 1)
          let go_patches (patch-set patch -2 1 patch -1 1 patch 0 1 patch 1 1 patch 2 1 patch -1 -1 patch 0 -1 patch 1 -1)
          let look_range [-4 -2]
          check-lane number stop_patches go_patches look_range "x" 1
        ]

        if number = 4 [
          let stop_patches (patch-set patch 0 1 patch 1 1 patch 2 1 patch 3 1 patch 4 1 patch 5 1 patch 6 1 patch -1 -1 patch 0 -1 patch 1 -1)
          let go_patches (patch-set patch -1 2 patch -1 1 patch -1 0 patch -1 -1 patch -1 -2 patch 1 -1 patch 1 0 patch 1 1)
          let look_range [-4 -2]
          check-lane number stop_patches go_patches look_range "y" 2
        ]
      ; elke 50 ticks wordt er gekeken of de weg vast loopt en zo ja dan wordt een baan geforceerd (oftewel een bestuurder onderneemt dan zelf actie)
        if ticks mod 50 = 0 [
          if mean [speed] of cars = 0 [
          ; stuur mee hoeveel banen er in de simulatie zijn
            force_lane 4
          ]
        ]
    ]
    ;; snelheid mag niet hoger dan het snelheidslimiet
    if speed > speed-limit [set speed speed-limit]
    if speed < 0 [ set speed 0 ]
    fd speed
  ]
  set average mean [speed] of cars
  ifelse traffic-lights = True
  [ line_crosses_count lime ]
  [ line_crosses_count gray ]

  ; elke 1000 ticks slaan we de huidige staat van de simulatie op in een csv bestand
  if ticks mod 1000 = 0 [results]

  tick
end


to check-lane [road_num stop_patches go_patches look_range axis opposite_side]
  ; road_num : nummer die aangeeft op welke baan auto A zich bevindt
  ; stop_patches : patches waar auto A voorrang aan moet verlenen als er een auto B op staat
  ; go_patches : patches waar als er een auto B van een bepaalde baan op staat auto A door kan rijden
  ; look_range : Geeft aan vanaf welk punt auto A begint op te letten wat er op de weg gebeurd
  ; axis : geeft aan of auto A op een horizontale of verticale weg zit
  ; opposite_side : Dit zijn de auto's B die als een van hun op een go patch staat auto A kan doorrijden
  ifelse axis = "x" [
    ask cars with [number = road_num] [
      ; zit auto A in de look_range?
      if xcor >= item 0 look_range and xcor <= item 1 look_range [
        ; zitten er auto B's op stop_patches?
        if any? cars-on stop_patches [
          ; is er geen auto B die van de overkant komt waardoor je door kan rijden?
          if not all? cars-on go_patches [number = opposite_side][
            ; verleen voorrang
            set speed 0
          ]
        ]
      ]
    ]
  ]
  [
    ask cars with [number = road_num] [
      if ycor >= item 0 look_range and ycor <= item 1 look_range [
        if any? cars-on stop_patches [
          if not all? cars-on go_patches [number = opposite_side][
            set speed 0
          ]
        ]
      ]
    ]
  ]
  ; Deze functie is misschien nog steeds verwarrend met de stop en go patches dus hieronder een klein voorbeeld
  ; er komt een auto van baan 1 (rechts). hun zouden dus auto's van baan 4 (boven) voorrang moeten verlenen
  ; als er een auto van baan 4 komt aanrijden OF er staan al auto's van baan 2 (beneden) of 4 op de kruising rem je af
  ; als er geen auto's op de kruising staan van baan 2 of 4, maar wel een auto van baan 3 (links) rij je door. OOK AL STAAT ER EEN AUTO OP BAAN 4
  ; dit hebben we zo gedaan omdat baan 4 voorrang moet geven aan baan 3 dus die moet stil staan todat de auto's van baan 3 zijn overgestoken.
  ; als deze toch stilstaan kan je dan net zo goed doorrijden om zo de doorstroming te verbeteren want dan sta je niet onnodig stil.
end


to force_lane [lanes]
  ; pak een random baan
  let lane random lanes + 1
  ; forceer de auto(s) op die baan om 2 naar voren te gaan
  ask cars with [number = lane] [
     fd 2
  ]
end


to slow-down [car-infront]
  ; versloom de auto op basis van de auto voor je en de descelaration
  set speed [speed] of car-infront - decelaration
end


to speed-up []
  ; versnel de auto op basis van de huidige snelheid en de accelaration
  set speed speed + accelaration
end


to-report var-in-file
  ;; elke variabelen die je in het bestand wilt meegeven
  report (list average line_1 total_amount_cars speed-limit accelaration decelaration)
end


to results
  file-open "data_verkeer.csv"
  if (not file-exists? "data_verkeer.csv") [
    ;; voegt kolomnamen toe aan bestand
    file-print csv:to-row (list "average speed" "line count" "total cars" "speed limit" "accelaration" "decelaration")
  ]
  ask one-of cars [
    file-print csv:to-row var-in-file
  ]
  file-close
end


to deleteFile
  if (file-exists? "data_verkeer.csv") [
    ifelse (user-yes-or-no? "Do you want to delete this file?") [ ;;vraagt aan user om confirmatie om de file te deleten
      file-delete "data_verkeer.csv"
    ][
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
478
54
1158
735
-1
-1
11.02
1
10
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
303
188
460
225
setup
setup-crossing-lights
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
369
230
462
263
play/pause
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
303
230
366
263
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
298
274
470
307
amount-cars-way-1
amount-cars-way-1
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
298
311
470
344
amount-cars-way-2
amount-cars-way-2
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
299
474
471
507
accelaration
accelaration
0.0001
0.02
0.0056
0.0001
1
NIL
HORIZONTAL

SLIDER
299
513
471
546
decelaration
decelaration
0.001
0.1
0.055
0.001
1
NIL
HORIZONTAL

SLIDER
297
345
469
378
amount-cars-way-3
amount-cars-way-3
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
298
382
470
415
amount-cars-way-4
amount-cars-way-4
1
20
6.0
1
1
NIL
HORIZONTAL

PLOT
1165
55
1601
401
flow trought traffic lights
time
crossings
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot (line_1 + line_2 + line_3 + line_4) / 4"

SWITCH
321
153
445
186
traffic-lights
traffic-lights
1
1
-1000

BUTTON
202
230
287
263
NIL
deleteFile
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This is a basic traffic simulation to test if the speed limit has any effect on the traffic flow.

## HOW IT WORKS

Our agents are the cars. The cars wil keep a certain distance from vehicles in front of them. If they get to close they brake, but if there is no one in front of them, they accelarate.

## HOW TO USE IT

You click on setup and after setup you press on GO.

## THINGS TO NOTICE

You will notice cars get closer to cars in front of them, this will lead to the car break breaking. If this repeats itself it will cause a traffic jam. You can also look at the average speed monitor. With this we can see what the average speed of all cars are. With this info, we can make a simple (not 100% accurate) conculsion if the maximum speed has any influence on the traffic flow
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car_down
false
0
Polygon -7500403 true true 180 300 164 279 144 261 135 240 132 226 106 213 84 203 63 185 50 159 50 135 60 75 150 0 165 0 225 0 225 300 180 300
Circle -16777216 true false 180 180 90
Circle -16777216 true false 180 30 90
Polygon -16777216 true false 80 162 78 132 135 134 135 209 105 194 96 189 89 180
Circle -7500403 true true 195 47 58
Circle -7500403 true true 195 195 58

car_left
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

car_right
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car_up
false
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
