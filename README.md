# Reaction-Game
Capacitive sensor reaction reaction game written in 8051 assembly using the AT89LP51RC2 microcontroller. Produces an audible signal using a speaker, wait for players input from capacitive sensors, decides who wins the round, and keeps a record of points for each player using the LCD. Capacitance variations were detected using a 555 timer on an a-stable oscillator configuration.

**Game Rules**

1. The game will produce either a 2100Hz tone or a 2000Hz tone randomly using the CEM-1023 speaker.
2. If the tone is 2100Hz, the first player to press its capacitor sensor wins a point.
3. If the tone is 2000Hz, the first player that presses its capacitor sensor loses a point.
4. The LCD displays the points for each player.
5. The first player to reach 5 points wins the game!
6. Other Contributers: Colin Pereira, Mohamed Salah
