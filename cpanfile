requires 'exact', '1.13';
requires 'exact::class', '1.08';
requires 'exact::cli', '1.03';
requires 'exact::conf', '1.03';

requires 'Mojolicious', '8.39';
requires 'MojoX::ConfigAppStart', '1.01';
requires 'MojoX::Log::Dispatch::Simple', '1.07';
requires 'Mojolicious::Plugin::AccessLog', '>= 0.010';
requires 'Mojolicious::Plugin::RequestBase', '>= 0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '>= 1.09';

requires 'DBIx::Query', '1.10';
requires 'App::Dest', '1.27';

requires 'CSS::Sass', '3.6.0';
requires 'Data::Printer', '0.40';
requires 'DateTime', '1.52';
requires 'DateTime::TimeZone', '2.39';
requires 'Email::Mailer', '1.09';
requires 'Encode', '3.06';
requires 'File::Basename', '2.85';
requires 'File::Copy', '2.34';
requires 'File::Find', '1.36';
requires 'File::Path', '2.16';
requires 'File::Spec', '3.75';
requires 'Linux::Inotify2', '2.2';
requires 'Log::Dispatch', '2.69';
requires 'Log::Dispatch::Email::Mailer', '1.05';
requires 'Term::ANSIColor', '5.01';
requires 'Text::CSV_XS', '1.43';
requires 'Text::MultiMarkdown', '1.000035';
requires 'YAML::XS', '0.81';

on 'test' => sub {
    requires 'Cwd', '3.75';
    requires 'ExtUtils::Manifest', '1.72';
    requires 'Pod::Coverage::TrustPod', '0.100005';
    requires 'Test::EOL', '2.00';
    requires 'Test::MockModule', '0.172.0';
    requires 'Test::Most', '0.37';
    requires 'Test::NoTabs', '2.02';
    requires 'Test::Output', '1.031';
    requires 'Test::Pod', '1.52';
    requires 'Test::Pod::Coverage', '1.10';
    requires 'Test::Portability::Files', '0.10';
    requires 'Test::Synopsis', '0.16';
    requires 'Text::Gitignore', '0.04';
};
