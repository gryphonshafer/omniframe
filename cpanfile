requires 'App::Dest', '1.30';
requires 'DBD::SQLite', '1.70';
requires 'DBIx::Query', '1.13';
requires 'Data::Printer', '1.000004';
requires 'Date::Format', '2.24';
requires 'Date::Parse', '2.33';
requires 'DateTime', '1.55';
requires 'DateTime::TimeZone', '2.51';
requires 'DateTime::TimeZone::Olson', '0.007';
requires 'Digest::Bcrypt', '1.212';
requires 'Email::Mailer', '1.18';
requires 'File::Copy';
requires 'File::Copy::Recursive', '0.45';
requires 'FindBin', '1.52';
requires 'HTML::Packer', '2.10';
requires 'IPC::Run3', '0.048';
requires 'JavaScript::Packer', '2.08';
requires 'Linux::Inotify2', '2.3';
requires 'Log::Dispatch', '2.70';
requires 'Log::Dispatch::Email::Mailer', '1.11';
requires 'MojoX::ConfigAppStart', '1.02';
requires 'MojoX::Log::Dispatch::Simple', '1.11';
requires 'Mojolicious', '9.22';
requires 'Mojolicious::Plugin::AccessLog', '0.010001';
requires 'Mojolicious::Plugin::RequestBase', '0.3';
requires 'Mojolicious::Plugin::ToolkitRenderer', '1.11';
requires 'Pod::Simple::HTML', '3.43';
requires 'Template', '3.010';
requires 'Term::ANSIColor', '5.01';
requires 'Text::CSV_XS', '1.47';
requires 'Text::MultiMarkdown', '1.000035';
requires 'Time::HiRes', '1.9764';
requires 'YAML::XS', '0.83';
requires 'exact', '1.17';
requires 'exact::class', '1.15';
requires 'exact::cli', '1.05';
requires 'exact::conf', '1.06';
requires 'exact::lib', '1.02';

on test => sub {
    requires 'Cwd', '3.75';
    requires 'ExtUtils::Manifest', '1.73';
    requires 'Pod::Coverage::TrustPod', '0.100005';
    requires 'Test2::MojoX', '0.07';
    requires 'Test2::V0', '0.000144';
    requires 'Test::EOL', '2.02';
    requires 'Test::Mojibake', '1.3';
    requires 'Test::NoTabs', '2.02';
    requires 'Test::Output', '1.033';
    requires 'Test::Pod', '1.52';
    requires 'Test::Pod::Coverage', '1.10';
    requires 'Test::Portability::Files', '0.10';
    requires 'Test::Synopsis', '0.17';
    requires 'Text::Gitignore', '0.04';
};
