'use strict';
if ( ! window.omniframe ) window.omniframe = {};
window.omniframe.websocket = ( function () {
    function restarting_websocket(settings) {
        this.settings = settings;
        this.ws       = undefined;
        this.restart  = true;

        let reconnect_attempts = 0;
        this.start = () => {
            this.ws = new WebSocket(
                ( ( window.location.protocol.match('s') ) ? 'wss' : 'ws' ) + '://' +
                    window.location.hostname +
                    ( ( window.location.port ) ? ':' + window.location.port : '' ) +
                    ( ( this.settings.path.indexOf('/') != 0 ) ? window.location.pathname + '/' : '' ) +
                    this.settings.path
            );

            this.ws.onopen = (event) => {
                reconnect_attempts = 0;
                if ( this.settings.onopen ) this.settings.onopen( this, event );
            };

            this.ws.onmessage = (event) => {
                if ( this.settings.onmessage )
                    this.settings.onmessage( JSON.parse( event.data ), this, event );
            };

            this.ws.onerror = (error) => {
                if ( this.settings.onerror ) {
                    this.settings.onerror( this, error );
                }
                else {
                    console.log(error);
                }
            };

            this.ws.onclose = (event) => {
                if ( this.settings.onclose ) this.settings.onclose( this, event );
                if ( this.restart ) {
                    setTimeout(
                        () => {
                            reconnect_attempts++;
                            this.start();
                        },
                        ( reconnect_attempts < 5 ) ? 100 * Math.pow( 2, reconnect_attempts ) : 5000,
                    );
                }
            };
        };

        this.stop = () => {
            this.restart = false;
            if ( this.ws ) this.ws.close();
        };
    }

    return {
        start : settings => {
            let rws = new restarting_websocket(settings);
            rws.start();
            return rws;
        }
    };
} )();

/*
=head1 NAME

window.omniframe.websocket

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/websocket.js" async></script>
    <script type="text/javascript">
        const restarting_websocket = omniframe.websocket.start({
            path      : '/ws',
            onmessage : function ( data, ws ) {
                console.log(data);
                ws.stop();
            }
        });
    </script>

=head1 DESCRIPTION

Loading this library will cause C<window.omniframe.websocket> to be filled with an
object that exposes the a C<start> method for creating and starting websockets
that automatically restart on disconnect.

=head1 ATTRIBUTES

=head2 restart

This attribute is by default true, and if true, the websocket will attempt to
reconnect if it encounters an onclose or onerror event.

=head1 METHODS

=head2 start

This method requires an object be provided that has at minimum the C<path>
attribute defined. The C<path> attribute is a relative or absolute path to a
websocket endpoint. Additionally, you can add callbacks for: onopen, onmessage,
onclose, and onerror.

    const restarting_websocket = omniframe.websocket.start({
        path      : '/ws',
        onmessage : function ( data, restarting_websocket, event ) {
            console.log(data);
        }
    });

For all but onmessage, these will be passed the websocket object and the event
object. For onmessage, it will be passed the data payload object first, then
the websocket and event objects.

On both onclose and onerror events, the websocket will attempt to be
reestablished after 1 second (so long as C<restart> remains true; see above).

=head2 stop

You can call this method on the restarting websocket object, which will cause
the websocket to stop.

=cut
*/
