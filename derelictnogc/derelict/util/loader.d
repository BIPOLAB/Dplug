/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.util.loader;

import std.array,
       std.string;

import derelict.util.exception,
       derelict.util.sharedlib,
       derelict.util.system;

struct SharedLibVersion
{
    int major;
    int minor;
    int patch;
}

abstract class SharedLibLoader
{
    /++
     Constructs a new instance of shared lib loader with a string of one
     or more shared library names to use as default.

     Params:
        libNames =      A string containing one or more comma-separated shared
                        library names.
    +/
    nothrow @nogc
    this(string libNames) { _libNames = libNames; }

    /++
     Binds a function pointer to a symbol in this loader's shared library.

     Params:
        ptr =       Pointer to a function pointer that will be used as the bind
                    point.
        funcName =  The name of the symbol to be bound.
        doThrow =   If true, a SymbolLoadException will be thrown if the symbol
                    is missing. If false, no exception will be thrown and the
                    ptr parameter will be set to null.
     Throws:        SymbolLoadException if doThrow is true and a the symbol
                    specified by funcName is missing from the shared library.
    +/
    final void bindFunc(void** ptr, string funcName, bool doThrow = true) nothrow @nogc
    {
        void* func = loadSymbol(funcName, doThrow);
        *ptr = func;
    }

    /++
     Binds a function pointer to a stdcall symbol in this loader's shared library.

     On builds for anything other than 32-bit Windows, this simply delegates to bindFunc.

     Params:
        ptr =       Pointer to a function pointer that will be used as the bind
                    point.
        funcName =  The name of the symbol to be bound.
        doThrow =   If true, a SymbolLoadException will be thrown if the symbol
                    is missing. If false, no exception will be thrown and the
                    ptr parameter will be set to null.
     Throws:        SymbolLoadException if doThrow is true and a the symbol
                    specified by funcName is missing from the shared library.
    +/

     /+   void bindFunc_stdcall(Func)(ref Func f, string unmangledName)
        {
            // TODO
        }
        +/

    /++
     Finds and loads a shared library, using this loader's default shared library
     names and default supported shared library version.

     If multiple library names are specified as default, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exceptin chain containing one instance of the exception for each library
     that failed.

     Examples:  If this loader supports versions 2.0 and 2.1 of a shared libary,
                this method will attempt to load 2.1 and will fail if only 2.0
                is present on the system.

     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load() nothrow @nogc { load(_libNames); }

    /++
     Finds and loads any version of a shared library greater than or equal to
     the required mimimum version, using this loader's default shared library
     names.

     If multiple library names are specified as default, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exceptin chain containing one instance of the exception for each library
     that failed.

     Examples:  If this loader supports versions 2.0 and 2.1 of a shared library,
                passing a SharedLibVersion with the major field set to 2 and the
                minor field set to 0 will cause the loader to load version 2.0
                if version 2.1 is not available on the system.

     Params:
        minRequiredVersion = the minimum version of the library that is acceptable.
                             Subclasses are free to ignore this.

     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load(SharedLibVersion minRequiredVersion) nothrow @nogc
    {
        configureMinimumVersion(minRequiredVersion);
        load();
    }

    /++
     Finds and loads a shared library, using libNames to find the library
     on the file system.

     If multiple library names are specified in libNames, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exceptin chain containing one instance of the exception for each library
     that failed.

     Examples:  If this loader supports versions 2.0 and 2.1 of a shared libary,
                this method will attempt to load 2.1 and will fail if only 2.0
                is present on the system.

     Params:
        libNames =      A string containing one or more comma-separated shared
                        library names.
     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load(string libNames) nothrow @nogc
    {
        if(libNames == null)
            libNames = _libNames;

        // TODO support multiple paths
  /*      auto lnames = libNames.split(",");
        foreach(ref string l; lnames)
            l = l.strip();
        load(lnames);
        */

        //
        string[1] lnames;
        lnames[0] = libNames;
        load(lnames);
    }

    /++
     Finds and loads any version of a shared library greater than or equal to
     the required mimimum version, using libNames to find the library
     on the file system.

     If multiple library names are specified as default, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exceptin chain containing one instance of the exception for each library
     that failed.

     Examples:  If this loader supports versions 2.0 and 2.1 of a shared library,
                passing a SharedLibVersion with the major field set to 2 and the
                minor field set to 0 will cause the loader to load version 2.0
                if version 2.1 is not available on the system.

     Params:
        libNames =      A string containing one or more comma-separated shared
                        library names.
        minRequiredVersion = The minimum version of the library that is acceptable.
                             Subclasses are free to ignore this.

     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load(bool dummy = false)(string libNames, SharedLibVersion minRequiredVersion) // templated to infer attributes
    {
        configureMinimumVersion(minRequiredVersion);
        load(libNames);
    }

    /++
     Finds and loads a shared library, using libNames to find the library
     on the file system.

     If multiple library names are specified in libNames, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exception chain containing one instance of the exception for each library
     that failed.


     Params:
        libNames =      An array containing one or more shared library names,
                        with one name per index.

     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load(string[] libNames) nothrow @nogc
    {
        _lib.load(libNames);
        loadSymbols();
    }

    /++
     Finds and loads any version of a shared library greater than or equal to
     the required mimimum version, , using libNames to find the library
     on the file system.

     If multiple library names are specified in libNames, a SharedLibLoadException
     will only be thrown if all of the libraries fail to load. It will be the head
     of an exception chain containing one instance of the exception for each library
     that failed.

     Examples:  If this loader supports versions 2.0 and 2.1 of a shared library,
                passing a SharedLibVersion with the major field set to 2 and the
                minor field set to 0 will cause the loader to load version 2.0
                if version 2.1 is not available on the system.


     Params:
        libNames =      An array containing one or more shared library names,
                        with one name per index.
        minRequiredVersion = The minimum version of the library that is acceptable.
                             Subclasses are free to ignore this.

     Throws:    SharedLibLoadException if the shared library or one of its
                dependencies cannot be found on the file system.
                SymbolLoadException if an expected symbol is missing from the
                library.
    +/
    final void load(string[] libNames, SharedLibVersion minRequiredVersion) nothrow @nogc // templated to infer attributes
    {
        configureMinimumVersion(minRequiredVersion);
        load(libNames);
    }

    /++
     Unloads the shared library from memory, invalidating all function pointers
     which were assigned a symbol by one of the load methods.
    +/
    nothrow @nogc
    final void unload() { _lib.unload(); }


    /// Returns: true if the shared library is loaded, false otherwise.
    @property @nogc nothrow
    final bool isLoaded() { return _lib.isLoaded; }

protected:
    /++
     Must be implemented by subclasses to load all of the symbols from a
     shared library.

     This method is called by the load methods.
    +/
    // TODO
    abstract void loadSymbols() nothrow @nogc;

    /++
     Allows a subclass to install an exception handler for specific versions
     of a library before loadSymbols is called.

     This method is optional. If the subclass does not implement it, calls to
     any of the overloads of the load method that take a SharedLibVersion will
     cause a compile time assert to fire.
    +/
    nothrow @nogc
    void configureMinimumVersion(SharedLibVersion minVersion)
    {
        assert(0, "SharedLibVersion is not supported by this loader.");
    }

    /++
     Subclasses can use this as an alternative to bindFunc, but must bind
     the returned symbol manually.

     bindFunc calls this internally, so it can be overloaded to get behavior
     different from the default.

     Params:
        name =      The name of the symbol to load.doThrow =   If true, a SymbolLoadException will be thrown if the symbol
                    is missing. If false, no exception will be thrown and the
                    ptr parameter will be set to null.
     Throws:        SymbolLoadException if doThrow is true and a the symbol
                    specified by funcName is missing from the shared library.
     Returns:       The symbol matching the name parameter.
    +/
    nothrow @nogc
    void* loadSymbol(string name, bool doThrow = true)
    {
        return _lib.loadSymbol(name, doThrow);
    }

    /// Returns a reference to the shared library wrapped by this loader.
    @property @nogc nothrow
    final ref SharedLib lib(){ return _lib; }


private:
    string _libNames;
    SharedLib _lib;
}