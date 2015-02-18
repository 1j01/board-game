
@T = THREE
@P = Physijs
@V2 = T.Vector2
@V3 = T.Vector3

# relative to this file
P.scripts.worker = './lib/physijs_worker.js'
# relative to the above worker file
P.scripts.ammo = './ammo.js'


@TAU = # C/r  #%##%#|#%##%#
          #%###     |     #%###
       #%#         tau         #%#     Tau is equal to the circumference divided by the radius.
     #%#     ...--> | <--...     #%#
   #%#     -'   one | turn  '-     #%#    One whole turn in radians.
  ##     .'         |         '.     ##
 ##     /           |           \     ##
 #     |            | <-..       |     #
##    |          .->|     \       |    ##
#     |         /   |      |      |     #    Pi is half a turn in radians, as shown in this diagram.
- - - - - - Math.PI + Math.PI - - - - - 0
#     |         \   |      |      |     #
##    |          '->|     /       |    ##
 #     |            | <-''       |     #
 ##     \           |           /     ##
  ##     '.         |         .'     ##
   #%#     -.       |       .-     #%#
     #%#     '''----|----'''     #%#
       #%#          |          #%#
         #%##%#     |     #%###
              #%##%#|#%##%#

@choose = (args...)->
	arr = if args.length > 1 then args else args[0]
	arr[~~(Math.random()*arr.length)]

