#Requires AutoHotkey v2+

#Include scaling.ahk
#Include colors.ahk
#Include coords.ahk

isDbdFinishedLoading() {
    ; The text of the ESC button moves around at different resolutions.
    ; The gear icon is more stable. Check the rightmost spoke for whiteishness.
    escText := scaled.getColor(438, 1350)
    escTextIsWhite := isWhiteish(escText, 0x70)

    ; Main menu: Middle of the red '<' arrow
    ; Can be a dark red without reshade filters, so we must look at hue rather than red component intensity
    backArrow := scaled.getColor(137, 1345)
    backArrowIsRed := isRedish(backArrow)

    return escTextIsWhite && backArrowIsRed
}

backEscWhiteE := Coords2K(239, 1348)
backRedArrow := Coords2K(137, 1345)
isSettingsOpen() {
    settingsWhiteishMatchDetailsE := coords.getColor(backEscWhiteE)
    settingsRedishBackArrow := coords.getColor(backRedArrow)

    w := isWhiteish(settingsWhiteishMatchDetailsE, 0xB0)
    r := isRedish(settingsRedishBackArrow)
    return w && r
}

isSettingsGraphicsTabSelected() {
    ; 'R' of 'GRAPHICS': (950, 100)
    colorGraphicsR := scaled.getColor(950, 100)
    return isWhiteish(colorGraphicsR)
}

isSettingsGraphicsFpsMenuOpen() {
    ; Check for the base of the 2 of the 120: (1771, 1100)
    colorFps120 := scaled.getColor(1771, 1100)
    return isWhiteish(colorFps120)
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

        logger.debug("(" x ", " y ")=" color " isBright=" isBright " isDesaturated=" isDesaturated " s=" s)

        return isBright && isDesaturated
    }

    logger.debug("tens:")
    if (dbdWindow.height = 1080) {
        digit10 := isLit(601, 101) ? isLit(610, 99) ? isLit(601, 107) ? isLit(606, 102) ? isLit(604, 110) ? 8 : -1 : isLit(601, 106) ? 0 : -1 : isLit(605, 104) ? 9 : -1 : isLit(602, 95) ? isLit(601, 109) ? 5 : -1 : isLit(601, 106) ? 6 : -1 : isLit(610, 106) ? isLit(602, 96) ? isLit(603, 97) ? 3 : -1 : isLit(601, 106) ? 4 : -1 : isLit(610, 110) ? isLit(603, 97) ? 2 : -1 : isLit(610, 95) ? isLit(604, 107) ? 7 : -1 : isLit(603, 97) ? 1 : -1
    } else if (dbdWindow.height = 1440) {
        digit10 := isLit(802, 141) ? (isLit(796, 139) ? (isLit(798, 148) ? (isLit(807, 134) ? (9) : (-1)) : (isLit(804, 147) ? (4) : (-1))) : (isLit(809, 149) ? (isLit(807, 149) ? (2) : (-1)) : (isLit(809, 127) ? (isLit(804, 136) ? (7) : (-1)) : (isLit(803, 148) ? (1) : (-1))))) : (isLit(808, 133) ? (isLit(802, 137) ? (isLit(796, 140) ? (isLit(804, 147) ? (8) : (-1)) : (isLit(805, 140) ? (3) : (-1))) : (isLit(806, 133) ? (0) : (-1))) : (isLit(808, 127) ? (isLit(800, 137) ? (5) : (-1)) : (isLit(801, 136) ? (6) : (-1))))
    }

    logger.debug("ones:")
    if (dbdWindow.height = 1080) {
        digit1 := isLit(615, 101) ? isLit(624, 99) ? isLit(615, 107) ? isLit(620, 102) ? isLit(618, 110) ? 8 : -1 : isLit(615, 106) ? 0 : -1 : isLit(619, 104) ? 9 : -1 : isLit(616, 95) ? isLit(615, 109) ? 5 : -1 : isLit(615, 106) ? 6 : -1 : isLit(624, 106) ? isLit(616, 96) ? isLit(617, 97) ? 3 : -1 : isLit(615, 106) ? 4 : -1 : isLit(624, 110) ? isLit(617, 97) ? 2 : -1 : isLit(624, 95) ? isLit(618, 107) ? 7 : -1 : isLit(617, 97) ? 1 : -1
    } else if (dbdWindow.height = 1440) {
        digit1 := isLit(820, 141) ? (isLit(814, 139) ? (isLit(816, 148) ? (isLit(825, 134) ? (9) : (-1)) : (isLit(822, 147) ? (4) : (-1))) : (isLit(827, 149) ? (isLit(825, 149) ? (2) : (-1)) : (isLit(827, 127) ? (isLit(822, 136) ? (7) : (-1)) : (isLit(821, 148) ? (1) : (-1))))) : (isLit(826, 133) ? (isLit(820, 137) ? (isLit(814, 140) ? (isLit(822, 147) ? (8) : (-1)) : (isLit(823, 140) ? (3) : (-1))) : (isLit(824, 133) ? (0) : (-1))) : (isLit(826, 127) ? (isLit(818, 137) ? (5) : (-1)) : (isLit(819, 136) ? (6) : (-1))))
    }

    logger.debug("digit10=" digit10 " digit1=" digit1)

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

isHookSpaceOptionAvailable() {
    ; Head of the "carried survivor" icon.
    ; Chosen because it is not white in the same spot as the "Blight Rush" icon.
    colorHead := scaled.getColor(227, 1254)

    ; White part of the 'A' of the "[SPACE] HANG" prompt.
    colorSpaceA := scaled.getColor(1235, 1265)

    ; Black background of the "[SPACE] HANG" prompt to disqualify an all white screen.
    colorSpaceBg := scaled.getColor(1235, 1269)

    return colorHead = 0xFFFFFF && colorSpaceA = 0xFFFFFF && colorSpaceBg = 0x000000
}

tallyLeftArrowWhite := Coords2K(367, 1196)
tallyLeftArrowDark := Coords2K(353, 1193)

tallyRightArrowWhite := Coords2K(859, 1197)
tallyRightArrowDark := Coords2K(872, 1194)

tallyContinueButtonRed := Coords2K(2421, 1348)

isTallyScreen() {
    isLeftArrowWhiteish() => isWhiteish(coords.getColor(tallyLeftArrowWhite))
    isLeftArrowBlackish() => isBlackish(coords.getColor(tallyLeftArrowDark),, tolerance := 10)

    isRightArrowWhite() => isWhiteish(coords.getColor(tallyRightArrowWhite))
    isRightArrowBlackish() => isBlackish(coords.getColor(tallyRightArrowDark),, tolerance := 10)

    isContinueButtonRedish() => isRedish(coords.getColor(tallyContinueButtonRed))

    return isLeftArrowWhiteish() && isLeftArrowBlackish() && isRightArrowWhite() && isRightArrowBlackish() && isContinueButtonRedish()
}

tallyScoreMatchText := Coords2K(158, 630)
isTallyBloodpointsScreen() => isWhiteish(coords.getColor(tallyScoreMatchText), threshold := 0xF8)

cancelButtonRedMarker := Coords2K(2435, 1272)
isReadiedUp() => isRedish(coords.getColor(cancelButtonRedMarker))

readyButtonRedBar := Coords2K(2430, 1257)
readyButtonWhiteR := Coords2K(2278, 1260)
isReadyButtonVisible() {
    return isRedish(coords.getColor(readyButtonRedBar)) and isWhiteish(coords.getColor(readyButtonWhiteR), threshold := 0x90)
}
