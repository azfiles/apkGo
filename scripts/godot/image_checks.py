"""Check rendered game regions so a live process or log marker alone cannot pass CI."""
from PIL import Image


def validate_frame(image: Image.Image, screen: str) -> bool:
    if image.size != (720, 1280):
        return False
    image = image.convert('RGB')

    def count(rect, predicate):
        return sum(predicate(*pixel) for pixel in image.crop(rect).getdata())

    def lime(r, g, b):
        return r > 145 and g > 190 and b < 175 and g > b * 1.3

    def white(r, g, b):
        return min(r, g, b) > 170 and max(r, g, b) - min(r, g, b) < 55

    if screen == 'home':
        return (count((40, 489, 680, 565), lime) > 20000
                and count((40, 45, 680, 300), white) > 500)
    if screen == 'play':
        return (count((40, 245, 220, 330), lime) > 200
                and count((40, 368, 680, 1008), white) > 500
                and count((40, 368, 680, 1008), lambda r, g, b: 15 < r < 45 and 35 < g < 75 and 40 < b < 80) > 25000)
    if screen in ('pause', 'restored'):
        return (count((80, 676, 640, 756), lime) > 20000
                and count((40, 304, 680, 379), lime) > 500
                and count((40, 520, 680, 590), white) > 300)
    return False
