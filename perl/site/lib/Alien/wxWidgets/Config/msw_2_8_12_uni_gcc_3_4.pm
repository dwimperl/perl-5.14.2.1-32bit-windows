package Alien::wxWidgets::Config::msw_2_8_12_uni_gcc_3_4;

use strict;

our %VALUES;

{
    no strict 'vars';
    %VALUES = %{
$VAR1 = {
          'defines' => '-DHAVE_W32API_H -D__WXMSW__ -DNDEBUG -D_UNICODE -DWXUSINGDLL -DNOPCH -DNO_GCC_PRAGMA ',
          'include_path' => '-IC:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4\\lib -IC:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4\\include -IC:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4\\include ',
          'alien_package' => 'Alien::wxWidgets::Config::msw_2_8_12_uni_gcc_3_4',
          'version' => '2.008012',
          'alien_base' => 'msw_2_8_12_uni_gcc_3_4',
          'link_libraries' => '-LC:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4\\lib -lwxmsw28u_core -lwxbase28u ',
          'c_flags' => ' -m32  -O2 -mthreads -m32 -Os ',
          '_libraries' => {
                            'base' => {
                                        'link' => '-lwxbase28u',
                                        'dll' => 'wxbase28u_gcc_custom.dll',
                                        'lib' => 'libwxbase28u.a'
                                      },
                            'core' => {
                                        'link' => '-lwxmsw28u_core',
                                        'dll' => 'wxmsw28u_core_gcc_custom.dll',
                                        'lib' => 'libwxmsw28u_core.a'
                                      },
                            'richtext' => {
                                            'link' => '-lwxmsw28u_richtext',
                                            'dll' => 'wxmsw28u_richtext_gcc_custom.dll',
                                            'lib' => 'libwxmsw28u_richtext.a'
                                          },
                            'aui' => {
                                       'link' => '-lwxmsw28u_aui',
                                       'dll' => 'wxmsw28u_aui_gcc_custom.dll',
                                       'lib' => 'libwxmsw28u_aui.a'
                                     },
                            'stc' => {
                                       'link' => '-lwxmsw28u_stc',
                                       'dll' => 'wxmsw28u_stc_gcc_custom.dll',
                                       'lib' => 'libwxmsw28u_stc.a'
                                     },
                            'gl' => {
                                      'link' => '-lwxmsw28u_gl',
                                      'dll' => 'wxmsw28u_gl_gcc_custom.dll',
                                      'lib' => 'libwxmsw28u_gl.a'
                                    },
                            'net' => {
                                       'link' => '-lwxbase28u_net',
                                       'dll' => 'wxbase28u_net_gcc_custom.dll',
                                       'lib' => 'libwxbase28u_net.a'
                                     },
                            'html' => {
                                        'link' => '-lwxmsw28u_html',
                                        'dll' => 'wxmsw28u_html_gcc_custom.dll',
                                        'lib' => 'libwxmsw28u_html.a'
                                      },
                            'xml' => {
                                       'link' => '-lwxbase28u_xml',
                                       'dll' => 'wxbase28u_xml_gcc_custom.dll',
                                       'lib' => 'libwxbase28u_xml.a'
                                     },
                            'media' => {
                                         'link' => '-lwxmsw28u_media',
                                         'dll' => 'wxmsw28u_media_gcc_custom.dll',
                                         'lib' => 'libwxmsw28u_media.a'
                                       },
                            'xrc' => {
                                       'link' => '-lwxmsw28u_xrc',
                                       'dll' => 'wxmsw28u_xrc_gcc_custom.dll',
                                       'lib' => 'libwxmsw28u_xrc.a'
                                     },
                            'adv' => {
                                       'link' => '-lwxmsw28u_adv',
                                       'dll' => 'wxmsw28u_adv_gcc_custom.dll',
                                       'lib' => 'libwxmsw28u_adv.a'
                                     }
                          },
          'link_flags' => ' -s -m32 ',
          'shared_library_path' => 'C:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4\\lib',
          'compiler' => 'g++',
          'linker' => 'g++',
          'config' => {
                        'compiler_version' => '3.4',
                        'compiler_kind' => 'gcc',
                        'mslu' => undef,
                        'toolkit' => 'msw',
                        'unicode' => 1,
                        'debug' => 0,
                        'build' => 'multi'
                      },
          'wx_base_directory' => 'C:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4',
          'prefix' => 'C:\\strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_2_8_12_uni_gcc_3_4'
        };
    };
}

my $key = substr __PACKAGE__, 1 + rindex __PACKAGE__, ':';

my ($portablebase);
my $wxwidgetspath = __PACKAGE__ . '.pm';
$wxwidgetspath =~ s/::/\//g;

for (@INC) {
    if( -f qq($_/$wxwidgetspath ) ) {
        $portablebase = qq($_/Alien/wxWidgets/$key);
        last;
    }
}

if( $portablebase ) {
    $portablebase =~ s{/}{\\}g;
    my $portablelibpath = qq($portablebase\\lib);
    my $portableincpath = qq($portablebase\\include);

    $VALUES{include_path} = qq{-I$portablelibpath -I$portableincpath};
    $VALUES{link_libraries} =~ s{-L\S+\s}{-L$portablelibpath };
    $VALUES{shared_library_path} = $portablelibpath;
    $VALUES{wx_base_directory} = $portablebase;
    $VALUES{prefix} = $portablebase;
}

sub values { %VALUES, key => $key }

sub config {
   +{ %{$VALUES{config}},
      package       => __PACKAGE__,
      key           => $key,
      version       => $VALUES{version},
      }
}

1;
