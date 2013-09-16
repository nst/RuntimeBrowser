RuntimeBrowser
==============

![RuntimeBrowser](art/screenshot_iphone.png "RuntimeBrowser iPhone")

This is a class browser for the Objective-C runtime on iOS and OS X. It gives you full access to all classes loaded in the runtime; allows you to dynamically load new modules and their classes; shows every method implemented on each class; and displays information in a header (.h) file format.

We have found this to be a useful development tool. Please note, however, that each user is responsible for their own usage.

The [original version](http://www.prajnait.com/source/src_RuntimeBrowser.html) was released in April 2002 by Ezra Epstein. The project is maintained by Nicolas Seriot since August, 2008.

The iOS version features:

  * browse by class tree, image or indexed list
  * search in classes names
  * headers retrieval through HTTP
  * instantiates most classes including allocation of non-shared instances
  * allows invocation of methods including inputting of parameters at runtime
  
Latest build of the original Runtime Browser: [http://seriot.ch/temp/runtimebrowser.zip](http://seriot.ch/temp/runtimebrowser.zip)

The OS X version features:

  * browse by class tree, image or indexed list
  * search in classes contents
  * syntax colorization
  * drag and drop frameworks and headers

You can browse the [iOS headers](https://github.com/nst/iOS-Runtime-Headers) as seen by RuntimeBrowser.

![Screenshot](art/screenshot.png "RuntimeBrowser Mac OS X")

Shmoopi Additions
--------------

![RuntimeBrowser](art/screenshot_iphone_2.png "RuntimeBrowser iPhone")

The iOS version now features:

  * better invocation of methods and allocation of classes
  * smarter output handling from invocations
  * better handling of failing messages and void returns from output
  * now instantiates most all classes including allocation of non-shared instances
  * allows invocation of most all methods
  * input parameters at runtime