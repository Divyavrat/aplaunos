Aplaun OS
=========

A portable OS with common features.

Open Source with - **GPLv3 License**

(Created by DivJ)

[For any help visit wiki pages](https://github.com/Divyavrat/aplaun/wiki)

To run BASIC programs from any folder -

1. go in the BASIC folder >> `nm basic q q`
2. and add to path with the command >> `addpathc`

Setup
-----

1. Format a pendrive(Careful).
2. Use any Hex Editor such as *HxD* to write boot.img on drive's first sector.
	Or use PartCopy? or dd (Linux).
3. Copy **kernel.COM** to pendrive.

######Recommended: Copy the *copythis folder* contents to drive too.

How to Boot with older bootloader -
-----------------------------------

1. Tell what drive it is.(commonly it is 80).
2. Tell where FAT12 file is.(commonly it is 13).
3. Try first by 80:13 ,else 00:13 ,other than that god knows.
4. Press any key until Kernel file i.e. kernel.COM shows up and press Enter or Space.

Contributing
------------

You can contribute by making apps, games, testing
or even add modules to main system.

1. [Fork it](https://help.github.com/articles/fork-a-repo)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](https://help.github.com/articles/using-pull-requests)

We'd prefer if your contributions were well commented
for better understanding of its working and for ease in future use.

Bug Tracker
-----------

Found a bug? Report it [here](https://github.com/Divyavrat/aplaun/issues/)!

Any basic bug can be reported.
Odd results or un-handled features that we may have overlooked.

If a basic hardware is not working,
you can list out the used configuration.

Feature Request
---------------

We are happy to receive any suggestions or customizations.

Have an idea? Add it [here](https://github.com/Divyavrat/aplaun/issues/)!

License
-------

##### Aplaun OS
is released under the [General Public License , Version 3.0](http://www.gnu.org/licenses/gpl.html).

[General Public License text, Version 3.0](http://www.gnu.org/licenses/gpl-3.0.txt)

The full license text is included in `LICENSE` file.

Authors
-------

A full list of [contributors](https://github.com/Divyavrat/aplaun/graphs/contributors)
can be found on GitHub.

Acknowledgements
----------------

We would like to acknowledge
the following open source projects used
for development of **Aplaun OS** -

1. MikeOS - **BASIC** interpreter, and Applications (Also TachyonOS, CompOS)
2. BrokenThorn NeptuneOS - Bootloader and FAT12 driver
3. Sean Haas - **Drek** game
4. Mike Saunders - MikeOS
5. Leonardo Ono - **asm4mo** Assembler
6. Joshua Beck - MikeOS apps
