#Requires AutoHotkey v2.0

#Include ..\..\Lib\Gdip_All.ahk

class DbdTestWindow extends DbdWindowOps {
    __New(pBitmap) {
        if !pBitmap
            throw Error("DbdTestWindow requires a pBitmap")
        this.pBitmap := pBitmap
    }
    checkScale() {
        this._width := Gdip_GetImageWidth(this.pBitmap)
        this._height := Gdip_GetImageHeight(this.pBitmap)
    }
}

class TestOps extends WindowOps {
    __New(pBitmap) {
        if !pBitmap
            throw Error("TestOps requires a pBitmap")
        this.pBitmap := pBitmap
    }

    getColor(x, y) {
        return Gdip_GetPixel(this.pBitmap, x, y)
    }
}