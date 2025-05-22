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


isWhiteish(color, threshold := 0xD0) {
    ; Most reshade filters leave near-pure-white pixels as near-pure-white.
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    lowSat := abs(r - g) < 5 && abs(r - b) < 5
    brightEnough := r >= threshold
    return lowSat && brightEnough
}

isRedish(color) {
    r := ((color >> 16) & 0xFF) / 255.0
    g := ((color >> 8) & 0xFF) / 255.0
    b := (color & 0xFF) / 255.0

    max := r, min := r
    if (g > max)
        max := g
    if (b > max)
        max := b
    if (g < min)
        min := g
    if (b < min)
        min := b

    delta := max - min

    if (delta = 0) {
        return false  ; grayscale (no hue)
    } else if (max = r) {
        hue := 60 * Mod(((g - b) / delta), 6)
    } else if (max = g) {
        hue := 60 * (((b - r) / delta) + 2)
    } else {
        hue := 60 * (((r - g) / delta) + 4)
    }

    if (hue < 0)
        hue += 360

    ; Reddish hue range: 0–20 or 340–360
    return hue <= 20 || hue >= 340
}