import pymouse

mouse = pymouse.PyMouse()
from math import sin, cos

theta = 0
while True:
  w, h = 1000, 720
  mouse.move(w/2 + w/2 * cos(theta), h/2 + h/2 * sin(theta))
  theta += 0.0001
