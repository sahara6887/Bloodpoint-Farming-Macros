## Icons

.ico files can be created from any image using [imagemagick](https://imagemagick.org/).

```sh
magick Hook.png -define icon:auto-resize="128,96,64,48,32,16" hook.ico
```

Including multiple sizes is important for visual quality. Windows resizing isn't as pretty.

See [ImageMagick documentation](https://usage.imagemagick.org/thumbnails/#favicon) for more details. 
