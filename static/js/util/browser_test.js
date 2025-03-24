'use strict';
if ( ! window.omniframe ) window.omniframe = {};
window.omniframe.browser_test = ( function () {
    var run_tests = function () {
        var results = new Array;

        function ok( version, feature, command ) {
            var result = { version: version, feature: feature, command: command };
            result.pass = eval( result.command );
            results.push(result);
        }

        function lives_ok( version, feature, command ) {
            var result = { version: version, feature: feature, command: command };

            try {
                eval(command);
                result.pass = true;
            }
            catch (error) {
                result.pass    = false;
                result.message = error;
            }

            results.push(result);
        }

        function is_function( version, feature ) {
            ok( version, feature, 'typeof ' + feature + ' === "function"' );
        }

        function is_object_function( version, parent, feature ) {
            ok(
                version,
                parent + '.' + feature,
                'typeof ' + parent + ' === "object" && typeof ' + parent + '.' + feature + ' === "function"'
            );
        }

        var scalar = 1;
        var list   = new Array( 1, 2, 3 );

        is_function( 'ES5', 'Array.isArray'               );
        is_function( 'ES5', 'Array.prototype.forEach'     );
        is_function( 'ES5', 'Array.prototype.map'         );
        is_function( 'ES5', 'Array.prototype.filter'      );
        is_function( 'ES5', 'Array.prototype.reduce'      );
        is_function( 'ES5', 'Array.prototype.reduceRight' );
        is_function( 'ES5', 'Array.prototype.every'       );
        is_function( 'ES5', 'Array.prototype.some'        );
        is_function( 'ES5', 'Array.prototype.indexOf'     );
        is_function( 'ES5', 'Array.prototype.lastIndexOf' );
        is_function( 'ES5', 'Date.now'                    );
        is_function( 'ES5', 'Date.valueOf'                );
        is_function( 'ES5', 'Object.defineProperty'       );

        is_object_function( 'ES5', 'JSON', 'parse'     );
        is_object_function( 'ES5', 'JSON', 'stringify' );

        is_function( 'ES6', 'Array.prototype.find' );

        lives_ok( 'ES6', 'let',                       'let answer = 42'                           );
        lives_ok( 'ES6', 'const',                     'const thx = 1138'                          );
        lives_ok( 'ES6', 'for...of',                  'for ( var item of list ) {}'               );
        lives_ok( 'ES6', 'default parameters',        'function test( a = 42, t = 1138 ) {}'      );
        lives_ok( 'ES6', 'rest operator',             'function test( a, ...b ) {}'               );
        lives_ok( 'ES6', 'spread operator',           'let test = [...list]'                      );
        lives_ok( 'ES6', 'destructuring',             'let [ x, y ] = list'                       );
        lives_ok( 'ES6', 'template literals/strings', '`Text with a variable: ${scalar}`'         );
        lives_ok( 'ES6', 'arrow functions',           'var val = ( x, y ) => { return x * y }'    );
        lives_ok( 'ES6', 'Promise',                   'new Promise( function () {} )'             );
        lives_ok( 'ES6', 'class',                     'class Demo {}'                             );
        lives_ok( 'ES6', 'Map',                       'new Map()'                                 );
        lives_ok( 'ES6', 'Set',                       'new Set()'                                 );
        lives_ok( 'ES6', 'WeakMap',                   'new WeakMap()'                             );
        lives_ok( 'ES6', 'WeakSet',                   'new WeakSet()'                             );
        lives_ok( 'ES6', 'function generator/yield',  'function * generator() { yield "String" }' );
        lives_ok( 'ES6', 'Symbol',                    'Symbol()'                                  );

        ok( 'ES6', 'Unicode',       '"\x7A" === "z"'                                                 );
        ok( 'ES6', 'export/import', 'document.currentScript && "noModule" in document.currentScript' );

        lives_ok( 'ES6', 'Proxy',   'new Proxy( {}, function () {} )'                                   );
        lives_ok( 'ES6', 'Reflect', 'Reflect.defineProperty( function () {}, "foo", { value: "bar" } )' );

        lives_ok( 'ES7', 'exponential operator', '3 ** 2' );

        is_function( 'ES7', 'Array.prototype.includes' );

        is_function( 'ES8', 'String.prototype.padStart' );
        is_function( 'ES8', 'String.prototype.padEnd'   );

        lives_ok( 'ES8', 'async/await',     'async function testAsyncAwait() { await testAsyncAwait() }' );
        lives_ok( 'ES8', 'trailing commas', 'function testTrailingCommas( a, b, c, ) {}'                 );

        is_function( 'ES8', 'Object.entries'                  );
        is_function( 'ES8', 'Object.values'                   );
        is_function( 'ES8', 'Object.getOwnPropertyDescriptor' );

        lives_ok(
            'ES9', 'asynchronous iteration',
            'async function thing() { for await ( var i of Something ) {} }'
        );

        var regex = true;
        try {
            var reDate = /([0-9]{4})-([0-9]{2})-([0-9]{2})/;
            var match  = reDate.exec('2019-11-30');
            if ( ! (
                match.length == 4 &&
                match[1] == '2019' &&
                match[2] == '11' &&
                match[3] == '30'
            ) ) throw true;
        }
        catch (error) {
            regex = false;
        }
        ok( 'ES9', 'Regular expression improvements', 'regex' );

        var promise_finally = true;
        try {
            if (
                typeof Promise !== 'function' ||
                typeof Promise.prototype !== 'object' ||
                eval('typeof Promise.prototype.finally !== "function"')
            ) throw true;
        }
        catch (error) {
            promise_finally = false;
        }
        ok( 'ES9', 'Promise.prototype.finally', 'promise_finally' );

        ok( 'Extra', 'navigator.onLine',    '"onLine" in navigator'        );
        ok( 'Extra', 'window.fetch',        '"fetch" in window'            );
        ok( 'Extra', 'window.localStorage', '"localStorage" in window'     );
        ok( 'Extra', 'caches',              '"caches" in window'           );
        ok( 'Extra', 'serviceWorker',       '"serviceWorker" in navigator' );

        return results;
    };

    return {
        results : run_tests(),
        test    : function ( version, feature ) {
            var found = this.results.filter(
                function (i) {
                    return i.version == version && i.feature == feature;
                }
            );
            return found[0];
        },
        check : function ( version, feature ) {
            var test = this.test( version, feature );
            return (test) ? test.pass : test;
        }
    };
} )();

/*
=head1 NAME

window.omniframe.browser_test

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/browser_test.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'DOMContentLoaded', () => {

            if ( omniframe.browser_test.check( 'ES6', 'Promise' ) )
                console.log('Promise functionality available');

            console.log( omniframe.browser_test.test( 'ES6', 'Promise' ).pass );

            let results = omniframe.browser_test.results;

            document.writeln('<table>');
            for ( var i = 0; i < results.length; i++ ) {
                var r = results[i];
                document.writeln(
                    '<tr><td>' + r.version + '</td><td>' + r.feature + '</td>' +
                    '<td>' + ( ( r.pass ) ? 'pass' : r.message ) + '</td></tr>'
                );
            }
            document.writeln('</table>');

        } );
    </script>

=head1 DESCRIPTION

Loading this library will run a lengthy set of Javascript functionality tests
and ultimately will cause C<window.omniframe.browser_test> to be filled with an
object. This object contains the results of the tests in the C<results>
attribute.

=head1 ATTRIBUTES

=head2 results

The C<results> attribute is populated on initial run of this library and
contains an array of objects, each object representing the results of a
particular Javascript test.

Each object will have the following attributes:
C<version>, C<feature>, C<command>, C<pass>, and C<message>.
C<version> is the version the Javascript feature became available, like "ES6".
C<feature> is the name of the feature, like "Promise".
C<command> is the command used to test the feature.
C<pass> is a boolean as to whether the test passed.
And C<message> is any error message or response from the test command.

=head1 METHODS

=head2 check

This method expects a version and feature to be provided and will return the
boolean pass value for that test if found, otherwise undefined.

=head2 test

This method expects a version and feature to be provided and will return the
test that matches, otherwise undefined.

=cut
*/
