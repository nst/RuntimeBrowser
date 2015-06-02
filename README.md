RuntimeBrowser
==============

This is a class browser for the Objective-C runtime on iOS and OS X. It gives you full access to all classes loaded in the runtime; allows you to dynamically load new modules and their classes; shows every method implemented on each class; and displays information in a header (.h) file format.

We have found this to be a useful development tool. Please note, however, that each user is responsible for their own usage.

The [original version](http://www.prajnait.com/source/src_RuntimeBrowser.html) was released in April 2002 by Ezra Epstein. The project is maintained by Nicolas Seriot since August, 2008.

### iOS Version

  * browse by class tree, image or indexed list
  * search in classes names
  * headers retrieval through HTTP port 10000
  * instantiates most classes including allocation of non-shared instances
  * allows invocation of methods including inputting of parameters at runtime

You can browse the [iOS headers](https://github.com/nst/iOS-Runtime-Headers) as seen by RuntimeBrowser.

![RuntimeBrowser](art/screenshot_iphone.png "RuntimeBrowser iPhone")
![RuntimeBrowser](art/screenshot_iphone_2.png "RuntimeBrowser iPhone")
    
### OS X Version

Latest build: 2015-06-03 [http://seriot.ch/temp/runtimebrowser_0.991.zip](http://seriot.ch/temp/runtimebrowser_0.991.zip) 275 KB

  * browse by class tree, image, list or protocols
  * search in classes contents
  * syntax colorization
  * drag and drop frameworks and headers

![Screenshot](art/screenshot.png "RuntimeBrowser Mac OS X")
