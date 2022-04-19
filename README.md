# Complex effect

This is the first gold achievements for the Effects & Shaders class in THUAS'
Game Development & Simulation minor.

## Instructions

Create a complex effect with at least three different shaders in it (VS, PS &
GS/Tess).

### Requirements

- The effect should be written with the HLSL language only, and thus be
game-engine-agnostic. It must be able to run in Unity for instance, but also
other softwares.
- The effect must include at least a vertex shader, a fragment shader and a
third shader which can be either a geometry or a hull shader.
- The vertex shader must at least use some kind of algorithm to transform the
vertices. It must have some complexity.
- The fragment shader must at least use two textures and combine them.

### Result

The goal of this shader is to render a snow cover over objects in the
scene. It uses:
- a vertex shader to perform some preliminary computations, and among
other things, offset the surface by the specified snow thickness amount
- a geometry shader to cull out vertices that shouldn't be rendered
(because their face is too steep/not facing the right direction to
realistically hold snow) and generate geometry to close the gap between
the underlying object and the offset surface.
- a fragment shader to apply a normal map and compute ambient and diffuse
lighting in tangent space, before outputting the fragment color.

<div align="center">
  <img src="./resources/snow-cover-shader.gif" alt="Shader demo in Unity"/>
  <p><i>Shader demo in Unity</i></p>
</div>

#### Disclaimers

This shader was developed under Unity, but all Unity's built-in functions
and macros were abstracted to make it usable in other softwares, however
due to a lack of time, I wasn't able to test it in a different software.
Also, some of the maths might be wrong, again, due to a lack of time and
too optimistic ambitions that led to a lot of research and rewritings.

#### Demo

The [releases page](https://github.com/adrienlucbert/thuas-effects-shaders-gold1/releases)
of this repository contains a demo built for different platforms.
In this demo, you can have a look around with a free camera, and adjust snow
thickness and amount.

Controls:

- wasd/arrows: move camera in the world
- right click + mouse: free lock
- shift: fast movement mode

<div align="center">
  <img src="./resources/snow-cover-shader-demo.gif" alt="Shader demo game"/>
  <p><i>Shader demo game</i></p>
</div>

## Credits

This project is the work of [Adrien Lucbert](https://github.com/adrienlucbert),
and the Effects & Shaders class was given by Vincent Broeren.
