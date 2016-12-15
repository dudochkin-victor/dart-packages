part of packages;

/*
 * Copyright (c) 2016, Michael Mitterer (office@mikemitterer.at),
 * IT-Consulting and Development Limited.
 *
 * All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/// Resolves packages-Names
class Packages {
    static const String _FILENAME = ".packages";

    final File packagesFile = new File(_FILENAME);
    final Map<String,String> _packages = new Map<String,String>();

    Package resolvePackageUri(final Uri uri) {
        if(_packages.isEmpty && hasPackages) {
            _readPackagesFile();
        }

        if(uri.scheme != "package") {
            throw new ArgumentError("This is not a valid package-URI! Scheme must be 'package' but was '${uri.scheme}'");
        }

        if(uri.path == null || uri.path.isEmpty) {
            throw new ArgumentError("Invalid package path! (${uri})");
        }

        // First path element ist the packagename
        final String packagename = path.split(uri.path)[0].trim();

        if(packagename.startsWith(r"\W")) {
            throw new ArgumentError("Invalid packagename: ($packagename)!");
        }

        if(!_packages.containsKey(packagename)) {
            throw new RangeError("Could not find $packagename in your .packages-File");
        }

        return new Package(uri,packagename,Uri.parse(path.normalize(_packages[packagename])));
    }

    /// Returns all packages in .packages-File
    List<Package> get all {
        if(_packages.isEmpty && packagesFile.existsSync()) {
            _readPackagesFile();
        }
        final List<Package> packages = new List<Package>();
        _packages.keys.forEach((final String packagename) {
            packages.add(resolvePackageUri(Uri.parse("package:$packagename")));
        });
        return packages;
    }

    /// Returns true if .packages-File is available
    bool get hasPackages {
        return packagesFile.existsSync();
    }

    //- private --------------------------------------------------------------------------------------------------------

    /// Reads the lines from a .packages file
    ///
    /// Format:
    ///     bignum:file:///Users/mikemitterer/.pub-cache/hosted/pub.dartlang.org/bignum-0.1.0/lib/
    ///     mobiad_rest_ui_mdl:../../lib/
    void _readPackagesFile() {
        final List<String> lines = packagesFile.readAsLinesSync();

        _packages.clear();
        lines.where((final String line) => line.contains(":") && !line.trim().startsWith("#"))
            .forEach((final String line) {

            final int index  = line.indexOf(":");
            final String package = line.substring(0,index);         // e.g. bignum or mobiad_rest_ui_mdl
            final String packagePath = line.substring(index + 1);   // e.g. ../../lib/

            _packages[package] = packagePath;
        } );
    }
}

/// Details about the requested package
class Package {
    /// The packagename defined in pubspec.yaml
    final String packagename;

    /// The basis for the request
    ///
    /// e.g. package:foo/bar.txt
    final Uri _base;

    /// Absolute path to package
    ///
    /// Can be a relative path like "../../lib" or can start with "file:///..."
    /// "lib" for the requesting library/package
    ///
    /// E.g. if the "packages" library ask for "lib" it returns "lib"
    final Uri lib;

    Package(this._base, this.packagename,this.lib);

    /// Uri to localhost
    Future<Uri> get resource {
        return Isolate.resolvePackageUri(_base);
    }

    /// Full path to uri
    Uri get uri {
        return Uri.parse(path.normalize("${lib}${_base.path.replaceFirst(packagename,"")}"));
    }

    /// Package-root (without /lib at the end)
    ///
    /// The returned [Uri] always starts with "file://"
    /// Returns ALWAYS the full path to the package-root
    Uri get root {
        String packageRoot = lib.toString().replaceFirst(new RegExp(r"/lib$"),"");

        // "lib" indicates that
        // it refers to the package requesting this information
        if(packageRoot == "lib") {
            packageRoot = path.current;
        }
        if(!packageRoot.startsWith("file://")) {
            packageRoot = "file://${packageRoot}";
        }
        return Uri.parse(packageRoot);
    }
}