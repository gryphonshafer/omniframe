'use strict';
if ( ! window.omniframe ) window.omniframe = {};
window.omniframe.cookies = ( () => {
    let suffix = '; path=/; SameSite=Strict';

    return {
        set : ( name, value, days ) => {
            var expires = '';
            if ( typeof days !== 'undefined' ) {
                if ( parseInt(days) == days ) {
                    var date = new Date();
                    date.setTime( date.getTime() + ( days * 24 * 60 * 60 * 1000 ) );
                    expires = '; expires=' + date.toUTCString();
                }
                else {
                    expires = '; expires=' + days
                }
            }

            document.cookie =
                name + '=' + btoa( JSON.stringify(value) ) +
                expires + suffix;
            return value;
        },

        get : name => {
            var name_eq = name + '=';
            var cookies = document.cookie.split(';');
            for ( var i = 0; i < cookies.length; i++ ) {
                var cookie = cookies[i];
                while ( cookie.charAt(0) == ' ' ) cookie = cookie.substring( 1, cookie.length );
                if ( cookie.indexOf(name_eq) == 0 )
                    return JSON.parse( atob( cookie.substring( name_eq.length, cookie.length ) ) );
            }
            return null;
        },

        all : () => {
            return document.cookie.split(';').reduce( ( cookies, cookie ) => {
                let [ name, value ] = cookie.split('=').map( c => c.trim() );
                return {
                    ...cookies,
                    [name]: ( typeof value !== 'undefined' ) ? JSON.parse( atob(value) ) : value
                };
            }, {} );
        },

        delete : name => {
            this.set( name, undefined, new Date().toUTCString() );
        },

        delete_all : () => {
            document.cookie.split(';').forEach( (c) => {
                document.cookie = c
                    .replace( /^ +/, '' )
                    .replace( /=.*/, '=; expires=' + new Date().toUTCString() + suffix );
            } );
        }
    };
} )();

/*
=head1 NAME

window.omniframe.cookies

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/cookies.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'load', () => {
            js.cookies.set( 'cookie_name', { answer: 42 }, 365 );
            console.log( js.cookies.get('cookie_name').answer );
            console.log( js.cookies.all() );
            js.cookies.delete('cookie_name');
            js.cookies.delete_all();
        } );
    </script>

=head1 DESCRIPTION

Loading this library will cause C<window.omniframe.cookies> to be filled with an
object useful for handling cookie data.

=head1 METHODS

=head2 set

This method requires a name and value, which will be stored as a cookie.

The value can be a simple string or number, but it can also be a complex data
type. Values are converted to JSON and base-64 encoded before storage.

The method can optionally also accept a third time input. If an integer, this
time will be considered the number of days until expiration of the cookie. If
not an integer, the time input will be used as is for the cookie expiration
value. Any cookie without an expiration value will be a session cookie.

=head2 get

This method requires a name and returns the base-64 decoded, JSON parsed data
stored in the cookie with the same name.

=head2 all

Returns an object of key-value pairs representing cookie data.

=head2 delete

This method requires a name and will when called delete the cookie associated
with the name.

=head2 delete_all

This method deletes all cookies.

=cut
*/
