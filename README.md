# Tiles
This was a test task for Yandex back in 2012.

## Assignment
The goal was to create a simplified version of MapKit with 1 layer of 100 by 100 tiles. 
Tile size should have been 128x128 px. Tiles were supposed to be downloaded from the 
internet (source didn't matter). Once beeing download tile should have been cached in a 
file system. 

Caching were assumed to be organized through separate library, written in plain C (without 
any frameworks or iOS SDK). That library was expected to be compilable and usable under
Linux or Windows.

Application were supposed to work on iOS 3.0. And no MapKit or 3-rd party frameworks 
(like Cocos3d) were allowed to use.

## Result
Application with hardcore multithreading that uses additional run loop and runs 60 fps. And a plain C cache 
that can be ported to any other platform.
