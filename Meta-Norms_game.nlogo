globals [defections turtlecount turtleno difft Interactions mutants seen? ]

turtles-own[
    score                       ;; store the amount of points both earned or lost by the turtles
    boldness                    ;; sets the amount of Boldness to defect
    vengefulness                ;; sets the amount of Vengefulness to punish
    punish?                     ;; random variable used to decide whether or not punish
    havemutated?                ;; identity when a agent had mutated
    status                      ;; set the agent status: defector (who defect), observer (somebody who sees the deserter deserting), punisher (someone who punishes the deserter), punisher (somebody who punishes the observer)
    selected                    ;; identify if an agent had already act
    select                      ;; identify the agent focused in a tick
    defect-count                ;; count the number of times a turtle defected
    hurt-count                  ;; count the number of times a turtle was hurt
    punishes-count              ;; count the number of times a turtle punishes
    meta-punishes-count         ;; count the number of times a turtle meta-punishes
    is-punished-count           ;; count the number of times a turtle is punished
    ]

to setup
  clear-all
  set turtlecount 20  ;; set global variable as slider value
  set defections 0              ;; initialize number of defections

  addturtles turtlecount 0 0 0  ;; create the turtles, and sets the variables randomly
  reset-ticks
  ask turtles [set score 0]     ;; initialize the score
  ask turtles [set label score] ;; initialize the label score
  ask turtles [set selected 0]  ;; initialize the variable selected
  ask turtles [set select 0]    ;; initialize the variable select

end

to go100                        ;; Procedure to reproduce 100 generations
  repeat 2000[
   go
  ]
  stop
end


to go20                         ;; Procedure to reproduce 1 generation
  repeat 20[
   go
  ]
end

to go                           ;; Procedure to reproce four decision of the same agent
  ask turtles [                 ;; initialize the agents variables: color, status and label
    set status ""
    set color blue
    set label ""
    set select 0               ;; defines that no turtles are selected
   ]

  ask one-of turtles with [selected = 0] [      ;; select one turtle to decide whether or not defect
    set select 1
  ]
  repeat 4 [                                    ;; repeats four times the possibility that the same agent defects
    ask turtles [                               ;; for each repetions the values of status, color and label are reseting for the other turtles
      set status ""
      set color blue
      set label ""
    ]


    ask turtles with [select = 1] [             ;; ask the selected turtles to defect
      set selected 1
      defect                                    ;; procedure defect
      set label status

    ]


;    ]

  ]
  tick                                                  ;; a tick happen once the four repetion were done
  if (ticks > 0) and (ticks mod Generation = 0) [       ;; once a specific number of ticks the genetic algorithm is called
    ask turtles [set selected 0]
    evolution                                           ;; procedure evolution

  ]



end


to defect
  set seen? random-float More_visible?                  ;; define the value of seen parameter with a random number between 0 and More_visible?

  ;; Defect if think you can get away with it
  if seen? < boldness                                   ;; compares the seen value with boldness
     [  ;; Choose to defect
       set score score + benefit                        ;; updates the score values of the defector
       set color red                                    ;; changes the agent color to red
       set status "defector"                            ;; defines the agent status to defector
       set defections defections + 1                    ;; increase the defections (global) counter
       set defect-count defect-count + 1                ;; increase the defect-count (agent own) counter
        ask turtles with [status != "defector"][        ;; update the parameters of the other agents
            ;; hurt caused by defection
            set score score - hurts                     ;; update score values of the other agents
            set hurt-count hurt-count + 1               ;; increase the hurt-count (agent own) counter
            set status "observer"                       ;; set the other turtles status to observer
        ]

          ask other turtles with [status = "observer" and color = blue] [   ;; ask for the other turtles to decide whether or not apply the norm
            ask self [                                                      ;; define one turtle at times to decide whether or not apply the norm
            if status = "observer" and color = blue [                       ;; controls that each turtle decides whether or not apply the norm only once
            normalize                                                       ;; procedure which controls the norm application
            set label status                                                ;; changes the agent labels
            ]
          ]
        ]


  ]
end



to normalize

    if random-float 1 < seen? [                                             ;; defines if an observer saw the defector

      set punish? random-float 1                                            ;; sets the value of punish variable
      ifelse vengefulness > punish? [                                       ;; compares the vengefulness value to decide whether or not apply the norm

        set punishes-count punishes-count + 1                               ;; updates the punishes-count (agent own) counter
        set score score - cost                                              ;; updates the score values of the punisher
        set status "punisher"                                               ;; changes the agent status to punisher
        set color gray                                                      ;; changes the agent color to gray
        ask turtles with [status = "defector"] [                            ;; changes the parameters of the defector
          set score score - punishment                                      ;; updates the score values of the defectos applying the punishment
          set is-punished-count is-punished-count + 1                       ;; updates the is-punished-count (agent own) counter
        ]

    ][                                                                      ;; when the agent decides not to punish
        set status "tolerant"                                               ;; changes the agent status to tolerant
        set color yellow                                                    ;; changes the agent color to yellow
        if Metanorm [                                                       ;; calls metanorm procedure
          ask other turtles with [status = "observer" and color = blue] [   ;; asks other observer to decide whether or not apply the metanorm
          metanormalize
          set label status
        ]
        ]
      ]
    ]
  ;;]
end

to metanormalize

    if random-float 1 < seen? [                                             ;; defines if an observer saw the tolerant


      set punish? random-float 1                                            ;; sets the value of punish variable
      if vengefulness  > punish?  [                                         ;; compares the vengefulness value to decide whether or not apply the meta-norm


        set meta-punishes-count meta-punishes-count + 1                     ;; updates the meta-punishes-count (agent own) counter
        set score score - cost                                              ;; updates the score values of the meta-punisher

        ask myself [                                                        ;; changes the parameters of the tolerant
           set score score - punishment                                     ;;  updates the score values of the torelant applying the punishment
           set is-punished-count is-punished-count + 1                      ;; updates the is-punished-count (agent own) counter

        ]

    ]


    ]


end


to evolution                                                                ;; procedure which controls the evolution


  ;; From the five most successful individual, new five will create by crossover
  let crossover-generation max-n-of 5 turtles [score]                       ;; selects the best five agents
  let extinted-generation min-n-of 15 turtles [score]                       ;; selects the other rest (15 agent with lowest score values)

  repeat 5 [                                                                ;; crossover procedure
    let parent1 one-of crossover-generation                                 ;; selects one agent to be a the parent 1
    let parent2 one-of crossover-generation                                 ;; selects one agent to be a the parent 2
    let crossover-boldness [boldness] of parent1                            ;; identify the boldness of the parent1
    let crossover-vengefulness [vengefulness] of parent2                    ;; identify the vengefulness of the parent2
    ask parent1 [ hatch 1 [ set vengefulness crossover-vengefulness set score 0 setxy random 30 random 30 ]]        ;; create a clone of the parent1 with the vengefulness of the parent2 and score 0
    ask parent2 [ hatch 1 [ set boldness crossover-boldness set score 0 setxy random 30 random 30 ]]                ;; create a clone of the parent2 with the boldness of the parent1 and score 0


  ]

  ask extinted-generation  [                                                ;; remove 15 agents with lower score
              die

  ]


  addturtles 5 0 0 0                                                        ;; create five totally new agents

  ;; mutation

   ask one-of turtles [                                                     ;; select one turtle to mutate
     if random-float 1 <= 0.01[                                             ;; if the random number was less than 0.01, the boldness value will be mutated
        set havemutated? true
        set boldness boldness + 0.1
     ]
     if random-float 1 <= 0.01[                                             ;; if the random number was less than 0.01, the vengefulness value will be mutated
       set vengefulness vengefulness + 0.1
     ]
   ]
  set Interactions 0
  ;;set defections 0


end

to addturtles [num bold venge pts]                                          ;; procedure to create new agents (adapted from http://modelingcommons.org/browse/one_model/4538#model_tabs_browse_procedures)
  create-turtles num[
    ifelse bold = 0[
      set boldness random-float 1
    ][
     set boldness bold
    ]
    ifelse venge = 0[
      set vengefulness random-float 1
    ][
      set vengefulness venge
    ]

    set score pts
    setxy random 30 random 30
    set shape "person"
    set size 3
    set color blue
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
14
12
100
45
NIL
setup
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
100
12
174
45
NIL
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1100
319
1300
469
Population Characteristics
boldness
vengefulness
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -16777216 true "" "plotxy mean [boldness] of turtles mean [vengefulness] of turtles"

PLOT
660
318
860
468
Defections
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy ticks defections"

BUTTON
90
46
175
79
go * 100
go100
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
657
12
1343
296
Boldness and Vengefulness
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Boldness" 1.0 0 -2674135 true "" "plotxy ticks mean [boldness] of turtles"
"Vengefulness" 1.0 0 -14730904 true "" "plotxy ticks mean [vengefulness] of turtles"

SWITCH
43
91
162
124
Metanorm
Metanorm
1
1
-1000

SLIDER
41
220
162
253
benefit
benefit
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
41
252
162
285
hurts
hurts
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
40
132
171
165
Generation
Generation
1
100
20.0
1
1
NIL
HORIZONTAL

BUTTON
15
46
100
79
go20
go20
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
41
318
161
351
punishment
punishment
0
9
9.0
1
1
NIL
HORIZONTAL

SLIDER
41
285
161
318
cost
cost
0
10
2.0
1
1
NIL
HORIZONTAL

PLOT
885
319
1085
469
Scores
Ticks
Score
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [score] of turtles"

SLIDER
41
386
179
419
More_visible?
More_visible?
0
5
1.0
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Model constructed based on Axelrod (1986) An Evolutionary Approach to Norms. Axelrod's proposed norms game provides a game-theoretic/evolutionary simulation of how norms might evolve in a community based on negative feedback through punishment.

## HOW IT WORKS

20 agents are created with random boldness and vengefulness of 0-7. With each run, an agent has four opportunities to "defect" (ie. carry out a negative behaviour) based on their boldness and a random likeliness of being caught. a defection carries a positive score of 3 and a loss of 1 to all other agents.

If other agents observe the defection they choose to punish it with a likelihood based on their vengefulness level. Punishment is -9 to the defecting agent, with a -2 cost to the punishing agent.

In the "metanorms" condition, agents are also punished if they chose not to punish an observed defector.

After each round, the agents with the best scores reproduce the most (i.e. carry their boldness and vengefulness levels through to the next run). There is also a 1% likelihood of mutation.

## HOW TO USE IT

Set up to reset the model then run 100 to run a full simulation.

## THINGS TO NOTICE

According to Axelrod, the model will either converge on zero boldness and some vengefulness (due to the cost of being punished), or a full norm violation condition where all agents defect and boldness becomes maximised (and no one is being punished as they are all at it!). In my test, the latter condition only arises rarely.

In the metanorms condition, convergence on a stable state of high vengefulness is more rapid and predictable - as enacting a punishment is reinforced.

## THINGS TO TRY

Try repeating the 100 runs and note how sometimes a mutation seems to lead to 100% defections by the end, though usually it converges on low boldness and mid vengefulness.

## CREDITS AND REFERENCES
v1.0 Paul Matthews, 2015. University of the West of England. paul2.matthews@uwe.ac.uk

AXELROD, R., 1986. An Evolutionary Approach to Norms. The American Political Science Review, 80(4), pp. 1095-1111
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

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

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

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

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
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>mean [score] of turtles</metric>
    <metric>mean [boldness] of max-n-of 5 turtles [score]</metric>
    <metric>mean [vengefulness] of max-n-of 5 turtles [score]</metric>
    <metric>defections</metric>
    <enumeratedValueSet variable="turtlenumber">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Punishment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hurts">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="benefit">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Metanorm">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cust">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Generation">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_seen" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>mean [score] of turtles</metric>
    <metric>mean [boldness] of max-n-of 5 turtles [score]</metric>
    <metric>mean [vengefulness] of max-n-of 5 turtles [score]</metric>
    <metric>defections</metric>
    <enumeratedValueSet variable="turtlenumber">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Punishment">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hurts">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="benefit">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Metanorm">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cust">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Generation">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="More_visible?">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
