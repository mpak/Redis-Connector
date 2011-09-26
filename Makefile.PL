use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Redis::Connector',
    VERSION_FROM   => 'lib/Redis/Connector.pm',
    ABSTRACT_FROM  => 'lib/Redis/Connector.pm',
    AUTHOR         => 'Andrey Fedorov <secrethost@gmail.com>',
    PREREQ_PM      => {
        'Redis'      => 0,
        'Test::More' => 0,
    },
);
