'use strict';
if ( ! window.js ) window.js = {};
window.js.net_buffer = ( function () {
    let queue_name      = 'net_buffer_queue';
    let queue_callbacks = {};

    function queue_push ( url, payload, callback ) {
        let queue = JSON.parse( localStorage.getItem(queue_name) || '[]' );
        let id    = Date.now() + Math.random();

        queue_callbacks[id] = callback;

        queue.push({
            id      : id,
            url     : url,
            payload : payload
        });

        localStorage.setItem( queue_name, JSON.stringify(queue) );
        return;
    }

    function queue_get () {
        return JSON.parse( localStorage.getItem(queue_name) || '[]' );
    }

    function queue_shift () {
        let queue = queue_get();
        queue.shift();
        localStorage.setItem( queue_name, JSON.stringify(queue) );
        if ( queue.length == 0 ) localStorage.removeItem('queue_name');
        return queue.length;
    }

    let queue_process_active = false;

    function queue_process () {
        if (queue_process_active) return;
        queue_process_active = true;

        let [item] = queue_get();

        if ( ! item ) {
            queue_process_active = false;
            return;
        }

        fetch(
            item.url,
            {
                method      : 'POST',
                body        : JSON.stringify( item.payload ),
                credentials : 'include',
            }
        )
            .then( response => response.json() )
            .then( data => {
                if ( typeof queue_callbacks[ item.id ] === 'function' ) {
                    queue_callbacks[ item.id ](data);
                    delete queue_callbacks[ item.id ];
                }
                queue_process_active = false;
                if ( queue_shift() > 0 ) queue_process();
            } )
            .catch( error => {
                queue_process_active = false;
            } );

        return;
    }

    window.addEventListener( 'online', () => queue_process() );
    window.addEventListener( 'load',   () => queue_process() );

    return {
        send : ( url, payload, callback ) => {
            return new Promise( () => {
                queue_push( url, payload, callback );
                queue_process();
            } );
        },
        usage : () => {
            let serial = '';
            for ( let key in localStorage ) {
                serial += key;
                if ( localStorage.hasOwnProperty(key) ) {
                    serial += localStorage[key];
                }
            }

            return ( serial.length ) ? serial.length / ( 1 * 1024 * 1024 ) * 100 : 0;
        }
    };
} )();

/*
=head1 NAME

window.js.net_buffer

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/net_buffer.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'load', () => {
            js.net_buffer.send( '/api', { answer: 1138 }, (data) => console.log(data) );
            console.log( js.net_buffer.usage() );
        } );
    </script>

=head1 DESCRIPTION

Loading this library will cause C<window.js.net_buffer> to be filled with an
object. This object manages a send buffer. When offline or over a slow network,
you can send messages via this object, which will be placed in a buffer, and
then each message will be sent until all are handled.

In theory, this is resilient to system, network, and browser crashes, more or
less.

=head1 METHODS

=head2 send

This method expects a URL, Javascript data payload, and an optional callback.
It will append the call to the call buffer and attempt to send it when able.

Upon completion of the send, the callback will be called. The callback is not
necessarily guaranteed to run, specifically in the case where the browser is
closed prior to completion of sending from the buffer. In that case, the buffer
will remain (via C<localStorage>), but the callback will be lost.

=head2 usage

This method will return a float (ideally between 0 and 100 ) representing the
percentage usage of C<localStorage>. The usage calculation is based on a
1 mega-character total space limit (1 * 1024 * 1024), which is the assumed
minimum maximum size cross-browser.

=cut
*/
