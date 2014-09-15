Aplaun
========

A portable OS with common features.
GPLv3 License

Aplaun OS
(Created by DivJ)

Add the BASIC folder to path by going in folder
and the command >> addpathc

## Setup
Format a pendrive(Careful).
Use any Hex Editor such as HxD to write boot.img on drive's first sector. Or use PartCopy? or dd (Linux).
Copy kernel.COM to pendrive.
Recommended: Copy the copythis folder contents to drive too.

## How to Boot
Tell what drive it is.(commonly it is 80).
Tell where FAT12 file is.(commonly it is 13).
Try first by 80:13 ,else 00:13 ,other than that god knows.
Press any key until Kernel file i.e. kernel.COM shows up and press Enter or Space.

## Contributing

1. [Fork it](https://help.github.com/articles/fork-a-repo)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](https://help.github.com/articles/using-pull-requests)

## Bug Tracker

Found a bug? Report it [here](https://github.com/Divyavrat/aplaun/issues/)!

## Feature Request

Have an idea? Add it [here](https://github.com/Divyavrat/aplaun/issues/)!

## License

##### Aplaun OS is released under the [General Public License , Version 3.0](http://www.gnu.org/licenses/gpl.html).

[General Public License text, Version 3.0](http://www.gnu.org/licenses/gpl-3.0.txt)

The full license text is included in `LICENSE` file.

## Authors

A full list of [contributors](https://github.com/Divyavrat/aplaun/graphs/contributors) can be found on GitHub.


## Acknowledgements

We would like to acknowledge 
the following open source projects used
for development of Aplaun OS -

MikeOS - BASIC interpreter, and Applications
(Also TachyonOS, CompOS)

BrokenThorn NeptuneOS - Bootloader and FAT12 driver

Sean Haas - Drek game
Mike Saunders - MikeOS
Joshua Beck - MikeOS apps