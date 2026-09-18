**#OGÓLNE**  
jak zwykle w compiled jest gotowa wersja do pobrania  
a w kodŹródłowy są pliki projektu do godota  
(naprawdę przepraszam że łącze polski z angielskim)  
  
**#JAK TO DZIAŁA**  
Zasada działania jot'a w 4D jest bardzo prosta.  
Bierzemy dwa jot'y 2D i przy każdej iteracji gry w chaos zamieniamy wymiary (więcej we wzorze)  
  
**#WZÓR NA JOT'A 2D**  
bierzemy losową z trzech funkcji i gramy w chaos:  
f1(xy) = 1/√3 * [0 1] [x] + [2]  
----------------[1 0] [y] + [0]  

f2(xy) = 1/√3 * [0 1] [x] + [-1]  
----------------[1 0] [y] + [√3]  

f3(xy) = 1/√3 * [0 1] [x] + [-1]  
----------------[1 0] [y] + [-√3]  
Zasadniczo ma to bardzo dużo wspólnego z trójkątem sierpińskiego  
  
**#WZÓR NA JOT'A W 4D**
Po każdej iteracji robimy operacje:  
x = (z+x) * 1/√2  
y = (w+y) * 1/√2  
z = (z-x) * 1/√2  
w = (w-y) * 1/√2  
Więc teorytycznie można stworzyć JOT'a w liczbie wymiarów która jest potęgą dwójki i jest większa od 1  
(pracuje obecnie nad przełożeniem go na 8D)  
  
**#AUTOR FRAKTALU JOT**  
Fraktal JOT 2D został odkryty przez Marka Jendernalika  
To tutaj to tylko przełożenie go z 2 wymiarów na 4  
  
**#DALSZE INFO**  
utworzono 14.09.2026
