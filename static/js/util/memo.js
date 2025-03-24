'use strict';
if ( ! window.omniframe ) window.omniframe = {};
( () => {
    function args_to_inputs(...args) {
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

        return inputs;
    }

    function build_dialog(inputs) {
        const dialog = window.document.createElement('dialog');
        const div    = window.document.createElement('div');
        const form   = window.document.createElement('form');

        [ 'memo', ...inputs.classes ].filter( name => name ).forEach( name => dialog.classList.add(name) );
        form.setAttribute( 'method', 'dialog' );
        [ div, form ].forEach( element => dialog.appendChild(element) );

        inputs.messages.forEach( message => {
            if ( typeof message == 'string' ) {
                const p = window.document.createElement('p');
                if ( ! message.match('[.,?:;!>]$') ) message += '.';
                p.innerHTML = message;
                div.appendChild(p);
            }
            else if ( Array.isArray(message) ) {
                const ul = window.document.createElement('ul');
                message.forEach( item => {
                    const li = window.document.createElement('li');
                    li.innerHTML = item;
                    ul.appendChild(li);
                } );
                div.appendChild(ul);
            }
        } );

        inputs.options.forEach( option => {
            const button = window.document.createElement('button');
            button.innerHTML = option;
            button.onclick   = event => {
                if ( inputs.callbacks && inputs.callbacks.length ) {
                    const callback = inputs.callbacks.shift();
                    if (callback) callback(event);
                }
                window.document.body.removeChild(dialog);
            };
            form.appendChild(button);
        } );

        window.document.body.appendChild(dialog);
        dialog.autofocus = true;
        dialog.showModal();
    }

    window.omniframe.memo = (...args) => {
        if ( window.document.readyState !== 'complete' ) {
            window.addEventListener( 'DOMContentLoaded', () => {
                build_dialog( args_to_inputs(...args) );
            } );
        }
        else {
            build_dialog( args_to_inputs(...args) );
        }
    };
} )();

/*
=head1 NAME

window.omniframe.memo

=head1 SYNOPSIS

    <script type="text/javascript" src="/js/util/memo.js" async></script>
    <script type="text/javascript">
        window.addEventListener( 'DOMContentLoaded', () => {
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
