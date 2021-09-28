# VappyPasta
The infamous Vaporeon Copypasta now on GameBoy

![Did you know?](https://user-images.githubusercontent.com/17131442/135097579-9b01ff6b-6b7c-4edf-8ce2-7a2643680de6.png)

## Using
This is pretty much a demo (and a meme). It just scrolls the infamous copypasta at the bottom of the screen. However, the code itself might be useful as a head start into programming on the GameBoy.

* A Button: Change Vappy's color
* Select: View Vappy's stats (100% not made up in the spot)
* B Button: Returns to the text scroller screen while in the Stats screen.

I recommend running it on [BGB](https://bgb.bircd.org/) or in hardware if you have a way. Haven't tested it in hardware myself but somebody did and it ran fine (YMMV).

## Assembling
To assemble you'll need WLA-DX. Get it from https://github.com/vhelin/wla-dx and follow installation instructions (in case you don't have it already).
These instructions are for Windows systems but should be easy to do on not-Windows.

### Manual way
* Run `wla-gb -i -o link.tmp head.asm` to generate a file for the Linker
* Create a new text file, call it `list.txt` and put these two lines in it:
```
[objects]
link.tmp
```

* Link the "files" to generate both a GameBoy ROM image and a Symbol list (for debugging) with this:
```
wlalink -b -v -i -s list.txt VappyPasta.gb
```

* Optionally delete `tmp` and `lst` files

### Automated way
On Windows, run `!assemble.bat` to backup the previous build and make a new one or `!rebuild.bat` to skip the backing up part. Note that these two require something close to the following folder structure:

```
some_folder/
- [other systems you might be programming for]
- CGB/
  - [this repo]
- WLADX/
  - binaries/
    - [compiled WLA binaries]
  - assemble.bat
```

To make things easier, here is `assemble.bat` https://gist.github.com/Xch3l/51055019a5eaf022a884b90b10886f04. Save it into WLADX and call this repo's own `!assemble.bat` or `!rebuild.bat`.

## License?
Not sure which license should apply to this but at least you're free to use the code however you want. Graphics obviously not because _y'know..._ except maybe the font (without some tiles in it of course).

## Vappy?
Yes. The she has a name. Coming from the comments in the code I've decided it was a cute name and since I've never played Pokémon in my life for a considerable amount of time, I figured _why not?_
