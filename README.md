# Compilador

Compilador fet amb lex i yacc a partir del compilador https://github.com/jordiplanes/senzill
### Caracterítiques
  - Nova gràmatica
  - Includes
  - Comentaris (Una línia i multi-línia)
  - Arrays
  - Indexació per arrays
  - Funcions
  - Arguments per les funcions
  - Scopes per les funcions
  - Pas d'arrays per referència
  - Possibilitat de definir funcions dintre d'altres funcions

#### Gràmatica

Amb la nova gràmatica es poden barrejar les declaracions de variables amb les instruccions normals. Com podem veure en l'exemple de sota, el programa comença amb la paraula clau `main` instrucció que conté tot el programa i s'obre i es tanca amb les interrogacions `¿ ?`. Les comandes acaben sempre amb `;` 
```
/* Exemple de gràmatica mínima per qualsevol programa */
main ¿
    # Comandes;
?
````

#### Includes

Els includes es duen a terme amb la paraula clau `import` seguit del ruta del fitxer com podem veure en el següent exemple
```
# Noteu que els includes no acaben amb el caracter ;
main ¿ 
    import test/test2_1.sz
    import test/test2_2.sz
?
````

#### Comentaris
Per afegir comentaris al nostre programa tenim dues alternatives:
- Comentar una línia desde el caràcter fins al final amb `#`
- Multilinia obrint amb `/*` i tancan amb `*/`

#### Arrays
Per definir arrays ho farem amb la comanda `int array[size];` on array és el nom de la variable i size la longitud. Noteu que podem definir varios arrays a la mateixa línia o amb altres variables de tipus int
```c
# Declaració d'arrays i variables a la mateixa línia
 int array[5], a, b, i[10];
```
També és possible accedir als arrays mitjançant indexos sense que aquestos siguin un número directament sinó una expresió que pot ser una variable o bé una operació.
```
int a, b[5];
a = 1;
b[a] = 2;
b[a+2] = 3;
```
#### Funcions
Per definir funcions ho farem de la següent manera. Noteu com s'utilizen els mateixos símbols d'apertura i tancament que pel main i que acaben amb `;` després del tancament.
```
# Definició d'una funció
def function() ¿
    # Comandes;
?;
```
##### Paràmetres
També podem definir funcions amb paràmetres
```
def function(int integer, int[] array)¿ #... ?;
```
I definit funcions dintre de funcions
```
def function(int a) ¿
    def function2(int b) ¿?;
?;
```
##### Scopes

Per tal d'implementar que els arguments i variables d'una funció no siguin accesibles des de funcions externes a excepció de funcions declarades dintre de la mateixa funció s'han implementat els scopes. Els scopes consisteixen en un pila on cada cop que creem una funció creem i apilem un scope únic per aquella funció i al acabar la funció desempilem el scope. D'aquesta manera i tal com s'ha implementat la cerca de variables si cerquem una variable en una determinda funció la cercarem al seu scope i sinó anirem agafam un scope superior fins arribar al scope GLOBAL, això fa possible que des d'una funció puguem accedir a totes les variables definides en nivells superiors. 
```
/* En aquest exemple podeu veure com des de la func2 podriem accedir a:
   - La variable global a 
   - La variable b de la funció func
   - La variable local c
 */
main ¿ 
    int a; a = 1;
    def func()¿
        int b; b = 2;
        def func2()¿
            int c; c = 3;
            write a; write b;  write c;
        ?;  
    ?;
?
```

La assignació dels arguments que passem per paràmetre a una funció es idèntica a les variables que podem definir dintre, són varibles que definim amb el scope de la funció i li assignem els valors que li passem per parametre.

##### Pas d'arrays per referència
El cas dels arrays és diferent de les variables. Cada cop que passem una variable de tipus int a una funció o bé un número, com veiem en aquest exemple el que fem és crear una variable dintre la funció, en modificar aquesta variable, en aquest cas `i` la variable que passem per paràmetre `a` no es veura afectada.
```
def func(int i)¿?;
# Pas de variable
int a; a = 1; func(a);
# Pas d'un int directament
func(1);
```
En canvi quam passem un array per paràmetre el que fem es crear una altra etiqueta, noteu com en el següent exemple en modifcar l'array dintre de la funció aquest també canviarà fora. Així doncs quan printem `a[3]` que prèviament hem assignat a `3` veurem com en fer un `write` obtindrem com resultat `4` donat que tot i que la funció ha modifcat l'array `i` aquesta etiqueta es un apuntador que apunta a la mateixa adreça que l'etiqueta `a`
```
# Pas per referència
def func(int[] i)¿
   i[3] = 4;
?;
int a[5]; a[3] = 3;
func(a);
write a[3];
```

Per dur a terme el pas per referència en primer lloc simplement s'havia pensat en crear una variable a la taula de symbols sense asignar-li cap offset ni fet cap `data_location()`. Així el que tindriem és una altra etiqueta i en cridar la funció assignar els atributs de la variable que passem per paràmetre a la variable de la funció és a dir l'offset. Per realitzar això s'ha hagut de modificar les expressions dels paràmetres que introduïm en una funció. Prèviament es podien assignar expressions però ara era convienent diferenciar entre variables i números.

Aquesta diferenciació es deguda a que inicialment la variable de tipus array que tenim en la funció no és una variable a la la pila de la VM, només està a la taula de símbols així doncs no li podem assignar un número sino que li hem d'assignar una posició de memòria d'alguna altra variable (la que referenciarà). És per això que es permet assignar a un array tant variables (considerades arrays de longitud 1) com arrays. De fet si volem que una funció ens modifiqui el valor de una variable el que podem fer es declarar una funció amb un paràmetre de tipus array i passar per valor la variable que volem modificar.
