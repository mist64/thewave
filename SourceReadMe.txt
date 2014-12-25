INSTRUCTIONS FOR BUILDING THE WAVE

Note: The information contained here is mainly useful for programmers only, or for those that would be interested in learning how to program, especially in the Wheels or GEOS environment. Normal users do not need these source code files in order to enjoy using The Wave. It is also assumed that anyone diving into this source code package is already familiar with assembly language programming as well as programming in GEOS. By the time you get done studying this code, you'll know a great deal about programming in Wheels!

Included in this archive are all the source code files needed to recreate The Wave 64 V1.0 and The Wave 128 V1.0.

Other files you will need are geoWrite for editing the source code and Concept for assembling and linking. Concept is available for free downloading from:

http://www.ia4u.net/~maurice/concept.htm

It's also available from The SpeedZone BBS at: (517) 322-2386

The two symbol and equate files, WheelsSyms and WheelsEquates are included in the Concept package, however, the two versions of these files included with The Wave source code should be used for assembling The Wave. There are some additions to these files and if you use the older versions, you'll get a few errors due to the missing symbols and equates.

The font used throughout the source code files is CourierNLQ and is also included in this package.

Other support files included with this package are:

geosMac (macro file that may not actually be used anymore)
superMac (macro file that simulates some of the 65816 opcodes)
TermEquates (equate file containing specific equates)

To build The Wave, you'll want to set up a native partition on either a CMD HD or a RamLink. The partition must be at least 2megs in size, preferably larger. After copying all the needed files to the partition and doing all the assembling and linking, there will only be about 150-200K free. So, if you want to add other applications as well as additional files such as the fonts and documentation files that go along with The Wave, then you should consider creating a larger partition.

I like to begin with an empty partition and then I create a system directory. In this system directory, I put Concept, geoWrite, geoPaint, photo manager, text manager, Finder, the CourierNLQ font, WheelsSyms, WheelsEquates, superMac, and geosMac.

Then I make a subdirectory called "MAIN". I attach the same system directory to this subdir. In this MAIN subdir, I copy all of the source code files.

I can also create additional subdirs to hold other projects such as the installer application that I wrote for The Wave. Other subdirs might hold a bunch of HTML files for testing purposes. If you plan on adding additional subdirs for other support projects, be sure to begin with a large enough partition.


GETTING FAMILIAR WITH THE CODE

Now it's time to get down to business. First let's understand how I've currently got the source code files organized. I've arranged the code to accomodate both the 64 and 128 versions. Throughout much of the code there is conditional assembly used. What this means is that a variable can be defined and during assembly, whenever an .if statement is encountered, the variable that is being referenced will determine if that portion of the code gets assembled or ignored. As an example, if we were building Wave128, there is a variable called "C128" and one called "C64". The variables might be defined as follows:

C64=0
C128=1

Now, if we assemble the source code containing these definitions, the areas intended for the 128 will be assembled and the areas intended for the 64 will be ignored. Here's an example of some conditional assembly:

.if C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif

The above code won't assemble because the statement asks ".if C64". Since C64=0, the statement is false and this code will be ignored. This code segment is ended with the ".endif". Assembly will continue past that point. The next example is similar and will result in some assembly occuring for the 128.

.if C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.else
	LoadB	$ff00,#$7e
.endif

Since we added an ".else" in there, the assembler skipped the part pertaining to the 64 and assembled the part between .else and .endif. We could have just as easily written the code this way:

.if C128
	LoadB	$ff00,#$7e
.else
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif

In a sense, the .else here means "if not C128". We could also do it like this:

.if C128
	LoadB	$ff00,#$7e
.endif
.if C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif

But that looks more like two different pieces of code, so I generally don't do it that way unless the code segments are large and span multiple pages.


So, by using conditional assembly, I've been able to use the same source code files for both versions and this has helped me to keep both versions absolutely identical in their operations. Where conditional assembly is used is generally only in the parts that pertain to the actual 64 or 128 hardware or the difference between the two screen displays, or perhaps the difference between the two operating systems.

Now, some of the source code files do not have any conditional assembly used since nothing within those particular files cares what machine it's running on. Those files are then assembled directly. For the files that contain conditional assembly, they cannot be assembled directly or you'll get errors. There are separate files for the 64 and 128 that are assembled, and these files use the ".include" directive that will tell the assembler to assemble the desired file. In addition to the .include directive, these files each define the C64 and C128 variables according to the intended machine.

As an example, the source code file "TCPCode" doesn't have any routines that are specific to the machine or screen display. This file can be assembled directly. On the other hand, the file "VT100" contains routines that access the screen display. You can't assemble this file without errors. Instead, you would assemble "VT10064" for the 64 and "VT100128" for the 128.

To know which files to assemble, all you need to do is study the linker files. There are four linker files included here, two for the 64 and two for the 128. Once you've run the assembler and assembled all the correct files, you then run the linker and this will take all the .rel files the assembler created and link them together into the final files that are needed. The four linker files are:

Wave64.lnk	(this creates Wave64)
System64.lnk	(this creates System64)
Wave128.lnk	(this creates Wave128)
System128.lnk	(this creates System128)

In the linker files, you'll see all the .rel files that the linker will look for. If during the linking process, it tells you it can't find a particular .rel file, that means you forgot to assemble one of the source code files. Each .rel file has a matching source code file. For example, to create the file "BrowseA128.rel", you would assemble the file "BrowseA128". The actual source code for this would be in the file "BrowseA". You can find this out by loading BrowseA128 into geoWrite and scroll down near the bottom of the page.


READY TO ASSEMBLE AND LINK

Time to build this thing (or things). Load up geoWrite and load in one of the linker files, such as Wave64.lnk. Print this file out. Then do the same for the other three linker files. With the printed copies in your hand, you can check off the files as you assemble them. Look at the list of files and find anything that ends with ".rel". The matching source code file for each of these .rel files needs to be assembled. If everything is set up correctly, and you have all the correct files on your partition, each one of the files should assemble without error.

If you look at each of these 4 linker printouts, you'll notice a few of the files are repeated in each one. This was another method I used to keep certain routines and memory areas available to each of the finished code files. Once one of these repeated files are assembled, you don't have to assemble it again when working on another list of files. The source code files that are repeated between each of the linker lists are "WaveVars" and "RamSect". One thing to keep in mind is if you modify either of these two files, you'll have to rerun the linker on each of the four .lnk files again. Changing anything in these two files affects both the Wave64 and System64 files as well as the Wave128 and System128 files. 

Hopefully you've been successful in assembling every single file that's needed by the linker. Now it's time to run the linker. From the file requestor, just select one of the .lnk files. When the linker is finished, select the next .lnk file. Continue on until you've successfully run the linker on all four .lnk files. Once finished, you will have created the main files that make up The Wave for both the 64 and 128.

The beauty of this system is that you can make a change to any one of the source code files and then you run the assembler only on the altered file. You don't have to reassemble each and every source code file. Once finished with the assembler, then simply run the linker again to relink the .rel files again. For instance, if you alter the VT100 source code, you would relink Wave64 and Wave128 since the VT100 file is a part of these. You don't have to relink System64 and System128. Making changes and testing is quick and easy, especially if you are doing this all with a RamLink and SuperCPU.


TIME TO TEST

Now that you've created The Wave, you need to test it. Prior to this, you should have already downloaded the Wave package that any user would normally get. This package contains the same thing that you just created plus all the font files that are needed by the browser and the terminal. Put all of these files into a separate partition or ramdisk for testing.

NOTE: Remember, you can't run The Wave from a subdirectory, it must be in a root directory if used in a native partition.

Copy either Wave64 and System64 or Wave128 and System128 to the desired partition or disk. Or copy all 4! They can exist together on the same disk or partition. Then copy all of the font files including the FontList64 and/or the FontList128 files to the disk. Then just run Wave64 or Wave128 like you normally would. If it seems to operate just like the version you downloaded and doesn't crash or do strange things, then you were most likely successful in assembling and linking.

Congratulations!


UNDERSTANDING THE CODE

You now have a development system that you can study and learn from, or you can modify it to suit your own needs and tastes. Maybe there's something about the software you don't like... fix it! You can do that now once you've become familiar with the code.

There currently isn't a great deal of comments in the code, but some of the more important routines are commented and in most cases, the labels used to identify the routines are fairly well self-explanatory.

Here's a brief rundown on how some of the code is laid out. It begins by executing the code within the file "Wave2Init". Once the software is up and running, most all of the code in this file will be overwritten since it's not needed anymore and no sense in taking up memory with code that won't be used. This code does most of the initial setting up of the machine. It checks to make sure Wheels V4.2 or higher is running, it checks for a SCPU with SuperRAM, and then it installs The Wave as the default desktop. It loads in more code from the Wave and System files and stashes them into designated banks in the SuperRAM. This code in the SuperRAM will be executed as needed during the operation of the software. It also sets up the font database that resides in memory, and a number of other things. After this is all done, it calls a routine to load in the Bank 0 main jump tables and other routines that are needed most of the time and then loads in the browser code. The user will then see the browser begin to appear on the screen. Once everything is all set up and configured, a final rts turns control over to the kernal's MainLoop code and we then wait for user input.


Let's look at the source code files and get a rough idea of basically what might be found in each one. First the files from Wave64 and Wave128:

WaveVars - this contains definitions of jump tables and variable locations as well as buffer allocations.
WaveInit - This started out containing the main initialization code until it got too big. But it also contains code that remains in memory all the time and never got renamed accordingly. This code begins at $1800. This also .includes the Modem file which contains mostly modem specific code.
Wave2Init - this is all initialization code that runs when first started or partially when returning from an application.
RamSect - variables accessible to every part of the software. This occupies $1000-$17ff.
Main - this contains the main jump tables as well as the routines that permit calling routines that reside in other banks.
LowLvl - this holds a lot of routine stuff that's needed. Not sure why I called it LowLvl, probably it started out as code from an older program I wrote a while back. This is loaded along with the code from Main into the area at $2300.
BrowseA, BrowseB, BrowseC, BrowseRam - these make up the browser code that resides in Bank 0. This code is loaded in at $3500 whenever the browser is on the screen. The code resides in SuperRAM when not being used.
AscTermA, AscTermB, VT100, AscTermC - These make up the portion of the terminal that resides in Bank 0. This is loaded into the same area of memory that the browser is loaded to at $3500. So, in the current version, the browser and terminal cannot run at the same time. This also resides in SuperRAM when not being used.
ExtModA, SelDestDir - This contains code mostly for file requestors. This is stashed into the SuperRAM but is swapped into Bank 0 when needed. Once finished, it gets swapped back out.
ExtModBa, ExtModBb - This contains mostly messages. This is stashed into the SuperRAM but is swapped into Bank 0 when needed. Once finished, it gets swapped back out.
ExtModCa, ExtModCb - This contains mostly the BBS and ISP directory functions. There is also some code to get an Internet session started but not the actual PPP or TCP code. This is stashed into the SuperRAM but is swapped into Bank 0 when needed. Once finished, it gets swapped back out.
SLDriver - This is the code that controls the modem interface. This currently controls the SwiftLink and the Turbo232. Different code here could allow different interfaces to be used.
PPPBank0 - This is the PPP output code. This resides in Bank 0 for speed and other reasons.


Now let's look at the files that are a part of System64 or System128. The code in these files are all stashed into the SuperRAM and are run from there, except for what's in the RamSect file.

WaveVars and RamSect - same as for Wave64 and Wave128.
Prg2Jump - This holds jump tables that access various routines within a SuperRAM bank.
PPP1Link - This doesn't really hold any PPP code but is named this because it originally was called PPPLink but got too big and had to be separated into two files. This mainly contains the dialer code now, but is sorta related to the PPP code because it gets the modem dialed out to the ISP.
PPP2Link - This contains most all of the PPP code except for a small part in the PPPBank0 file.
TCPCode - This is mostly TCP/IP code with some other needed stuff.
XYModem - This holds the XModem and YModem code mostly. It's still controlled from some other routines in the ExtModA file which calls this code.
HTTP - This holds the code that fetches web pages.
Telnet - Most of the telnet code is contained within the terminal code, but some of it is also in this file.
Dos1Stuff - I'm beginning to move some routines into here for disk access, etc.
KrnlStuff - Same with this file. This also .includes Krnl2Stuff.
Parse1HTML, Parse2HTML, Parse3HTML, Parse4HTML, UpperRam - This is all the stuff that parses HTML code. The HTML code must already be in memory when calling this.


That about wraps it up. Hopefully you can make some sense of all this. I know it's sometimes difficult to understand someone else's code. And even I will forget how some of this works if I don't stay with it right along. There's an awful lot to keep track of here.

Feel free to use bits and pieces of this source code in your own programming. You'll find ways to do most anything here. Anything from telecommunications to disk and file access, to screen handling and font handling. You'll see how to handle user input in different ways. You'll discover how to deal with the SuperCPU and its SuperRAM. You might even find places where I've goofed up, who knows?

Copy this code, rearrange it, organize it, steal it, whatever... take it and build some exciting new applications for GEOS and Wheels users. There's a great deal of excitement left in these old computers.

Have fun and enjoy.

-Maurice
