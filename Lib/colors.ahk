#Requires AutoHotkey v2+

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

isWhiteish(color, threshold := 0xD0, tolerance := 5) {
    ; Most reshade filters leave near-pure-white pixels as near-pure-white.
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    lowSat := abs(r - g) < tolerance && abs(r - b) < tolerance
    brightEnough := r >= threshold
    return lowSat && brightEnough
}

isBlackish(color, threshold := 0x40, tolerance := 5) {
    ; Most reshade filters leave near-pure-white pixels as near-pure-white.
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    lowSat := abs(r - g) < tolerance && abs(r - b) < tolerance
    darkEnough := r <= threshold
    return lowSat && darkEnough
}

isRedish(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    hsl := RGBtoHSL(r, g, b)
    hue := hsl[1]
    sat := hsl[2]

    ; Reddish hue range: 0–20 or 340–360
    return (hue <= 20 || hue >= 340) and sat > 0.6 and r > 0x50
}