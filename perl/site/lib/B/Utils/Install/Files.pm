package B::Utils::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [
                          'typemap'
                        ],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/B/Utils/Install/Files.pm") {
			$CORE = $_ . "/B/Utils/Install/";
			last;
		}
	}

1;
