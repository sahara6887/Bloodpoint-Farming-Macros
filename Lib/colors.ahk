#Requires AutoHotkey v2.0

RGBtoHSL(r, g, b) {
    r := r / 255.0
    g := g / 255.0
    b := b / 255.0

    maxVal := Max(r, g, b)
    minVal := Min(r, g, b)
    l := (maxVal + minVal) / 2

    if (maxVal = minVal) {
        h := 0
        s := 0
    } else {
        d := maxVal - minVal
        s := (l > 0.5) ? d / (2 - maxVal - minVal) : d / (maxVal + minVal)

        if (maxVal = r)
            h := (g - b) / d + (g < b ? 6 : 0)
        else if (maxVal = g)
            h := (b - r) / d + 2
        else
            h := (r - g) / d + 4

        h := h / 6
    }

    return [h, s, l]  ; returns hue (0..1), saturation, lightness
}