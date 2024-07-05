#show box: it => align(center, it)
#set math.equation(numbering: "(1)")

= Rendering Catenaries
\
[paraphrased from wikipedia]

A catenary is the shape that a chain or rope creates when it is hung at two fixed points. It looks like, but is not a parabola.

If there is added weight, as in the rope is supporting extra weight other than itself, the shape will not be a mix between catenary and parabola, depending on how impactful the weight of the rope is. As in: if the weight of the rope itself is negligeable compared to what it is supporting, then the shape will be a parabola.

== Catenary equation

The basic equation for catenaries is as follows:
$ y = a cosh(x/a) $ <cat>
Where $a > 0$.

#{
  import "@preview/cetz:0.2.2": canvas, plot
  let domain = (-3, 3)
  canvas(length: 1cm, {
    plot.plot(size: (6, 6),
      x-tick-step: 1,
      y-tick-step: 1,
      y-min: 0,
      y-max: 6,
      x-grid: true,
      y-grid: true,
      {
        plot.add(
          style: (stroke: green),
          domain: domain,
          label: "a=1",
          x => 1 * calc.cosh(x/1))
        plot.add(
          style: (stroke: blue),
          domain: domain,
          label: "a=1.5",
          x => 1.5 * calc.cosh(x/1.5))
        plot.add(
          style: (stroke: red),
          domain: domain,
          label: "a=2",
          x => 2 * calc.cosh(x/2))
      })
  })
}

The catenary is centered on the $y$ axis, and is above the $x$ axis. The minima is at $(0, a)$. $a$ determines how "wide" the catenary is.

The reverse is also possible, getting $x$ from $y$.
$ x = a "acosh"(y/a) $ <cat-inv>

where acosh is the inverse of cosh, and only returns the positive values of x.

The length of the curve between two points at $x_1$ and $x_2$ is:
$ L = a sinh(x_2/a) - a sinh(x_1/a) $ <arc-len>

#pagebreak()

== Algorithm for rendering catenaries in pixel art
Pixel art catenaries can be drawn if the parameter $a$ is known. An x and y displacement is necessary render the wanted section.

First iterate through the x coordinates and use @cat to get the corresponding y coordinate, draw this pair. Once done, there will be gaps when the y displacement from one x-coord to the next is greater than 2.

Fix this by iterating through the y coordinates, using @cat-inv to get and draw coord pairs. This will overwrite some of the pixels drawn during the first loop, but will get rid of the gaps.

Pseudocode:
```
x_disp = ...
y_disp = ...
fn cat_y(x) = a * cosh(x/a)
fn cat_x(y) = a * acosh(y/a)

for x_im in 0..w
  x = x_im + x_disp
  y = cat_y(x)
  y = y.round()
  y_im = y - y_disp
  # (0,0) is usually top-left for images
  # flip and make (0,h-1) the top-left
  y_im = h - 1 - y_im
  draw(x_im,y_im)

for y_im in 0..h
  # (0,0) is usually top-left for images
  # flip and make (0,h-1) the top-left
  y_im = h - 1 - y_im
  y = y_im + y_disp
  x = cat_x(y)
  x = x.round()
  x_im = x - x_disp
  draw(x,y)
```

== Catenary from anchor displacement and arc length

Goal: to draw a catenary with anchor points spaced apart by the vector $"disp"_"AB"$, with a length of rope between them $L$.

$ "disp"_"AB" = vec(h, v) $ <disp-AB>

The catenary needs has anchor points:  $"Point"_A$ and $"Point"_B$, where

$ "Point"_B = "Point"_A + "disp"_"AB" $

In summary: \
#align(center, [
Knowns: $"disp"_"AB"$, $L$ \
Unknowns: $a$, $"Point"_A$, $"Point"_B$ \
])

#{
  import "@preview/cetz:0.2.2": canvas, plot, draw
  let domain = (-3, 3)
  canvas(length: 1cm, {
    plot.plot(size: (6, 2),
      name: "plot",
      axis-style: none,
      {
        plot.add(((-2,3),), mark: "o")
        plot.add-anchor("pt1", (-2,3))
        plot.add(((2,4),), mark: "o")
        plot.add-anchor("pt2", (2,4))

        plot.add(((-3.5,2), (3.5, 2)))
        plot.add-anchor("line1", (-3.5,2))
        plot.add-anchor("line2", (3.5,2))
      })
    draw.content("plot.pt1", anchor:"south", padding:.3, [$"Point"_A$])
    draw.content("plot.pt2", anchor:"south", padding:.3, [$"Point"_B$])
    draw.line("plot.pt1", "plot.pt2", mark: (end: ">"), name: "line")
    draw.content(("line.start", 1.7, "line.end"), angle:"line.end", anchor:"south", padding:.2, [$"disp"_"AB"$])
    draw.content(("plot.line1", 3, "plot.line2"), anchor:"south", padding:.3, [length of rope $L$])
  })
}
$a$ is the only paramter needed for the catenary equation in @cat. However, the section of the catenary which has the two points on the curve with a difference of $"disp"_"AB"$ must be found. 

Since there is a direct relation between $x$ and $y$ from @cat and $"Point"_A$, $"Point"_B$ from disp, finding either $x_A$, $x_B$, $y_A$ or $y_B$ is sufficient.

Keeping in mind $x_B = x_A + h$ and $y_B = y_A + v$, and the hyperbolic identities:\ 
$sinh(x) - sinh(y) = 2 cosh((x+y)/2) sinh((x-y)/2)$ \
$cosh(x) - cosh(y) = 2 sinh((x+y)/2) sinh((x-y)/2)$

Both $"Point"_A$ and $"Point"_B$ are on the catenary, so an equation for $v$ by using @cat is:

$ v &= a cosh(x_B/a) - a cosh(x_A/a) $
This can be simplified to:
$
v/a &= cosh((x_A+h)/a) - cosh(x_A/a) \
v/(2a) &= cosh((2x_A + h)/(2a)) sinh(h/(2a))
$ <v>

$ v^2 = 4 a^2 cosh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) $ <v-squared>

The equation for $L$ in @arc-len can be similarly simplified:
$ 
L   &= a sinh(x_B/a) - a sinh(x_A/a) \
L/a &= sinh((x_A+h)/a) - sinh(x_A/a) \
L/(2a) &= sinh((2x_A + h)/(2a)) sinh(h/(2a)) \
$ <L>
$ L^2 = 4 a^2 sinh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) $ <L-squared>


=== Finding $a$

Keeping in mind \
$cosh^2(x) - sinh^2(x) = 1$ 

Substracting @L-squared from @v-squared gives:

$ 
v^2 - L^2 &=   4 a^2 cosh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) - 4 a^2 sinh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) \
&=  4 a^2 sinh^2(h/(2a)) [cosh^2((2x_A + h)/(2a)) - sinh^2((2x_A + h)/(2a))] \
&= 4 a^2 sinh^2(h/(2a))
$

Therefore:
$ sqrt(v^2 - L^2) = 2 a sinh(h/(2a)) $
Solving for $a$ must be done numerically.

=== Finding $x_A$
$x_A$ can be solved for in @v:

$ 
v/(2a) &= cosh((2x_A + h)/(2a)) sinh(h/(2a)) \
cosh((2x_A + h)/(2a)) &= v/(2a sinh(h/(2a)))  \
(2x_A + h)/(2a) &= "acosh"(v/(2a sinh(h/(2a)))) \
2x_A &= 2a "acosh"(v/(2a sinh(h/(2a)))) - h \
$
$ x_A = a "acosh"(v/(2a sinh(h/(2a)))) - h/2 \ $
it can be similarly solved for in @L



