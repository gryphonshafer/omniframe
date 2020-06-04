'use strict';
if ( ! window.js ) window.js = {};
window.js.websocket = ( function () {
    function restarting_websocket(settings) {
        this.settings = settings;
        this.ws       = undefined;
        this.restart  = true;
        this.start    = function () {
            let that = this;
            that.ws  = new WebSocket(
                ( ( window.location.protocol.match('s') ) ? 'wss' : 'ws' ) + '://' +
                window.location.hostname +
                ( ( window.location.port ) ? ':' + window.location.port : '' ) +
                ( ( that.settings.path.indexOf('/') != 0 ) ? window.location.pathname + '/' : '' ) +
                that.settings.path
            );

            that.ws.onopen = function (e) {
                if ( that.settings.onopen ) that.settings.onopen( that, e );
            };

            that.ws.onmessage = function (e) {
                if ( that.settings.onmessage ) {
                    that.settings.onmessage( JSON.parse( e.data ), that, e );
                }
            };

            that.ws.onclose = function (e) {
                if ( that.settings.onclose ) that.settings.onclose( that, e );
                if ( that.restart ) setTimeout( that.start, 1000 );
            };

            that.ws.onerror = function (error) {
                if ( that.settings.onerror ) {
                    that.settings.onerror( e, that );
                }
                else {
                    console.error(error);
                }

                if ( that.restart ) setTimeout( that.start, 1000 );
            };
        };

        this.stop = function () {
            this.restart = false;
            this.ws.close();
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

window.js.websocket

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/websocket.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'load', () => {
            let restarting_websocket = js.websocket.start({
                path      : '/ws',
                onmessage : function ( data, ws ) {
                    console.log(data);
                    ws.stop();
                }
            });
        } );
    </script>

=head1 DESCRIPTION

Loading this library will cause C<window.js.websocket> to be filled with an
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

    let restarting_websocket = js.websocket.start({
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
