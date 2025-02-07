'use strict';
if ( ! window.omniframe ) window.omniframe = {};
( () => {
    const dialog = window.document.createElement('dialog');
    dialog.id = 'omniframe_memo';

    const div = document.createElement('div');
    dialog.appendChild(div);

    const form = document.createElement('form');
    form.setAttribute( 'method', 'dialog' );
    dialog.appendChild(form);

    window.addEventListener( 'load', () => window.document.body.appendChild(dialog) );

    window.omniframe.memo = (...args) => {
        if ( document.readyState === 'complete' ) {
            if ( ! window.document.querySelector('dialog#omniframe_memo') )
                window.document.body.appendChild(dialog);

            if ( args.length == 0 ) return;

            const inputs = {};
            if ( args.length == 1 && typeof args[0] == 'object' && ! Array.isArray( args[0] ) ) {
                Object.assign( inputs, args[0] );
                [ 'message', 'class', 'option', 'callback' ].forEach( singular => {
                    const plural = singular + ( ( singular[ singular.length - 1 ] == 's') ? 'es' : 's' );
                    if ( inputs.hasOwnProperty(singular) ) {
                        inputs[plural] = inputs[singular];
                        delete inputs[singular];
                    }
                } );
            }
            else {
                const keys = [ 'messages', 'classes', 'options', 'callbacks' ];
                while ( args.length > 0 ) inputs[ keys.shift() ] = args.shift();
            }

            inputs.options ||= 'OK';
            [ 'messages', 'classes', 'options', 'callbacks' ].forEach( key => {
                if ( ! Array.isArray( inputs[key] ) ) inputs[key] = [ inputs[key] ];
            } );

            [ div, form ].forEach( element => {
                while ( element.firstChild ) element.removeChild( element.firstChild );
            } );

            inputs.messages.forEach( message => {
                if ( typeof message == 'string' ) {
                    const p = document.createElement('p');
                    if ( ! message.match('[.,?:;!]$') ) message += '.';
                    p.innerHTML = message;
                    div.appendChild(p);
                }
                else if ( Array.isArray(message) ) {
                    const ul = document.createElement('ul');
                    message.forEach( item => {
                        const li = document.createElement('li');
                        li.innerHTML = item;
                        ul.appendChild(li);
                    } );
                    div.appendChild(ul);
                }
            } );

            inputs.options.forEach( option => {
                const button = document.createElement('button');
                button.innerHTML = option;
                if ( inputs.callbacks && inputs.callbacks.length ) button.onclick = inputs.callbacks.shift();
                form.appendChild(button);
            } );

            dialog.className = '';
            dialog.classList.add( ...inputs.classes );

            dialog.autofocus = true;
            dialog.show();
        }
        else {
            window.addEventListener( 'load', () => {
                window.omniframe.memo(...args);
            } );
        }
    };
} )();

/*
=head1 NAME

window.omniframe.memo

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/memo.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'load', () => {
            omniframe.memo('Message');

            omniframe.memo({
                message: 'Message',
                option : 'OK',
                class  : 'notice',
            });

            omniframe.memo({
                messages: [ 'Message', [ 'Item 1', 'Item 2' ] ],
                options : [ 'OK', 'Cancel' ],
                classes : [ 'notice', 'confirm' ],
                callback: () => { console.log('Hello world.') },
            });
        } );
    </script>

=head1 DESCRIPTION

Loading this library will cause C<window.omniframe.memo> to be a function that
can be called to populate HTML C<dialog> instances.

=cut
*/
