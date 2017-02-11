use v6;
#`(
Copyright ©  

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

)

use nqp;
use QAST:from<NQP>;

my %matcher = 一 => 1,
              二 => 2,
              三 => 3,
              四 => 4,
              五 => 5,
              六 => 6,
              七 => 7,
              八 => 8,
              九 => 9,
              十 => 10;

grammar Kazu {
    token TOP     { <single> | <ten> | <hundred> | <thousnd> | <tenthou> }
    token single  { <[一二三四五六七八九]> }
    token ten     { (<single>)? '十' (<single>)? }
    token hundred { (<single>)? '百' (<single> | <ten>)? }
    token thousnd { (<single>)? '千' (<hundred> | <ten> | <single>)? }
    token tenthou { (<single>)? '万' (<thousnd> | <hundred> | <ten> | <single>)? }
    # TODO
    # token counter { <[本枚個杯冊台階件足通分秒匹頭羽回度番等人名歳才年]> }
}

class Translator {
    method TOP ($/)     { make (given ($/) {
                                when $<single>  { $<single>.made }
                                when $<ten>     { $<ten>.made }
                                when $<hundred> { $<hundred>.made }
                                when $<thousnd> { $<thousnd>.made }
                                when $<tenthou> { $<tenthou>.made }
                            })
                        }
    method single ($/)  { make %matcher{$/}; }
    method ten ($/)     { make ($0 ?? $0<single>.made * 10 !! 10) +
                               ($1 ?? $1<single>.made      !! 0); }
    method hundred ($/) { my $res = ($0 ?? $0<single>.made * 100 !! 100);
                          ($res += (given $1 {
                                  when $1<single> { $1<single>.made };
                                  when $1<ten>    { $1<ten>.made };
                                  default         { 0 }
                                       })) if $1;
                          make $res;
                        }
    method thousnd ($/) { my $res = ($0 ?? $0<single>.made * 1000 !! 1000);
                          ($res += (given $1 {
                                  when $1<hundred> { $1<hundred>.made };
                                  when $1<single>  { $1<single>.made };
                                  when $1<ten>     { $1<ten>.made };
                                  default          { 0 }
                              })) if $1;
                          make $res;
                        }
    method tenthou ($/) { my $res = ($0 ?? $0<single>.made * 10000 !! 10000);
                          ($res += (given $1 {
                                           when $1<thousnd> { $1<thousnd>.made };
                                           when $1<hundred> { $1<hundred>.made };
                                           when $1<single>  { $1<single>.made };
                                           when $1<ten>     { $1<ten>.made };
                                           default          { 0 }
                              })) if $1;
                          make $res;
                        }
    # The code looks uglier with every level of depth here.
}

sub Slang::Kazu::to-number(Str $value --> Int) is export {
    Kazu.parse($value, actions => Translator).made;
};

sub EXPORT(|) {
    role Kazu::Grammar {
        rule number:sym<kazu> { <japint> }
        token japint { <[一二三四五六七八九十百千万]>+ }
    }

    role Kazu::Actions {
        sub lk(Mu \h, \k) {
            nqp::atkey(nqp::findmethod(h, 'hash')(h), k)
        }
    
        method number:sym<kazu>(Mu $/) {
            my $number   := lk($/, 'japint');
            my $block := QAST::Op.new(:op<call>,
                                      :name<&Slang::Kazu::to-number>,
                                      QAST::SVal.new(:value($number.Str))
                                     );
            $/.'!make'($block);
        }
    }

    nqp::bindkey(%*LANG,
                 'MAIN',
                 %*LANG<MAIN>.HOW.mixin(%*LANG<MAIN>,
                 Kazu::Grammar));
    nqp::bindkey(%*LANG,
                 'MAIN-actions',
                 %*LANG<MAIN-actions>.HOW.mixin(%*LANG<MAIN-actions>,
                 Kazu::Actions));
    {}
}

=begin pod

=head1 NAME

Slang::Kazu - Japanese numerals in your Perl 6

=head1 SYNOPSIS

  use Slang::Kazu;
  say "3542" ~~ 三千五百四十二; # True

=head1 DESCRIPTION

Slang::Kazu is a Perl 6 slang that allows you to use a subset of native Japanese numerals in your Perl 6 code because you can.

You can use numbers from 1 to 99999. Counters are yet to be implemented. Mostly this is a clone of [drforr's](http://github.com/drforr) `Slang::Roman`, but for Japanese numerals - all thanks to him for the idea and the implementation.

Currently, incorrect numbers like `二二` are evaluated to `Nil` and you will see some scary errors because of that, so don't lose your kanji!

This project is just a joke and doesn't intented to be used in any serious codebases! You are warned.

=head1 AUTHOR

Altai-man on Github, you can cast sena_kun on freenode too.

=head1 COPYRIGHT AND LICENSE

Copyright ©  

License GPLv3: The GNU General Public License, Version 3, 29 June 2007
<https://www.gnu.org/licenses/gpl-3.0.txt>

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


=end pod
