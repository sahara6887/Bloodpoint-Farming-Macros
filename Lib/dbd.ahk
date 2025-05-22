#Requires AutoHotkey v2.0

#Include scaling.ahk
#Include colors.ahk

isSettingsOpen() {
    ; 'E' of MATCH DETAILS (1999, 100)
    ; ']' of ESC: (295, 1350)
    settingsWhiteishMatchDetailsE := scaled.getColor(1999, 100)

    ; Red arrow `<` of back button to add further specificity
    settingsRedishBackArrow := scaled.getColor(133, 1350)

    return isWhiteish(settingsWhiteishMatchDetailsE, 0xD0) && isRedish(settingsRedishBackArrow)
}

getBloodwebLevel() {
    ; Decision-tree OCR.
    ; Highly efficient. Zero dependencies. Questionably reliable.
    ; Returns -1 if no level is present.
    ; TODO: Probably thinks a pure white screen is a digit.

    if (dbdWindow.height != 1080 && dbdWindow.height != 1440) {
        ; UI elements move around at other resolutions. It's not going to work.
        return -1
    }

    isLit(x, y) {
        ; Check if the pixel is plausibly text in the bloodweb.
        color := ops.getColor(x, y) ; no scaling! coords are specific to 1080 or 1440.

        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        hsl := RGBtoHSL(r, g, b)

        s := hsl[2]
        l := hsl[3]

        isBright := l >= 0xA0 / 0xFF
        isDesaturated := s < 0.15

        debug("(" x ", " y ")=" color " isBright=" isBright " isDesaturated=" isDesaturated " s=" s)

        return isBright && isDesaturated
    }

    debug("tens:")
    if (dbdWindow.height = 1080) {
        digit10 := isLit(602, 102) ? (isLit(609, 100) ? (isLit(601, 108) ? (isLit(605, 104) ? (isLit(603, 97) ? (8) : (-1)) : (isLit(602, 103) ? (0) : (-1))) : (isLit(605, 104) ? (9) : (-1))) : (isLit(602, 96) ? (isLit(601, 109) ? (5) : (-1)) : (isLit(601, 104) ? (6) : (-1)))) : (isLit(610, 108) ? (isLit(601, 98) ? (isLit(603, 97) ? (3) : (-1)) : (isLit(608, 107) ? (4) : (-1))) : (isLit(610, 112) ? (isLit(603, 97) ? (2) : (-1)) : (isLit(600, 96) ? (isLit(603, 97) ? (7) : (-1)) : (isLit(605, 104) ? (1) : (-1)))))
    } else if (dbdWindow.height = 1440) {
        digit10 := isLit(802, 141) ? (isLit(796, 139) ? (isLit(798, 148) ? (isLit(807, 134) ? (9) : (-1)) : (isLit(804, 147) ? (4) : (-1))) : (isLit(809, 149) ? (isLit(807, 149) ? (2) : (-1)) : (isLit(809, 127) ? (isLit(804, 136) ? (7) : (-1)) : (isLit(803, 148) ? (1) : (-1))))) : (isLit(808, 133) ? (isLit(802, 137) ? (isLit(796, 140) ? (isLit(804, 147) ? (8) : (-1)) : (isLit(805, 140) ? (3) : (-1))) : (isLit(806, 133) ? (0) : (-1))) : (isLit(808, 127) ? (isLit(800, 137) ? (5) : (-1)) : (isLit(801, 136) ? (6) : (-1))))
    }

    debug("ones:")
    if (dbdWindow.height = 1080) {
        digit1 := isLit(616, 102) ? (isLit(623, 100) ? (isLit(615, 108) ? (isLit(619, 104) ? (isLit(617, 97) ? (8) : (-1)) : (isLit(616, 103) ? (0) : (-1))) : (isLit(619, 104) ? (9) : (-1))) : (isLit(616, 96) ? (isLit(615, 109) ? (5) : (-1)) : (isLit(615, 104) ? (6) : (-1)))) : (isLit(624, 108) ? (isLit(615, 98) ? (isLit(617, 97) ? (3) : (-1)) : (isLit(622, 107) ? (4) : (-1))) : (isLit(624, 112) ? (isLit(617, 97) ? (2) : (-1)) : (isLit(614, 96) ? (isLit(617, 97) ? (7) : (-1)) : (isLit(619, 104) ? (1) : (-1)))))
    } else if (dbdWindow.height = 1440) {
        digit1 := isLit(820, 141) ? (isLit(814, 139) ? (isLit(816, 148) ? (isLit(825, 134) ? (9) : (-1)) : (isLit(822, 147) ? (4) : (-1))) : (isLit(827, 149) ? (isLit(825, 149) ? (2) : (-1)) : (isLit(827, 127) ? (isLit(822, 136) ? (7) : (-1)) : (isLit(821, 148) ? (1) : (-1))))) : (isLit(826, 133) ? (isLit(820, 137) ? (isLit(814, 140) ? (isLit(822, 147) ? (8) : (-1)) : (isLit(823, 140) ? (3) : (-1))) : (isLit(824, 133) ? (0) : (-1))) : (isLit(826, 127) ? (isLit(818, 137) ? (5) : (-1)) : (isLit(819, 136) ? (6) : (-1))))
    }

    debug("digit10=" digit10 " digit1=" digit1)

    ; Bloodweb level is left-aligned, so the tens digit actually houses levels 0-9 and the ones digit is empty.
    ; If tens digit is missing, then it's not a valid bloodweb level.
    if (digit10 = -1)
        return -1
    if (digit1 = -1)
        return digit10
    return digit10 * 10 + digit1
}

isAbandonEscapeOptionVisible() {
    ; Samples the [ESC] ABANDON button background in the top right
    ; in a spot that's common across keyboard (ESC), PS5 (OPTIONS)

    ; The button position moved for dbd 8.7.0.
    xShift := 9
    yShift := 19

    ; Black background
    bgLeftX := 2189 + xShift
    bgRightX := 2199 + xShift
    bgTopY := 82 + yShift
    bgBotY := 88 + yShift
    escBlackBg1 := scaled.getColor(bgLeftX, bgTopY)
    escBlackBg2 := scaled.getColor(bgRightX, bgTopY)
    escBlackBg3 := scaled.getColor(bgLeftX, bgBotY)
    escBlackBg4 := scaled.getColor(bgRightX, bgBotY)

    ; Outside of the button, which we assume to be non-black.
    fgLeftX := 2169 + xShift
    fgRightX := 2220 + xShift
    fgTopY := 43 + yShift
    fgBotY := 104 + yShift
    escNotBlackBg1 := scaled.getColor(fgLeftX, fgTopY)
    escNotBlackBg2 := scaled.getColor(fgRightX, fgTopY)
    escNotBlackBg3 := scaled.getColor(fgLeftX, fgBotY)
    escNotBlackBg4 := scaled.getColor(fgRightX, fgBotY)

    buttonIsBlack := escBlackBg1 = 0 and escBlackBg2 = 0 and escBlackBg3 = 0 and escBlackBg4 = 0
    surroundIsNotBlack := escNotBlackBg1 != 0 and escNotBlackBg2 != 0 and escNotBlackBg3 != 0 and escNotBlackBg4 != 0

    return buttonIsBlack and surroundIsNotBlack
}

isAbandonConfirmOpen() {
    ; After we click Abandon, we get a confirmation dialog
    ; It has a title of ABANDON in pure white
    global confirmWhiteA := scaled.getColor(1171, 380)
    global confirmWhiteN := scaled.getColor(1375, 372)
    return confirmWhiteA = 0xFFFFFF and confirmWhiteN = 0xFFFFFF
}