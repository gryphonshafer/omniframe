requires 'App::Dest', '1.34';
requires 'Auth::GoogleAuth', '1.07';
requires 'Crypt::CBC', '3.04';
requires 'Cwd', '3.75';
requires 'DBD::SQLite', '1.76';
requires 'DBIx::Query', '1.16';
requires 'Data::Printer', '1.002001';
requires 'Date::Format', '2.24';
requires 'Date::Parse', '2.33';
requires 'DateTime', '1.66';
requires 'DateTime::TimeZone', '2.65';
requires 'DateTime::TimeZone::Olson', '0.007';
requires 'Digest::Bcrypt', '1.212';
requires 'Email::Mailer', '1.21';
requires 'File::Copy';
requires 'File::Copy::Recursive', '0.45';
requires 'File::Glob';
requires 'FindBin', '1.54';
requires 'HTML::Packer', '2.11';
requires 'IPC::Run3', '0.049';
requires 'Imager::QRCode', '0.035';
requires 'JavaScript::QuickJS', '0.21';
requires 'Linux::Inotify2', '2.3';
requires 'Log::Dispatch', '2.71';
requires 'Log::Dispatch::Email::Mailer', '1.13';
requires 'MIME::Base64', '3.16';
requires 'MojoX::ConfigAppStart', '1.04';
requires 'MojoX::Log::Dispatch::Simple', '1.14';
requires 'Mojolicious', '9.40';
requires 'Mojolicious::Plugin::AccessLog', '0.010001';
requires 'Mojolicious::Plugin::CSRF', '1.02';
requires 'Mojolicious::Plugin::RequestBase', '0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '1.13';
requires 'POSIX';
requires 'Pod::Simple::HTML', '3.47';
requires 'Proc::ProcessTable', '0.636';
requires 'SQL::Abstract::Complete', '1.10';
requires 'Template', '3.102';
requires 'Term::ANSIColor', '5.01';
requires 'Text::CSV_XS', '1.60';
requires 'Text::MultiMarkdown', '1.005';
requires 'Text::Table::Tiny', '1.03';
requires 'Time::HiRes', '1.9764';
requires 'YAML::XS', '0.89';
requires 'exact', '1.28';
requires 'exact::class', '1.19';
requires 'exact::cli', '1.07';
requires 'exact::conf', '1.08';
requires 'exact::lib', '1.04';
recommends 'IO::Socket::SSL', '2.089';
recommends 'IO::Socket::Socks', '0.74';
recommends 'MojoX::Linda', '1.03';
recommends 'Net::DNS::Native', '0.22';

on test => sub {
    requires 'ExtUtils::Manifest', '1.75';
    requires 'Pod::Coverage::TrustPod', '0.100006';
    requires 'Test2::MojoX', '0.07';
    requires 'Test2::V0', '1.302213';
    requires 'Test::EOL', '2.02';
    requires 'Test::Mojibake', '1.3';
    requires 'Test::NoTabs', '2.02';
    requires 'Test::Output', '1.036';
    requires 'Test::Pod', '1.52';
    requires 'Test::Pod::Coverage', '1.10';
    requires 'Test::Portability::Files', '0.10';
    requires 'Test::Synopsis', '0.17';
    requires 'Text::Gitignore', '0.04';
};
