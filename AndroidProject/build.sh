#!/bin/sh
UNITYLIBS=`find -L /Applications/Unity | grep classes.jar | tail -1`
DSTDIR="../Plugins/NativeEditBox/Android"
export ANT_OPTS=-Dfile.encoding=UTF8
android update project -t android-18 -p .
mkdir -p libs
cp $UNITYLIBS libs
ant "-Djava.compilerargs=-Xlint:deprecation" release
mkdir -p $DSTDIR
cp -a bin/classes.jar $DSTDIR/NativeEditBox.jar
ant clean
rm -rf libs res proguard-project.txt