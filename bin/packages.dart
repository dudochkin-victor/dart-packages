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

import 'dart:async';
import 'package:console_log_handler/print_log_handler.dart';
import 'package:packages/packages.dart';
import 'package:args/args.dart';

Future main(final List<String> arguments) async {
    final Logger _logger = new Logger("packages.cmdline.main");

    final Packages packages = new Packages();
    final List<GlobalPackage> globals = await packages.globals;
    final _Application application = new _Application();

    _configLogging("info");

    try {
        final ArgResults results = application.parse(arguments);
        final _Printer printer = results.wasParsed("verbose") ? new _DetailsPrinter() : new _Printer();
        final _GlobalPrinter globalPrinter = results.wasParsed("verbose") ? new _GlobalDetailsPrinter() : new _GlobalPrinter();

        if(results.wasParsed("help")) {
            application.showUsage();
            return;
        }

        if(results.wasParsed("list")) {
            packages.all.forEach((final Package package) {
                printer.show(package);
            });
            return;
        }

        if(results.wasParsed("globals")) {
            globals.sort((a,b) => (a.hasPath && !b.hasPath ? -1 : 1));
            globals.forEach((final GlobalPackage package) {
                globalPrinter.show(package);
            });
            return;
        }

        if(results.rest.isEmpty) {
            application.showUsage();
            return;
        }

        final String request = results.rest.first;
        try {
            final String package = request.startsWith("package:") ? request : "package:$request";
            printer.show(packages.resolvePackageUri(Uri.parse(package)));

        } catch (error) {
            final List<GlobalPackage> _packages = globals.where(
                    (final GlobalPackage package) => package.packagename == request);
            if(_packages.isNotEmpty) {
                globalPrinter.show(_packages.first);
            } else {
                _logger.shout(error);
            }
        }

    } on FormatException catch(error) {
        _logger.shout(error.message);
        application.showUsage();
    }
}

class _Application {
    static const APPNAME  = 'packages';

    final ArgParser _argparser = _createArgParser();

    _Application();

    ArgResults parse(final List<String> arguments) => _argparser.parse(arguments);

    void showUsage() {
        print("Usage: $APPNAME [options] <packagename>");

        print(_argparser.usage);
    }

    //- private --------------------------------------------------------------------------------------------------------

    static ArgParser _createArgParser() {
        return new ArgParser()
            ..addFlag("help", abbr: "h", help: "Shows this help information")
            ..addFlag("list", abbr: "l", help: "Lists all packages")
            ..addFlag("globals", abbr: "g", help: "Lists all global packages")
            ..addFlag("verbose", abbr: "v", help: "More package details")
        ;
    }

}

class _Printer {
    void show(final Package package) {
        print("${package.packagename.padRight(25)} -> ${package.lib.path}");
    }
}

class _GlobalPrinter {
    void show(final GlobalPackage package) {
        if(package.hasPath) {
            print("${package.packagename.padRight(25)} -> ${package.path.value}");
        } else {
            print("${package.packagename.padRight(25)}");
        }
    }
}

class _DetailsPrinter extends _Printer {
    //static final int _MARGIN = 4;

    @override
    Future show(final Package package) async {
        final Uri resource = await package.resource;

        print("Name: ${package.packagename}");
        print("    Lib: ${package.lib.toString()}");
        print("    Uri: ${package.uri.toString()}");
        print("    Root: ${package.root.toString()}");
        print("    Resource: ${resource.toString()}");
    }
}

class _GlobalDetailsPrinter extends _GlobalPrinter {
    void show(final GlobalPackage package) {
        print("Name: ${package.packagename}");
        print("    Version: ${package.version}");

        if(package.hasPath) {
            print("    Path: ${package.path.value}");
        }
    }
}


void _configLogging(final String loglevel) {
    hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

    // now control the logging.
    // Turn off all logging first
    switch (loglevel) {
        case "fine":
        case "debug":
            Logger.root.level = Level.FINE;
            break;

        case "warning":
            Logger.root.level = Level.SEVERE;
            break;

        default:
            Logger.root.level = Level.INFO;
    }

    Logger.root.onRecord.listen(new LogPrintHandler());
}



