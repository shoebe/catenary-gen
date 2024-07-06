#set page(
  numbering: "1 / 1",
  number-align: right + bottom
)


#show box: it => align(center, it) // center plots
#let numbered_eq(content) = math.equation(
    block: true,
    numbering: "(1)",
    content,
)
#set heading(numbering: "1.a)")



= Rendering Catenaries
\
[paraphrased from wikipedia]

A catenary is the shape that a chain or rope creates when it is hung at two fixed points. It looks like, but is not a parabola.

If there is added weight, as in the rope is supporting extra weight other than itself, the shape will be a mix between catenary and parabola, depending on how impactful the weight of the rope is. As in: if the weight of the rope itself is negligeable compared to what it is supporting, then the shape will be a parabola.


= Catenary equation

#numbered_eq($ y = a cosh(x/a) $) <cat>
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

Any two points (and the segment between) chosen on any of these curves are valid catenaries.

The catenary is centered on the $y$ axis, and is above the $x$ axis. The minima is at $(0, a)$. $a$ determines how "wide" the catenary is.

The reverse is also possible, getting $x$ from $y$.
#numbered_eq($ x = a "acosh"(y/a) $) <cat-inv>

where acosh is the inverse of cosh. This will and only returns the positive values of x.

The length of the curve between two points at $x_1$ and $x_2$, where $x_2$ > $x_1$, is:
#numbered_eq($ L = a sinh(x_2/a) - a sinh(x_1/a) $) <arc-len>

#pagebreak()

= Algorithm for rendering catenaries in pixel art
Pixel art catenaries can be drawn if the parameter $a$ is known. An $x$ and $y$ displacement is necessary to render the wanted section.

First iterate through the $x$ coordinates and use @cat to get the corresponding $y$ coordinate, draw all paris. Once done, there will be gaps when the $y$ displacement from one $x$ coord to the next is greater than 1.

Fix this by iterating through the $y$ coordinates, using @cat-inv to get $x$, draw all pairs. This will overwrite some of the pixels drawn during the first loop, but will get rid of the gaps.

// not actually python but adds a splash of color
```python
x_disp = ...
y_disp = ...
fn cat_y(x) = a * cosh(x/a)
fn cat_x(y) = a * acosh(y/a)

for x_im in 0..w
  x = x_im + x_disp
  y = cat_y(x)
  y = y.round()
  y_im = y - y_disp
  # FLIPPING: (0,0) is usually top-left for images
  # flip and make (0,h-1) the top-left
  y_im = h - 1 - y_im
  draw(x_im,y_im)

for y_im in 0..h
  # See FLIPPING note
  y_im = h - 1 - y_im
  y = y_im + y_disp
  x = cat_x(y)
  x = x.round()
  x_im = x - x_disp
  draw(x,y)
```

= Catenary from anchor displacement and arc length

Goal: to draw a catenary with anchor points spaced apart by the vector $"disp"_"AB"$, with a length of rope between them $L$. $h$ is the displacement in the $x$ direction and $v$ in the $y$.

$ "disp"_"AB" = vec(h, v) $

The catenary has two anchor points:  $"Point"_A$ and $"Point"_B$, where

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
    plot.plot(size: (6, 1.5),
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
$a$ is the only paramter needed for the catenary equation in @cat. However, the section of the catenary which has the two points on the curve with a difference of $"disp"_"AB"$ must also be found. 

Since there is a direct relation between $x$ and $y$ from @cat and $"Point"_A$ and $"Point"_B$ from $"disp"_"AB"$, finding either $x_A$, $x_B$, $y_A$ or $y_B$ is sufficient.

Keeping in mind $x_B = x_A + h$ and $y_B = y_A + v$, and the hyperbolic identities:
$ sinh(x) - sinh(y) = 2 cosh((x+y)/2) sinh((x-y)/2) $ 
$ cosh(x) - cosh(y) = 2 sinh((x+y)/2) sinh((x-y)/2) $

Both $"Point"_A$ and $"Point"_B$ are on the catenary, so an equation for $v$ by using @cat is:

$ v &= a cosh(x_B/a) - a cosh(x_A/a) $
This can be worked to:
$ v/a &= cosh((x_A+h)/a) - cosh(x_A/a) $
#numbered_eq($ v/(2a) = sinh((2x_A + h)/(2a)) sinh(h/(2a)) $) <v>

#numbered_eq($ v^2 = 4 a^2 sinh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) $) <v-squared>

The equation for $L$ in @arc-len can be similarly worked:
$ L/a &= sinh((x_A+h)/a) - sinh(x_A/a) $
#numbered_eq($ L/(2a) &= cosh((2x_A + h)/(2a)) sinh(h/(2a)) $) <L>
#numbered_eq($ L^2 = 4 a^2 cosh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) $) <L-squared>

$sinh^2$ is an even function, so this function is also valid


== Finding $a$

Keeping in mind \
$ cosh^2(x) - sinh^2(x) = 1 $ 

Substracting @v-squared from @L-squared gives:

$ 
L^2 - v^2 &=   4 a^2 cosh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) - 4 a^2 sinh^2((2x_A + h)/(2a)) sinh^2(h/(2a)) \
&=  4 a^2 sinh^2(h/(2a)) [cosh^2((2x_A + h)/(2a)) - sinh^2((2x_A + h)/(2a))] \
&= 4 a^2 sinh^2(h/(2a))
$
#pagebreak()
Therefore for $a >= 0$:
$ sqrt(L^2 - v^2) = 2 a sinh(h/(2a)) $
Solving for $a$ must be done numerically.

$ f(a) = 0 = 2 a sinh(h/(2a)) - sqrt(L^2 - v^2) $

$ (d f(a))/(d a) = 2 sinh(h/(2a)) - h/a cosh(h/(2a)) $

== Finding $x_A$ <find-xa>
$x_A$ can be solved for in @v:

$ 
v/(2a) &= cosh((2x_A + h)/(2a)) sinh(h/(2a)) \
cosh((2x_A + h)/(2a)) &= v/(2a sinh(h/(2a)))  \
(2x_A + h)/(2a) &= "acosh"(v/(2a sinh(h/(2a)))) \
2x_A &= 2a "acosh"(v/(2a sinh(h/(2a)))) - h \
$
$ x_A = a "acosh"(v/(2a sinh(h/(2a)))) - h/2 \ $
it can be similarly solved for in @L

= Avoiding having to solve numerically for $a$

$a$ can be solved for algebraically if there is no $y$ displacement between $"Point"_A$, $"Point"_B$, and the amount of "sag" $H$ is known from the y level of the points down to the minima of the catenary.

In summary: \
#align(center, [
Knowns: $L$, $H$, $v=0$ \
Unknowns: $a$, $"Point"_A$, $"Point"_B$, $h$ \
])

if $v = 0$ then the minima is centered between $"Point"_A$ and $"Point"_B$. 
$ x_B = -x_A = h / 2 $

Keeping in mind
$ sinh(-x) = -sinh(x) $
@arc-len can be worked down to:

$ 
L &= a sinh(x_B/a) - a sinh(x_A/a) \
  &= a sinh(x_B/a) + a sinh(x_B/a) 
$

$ L = 2 a sinh(h/(2a)) $

#numbered_eq($ L^2 = 4 a^2 sinh^2(h/(2a)) $) <L-squared-2>

Reworking @cat:
$ 
y_B &= a cosh(x_B/a) \
    &= a cosh(h/(2a)) \
$
#numbered_eq($ y_B^2  &= a^2 cosh^2(h/(2a)) $) <y-B-squared>

Substracting @L-squared-2 from @y-B-squared:

$
y_B^2 - L^2 /4 &= a^2 cosh^2(h/(2a)) - a^2 sinh^2(h/(2a)) \
              &= a^2 (cosh^2(h/(2a)) - sinh^2(h/(2a))) \
              &= a^2
$
#numbered_eq($ y_B^2 - L^2 /4 = a^2 $) <y-B-L-all-squared>
Since $a$ is the minima, and $H$ is from the minima to the $y$ of the points
$ y_A = y_B = H + a $

Plug into @y-B-L-all-squared:

$
a^2 &= (H+a)^2 - L^2 / 4 \
    &= H^2 + 2 H a + a^2 - L^2 / 4 \
2H a &= L^2/4 - H^2
$

#numbered_eq($ a &= L^2/(8H) - H/2 $)

To get a non-symmetrical catenary using this method, an arbitrary amount of curve can be ignored. For example, $"Point"_A$ can be moved by 20 to the right:

$ x_A "new" = x_A + 20 $
$ y_A "new" = a cosh((x_A "new") / a) $

Could also move it up or down instead

Doing this is not very intuitive with the parameters though.