use ExtUtils::MakeMaker;
WriteMakefile(
    NAME      => 'Redis::Connector',
    VERSION   => '0.02',
    ABSTRACT  => 'Autoreconnect to Redis if connection is lost',
    AUTHOR    => 'Andrey Fedorov <secrethost@gmail.com>',
    PREREQ_PM => {
        'Redis'      => 0,
        'Test::More' => 0,
    },
);
