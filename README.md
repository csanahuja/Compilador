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
