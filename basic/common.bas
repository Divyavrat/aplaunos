rem *** MikeOS BASIC example program ***

alert "Welcome to the example!"
cls

print "Let's skip the next 'print' line..."
goto jump

print "This line will never be printed :-("

jump:
print "Righto, now enter a number:"
input x

if x > 10 then print "X is bigger than 10! Wow!"
if x < 10 then print "X is quite small actually."
if x = 10 then gosub equalsroutine

a = 7
b = a / 2
print "Variable A is seven here. Divided by two you get:"
print b
print "And the remainder of that is:"
b = a % 2
print b

print "A quick loop here..."
for c = 1 to 10
  print c
next c

print "Righto, that's the end! Bye!"
end

equalsroutine:
  print "Awesome, a perfect 10! Give me your name so I can high-five you!"
  input $1
  print "Top work, " ;
  print $1
return