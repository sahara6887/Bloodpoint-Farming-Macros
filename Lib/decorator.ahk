#Requires AutoHotkey v2+

/**
 * Forwards all method calls to the underlying object.
 */
class Decorator {
    underlying := -1

    __New(underlying) {
        this.underlying := underlying
    }

    __Call(method, args*) {
        return this.underlying.%method%(args*)
    }

    __Get(name, params*) {
        ; __Get is invoked on the meta object, not the instance.
        ; This means that the instance is not available in the normal way.
        ; ObjGetBase() avoids calling __Get which would cause infinite recursion.
        return ObjGetBase(this).underlying.%name%
    }

    __Set(name, value, params*) {
        return ObjGetBase(this).%name% := value
    }
}