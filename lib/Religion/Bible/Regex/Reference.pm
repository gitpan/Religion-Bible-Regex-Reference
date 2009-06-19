package Religion::Bible::Regex::Reference;

use strict;
use warnings;

# Input files are assumed to be in the UTF-8 strict character encoding.
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use Carp;
use Storable qw(store retrieve freeze thaw dclone);
use Data::Dumper;

use Religion::Bible::Regex::Config;
use version; our $VERSION = qv('0.9');

##################################################################################
# Configuration options:
# reference.full_book_name: true/false
# reference.abbreviation.map: true/false
# reference.cvs: Chapitre/Verset Separateur
##################################################################################
# Glossaire des abréviations
# $s  = header space
# $a   = l'espace entre le livre et le chapitre - $d
# $l   = le nom du livre ou abréviation
# $c   = chapitre
# $b   = l'espace entre le chapitre et le chapitre-verset separateur
# $cvs = chapitre ou verset separateur
# $d   = l'espace entre le chapitre-verset separateur et le verset
# $v, $vl_cl_sep
# $ts  = l'espace vers le tail (queue)
# $type = LCV, LCCV, LCVV
##################################################################################

# Defaults and Constants
# our %configuration_defaults = (
#     verse_list_separateur => ', ',
#     chapter_list_separateur => '; ',
#     book_list_separateur => '; ',
# );

# These constants are defined in several places and probably should be moved to a common file
# Move these to Constants.pm
use constant BOOK    => 'BOOK';
use constant CHAPTER => 'CHAPTER';
use constant VERSE   => 'VERSE'; 
use constant UNKNOWN => 'UNKNOWN';
use constant TRUE => 1;
use constant FALSE => 0;

sub new {
    my ($class, $config, $regex) = @_;
    my ($self) = {};
    bless $self, $class;
    $self->{'regex'} = $regex;
    $self->{'config'} = $config;
#    $self->{'reference_config'} = new Religion::Bible::Regex::Config($config->get_formatting_configurations, \%configuration_defaults);
    return $self;
}
# sub _initialize_default_configuration {
#     my $self = shift; 
#     my $defaults = shift; 

#     while ( my ($key, $value) = each(%{$defaults}) ) {    
#        $self->set($key, $value) unless defined($self->{mainconfig}{$key});  
#     }
# }

# Returns a reference to a Religion::Bible::Regex::Builder object.

# Subroutines related to getting information
sub get_regexes {
  my $self = shift;
  confess "regex is not defined\n" unless defined($self->{regex});
  return $self->{regex};
}

# Returns a reference to a Religion::Bible::Regex::Config object.
sub get_configuration {
  my $self = shift;
  confess "config is not defined\n" unless defined($self->{config});
  return $self->{config};
}

sub get_reference_hash { return shift->{'reference'}; }
sub reference { get_reference_hash(@_); }

# sub get_formatting_configuration_hash {
#   my $self = shift;
#   confess "reference is not defined in ReferenceBiblique::Versification\n" unless defined($self->{config}->get_formatting_configurations);
#   return $self->{config}->get_formatting_configurations;
# }

# sub get_versification_configuration_hash {
#   my $self = shift;
#   confess "reference_config is not defined in ReferenceBiblique::Versification\n" unless defined($self->{config}->get_versification_configurations);
#   return $self->{config}->get_versification_configurations;
# }

# Unique key representing the book this reference is from
sub key  { shift->{'reference'}{'data'}{'key'}; }
sub c    { shift->{'reference'}{'data'}{'c'};   }
sub v    { shift->{'reference'}{'data'}{'v'};   }

sub key2 { shift->{'reference'}{'data'}{'key2'}; }
sub c2   { shift->{'reference'}{'data'}{'c2'};   }
sub v2   { shift->{'reference'}{'data'}{'v2'};   }

sub ob   { shift->{'reference'}{'original'}{'b'};  }
sub ob2  { shift->{'reference'}{'original'}{'b2'}; }
sub oc   { shift->{'reference'}{'original'}{'c'};  }
sub oc2  { shift->{'reference'}{'original'}{'c2'}; }
sub ov   { shift->{'reference'}{'original'}{'v'};  }
sub ov2  { shift->{'reference'}{'original'}{'v2'}; }

sub s2   { shift->{'reference'}{'spaces'}{'s2'}; }
sub s3   { shift->{'reference'}{'spaces'}{'s3'}; }
sub s4   { shift->{'reference'}{'spaces'}{'s4'}; }
sub s5   { shift->{'reference'}{'spaces'}{'s5'}; }
sub s6   { shift->{'reference'}{'spaces'}{'s6'}; }
sub s7   { shift->{'reference'}{'spaces'}{'s7'}; }
sub s8   { shift->{'reference'}{'spaces'}{'s8'}; }
sub s9   { shift->{'reference'}{'spaces'}{'s9'}; }
sub book { 
    my $self = shift;
    return $self->get_regexes->book($self->key);
}
sub book2 { 
    my $self = shift;
    return $self->get_regexes->book($self->key2);
}
sub abbreviation  {
    my $self = shift;
    return $self->get_regexes->abbreviation($self->key);
}
sub abbreviation2  {
    my $self = shift;
    return $self->get_regexes->abbreviation($self->key2);
}
sub context_words  { shift->{'reference'}{'data'}{'context_words'}; }
sub cvs            { shift->{'reference'}{'info'}{'cvs'}; }
sub dash           { shift->{'reference'}{'info'}{'dash'}; }

# Subroutines for book, abbreviation and key conversions
sub abbreviation2book {}
sub book2abbreviation {}
sub key2book {}
sub key2abbreviation {}
sub book2key {}
sub abbreviation2key {}

# Subroutines for setting
sub set_key   {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'key'} = $e; 
}
sub set_c     {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'c'}   = $e; 
    $self->{'reference'}{'original'}{'c'}   = $e; 
}
sub set_v     {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    if ($e =~ m/(@{[$self->get_regexes->{'verse_number'}]})(@{[$self->get_regexes->{'verse_letter'}]})/) {
	$self->{'reference'}{'data'}{'v'}   = $1 if defined($1);
	$self->{'reference'}{'data'}{'vletter'} = $2 if defined($2);
    } else {
	$self->{'reference'}{'data'}{'v'}   = $e;
    }
    $self->{'reference'}{'original'}{'v'}   = $e; 
}

sub set_key2  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'key2'} = $e; 
}
sub set_c2    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'c2'}   = $e; 
    $self->{'reference'}{'original'}{'c2'}   = $e; 
}
sub set_v2    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    if ($e =~ m/(@{[$self->get_regexes->{'verse_number'}]})(@{[$self->get_regexes->{'verse_letter'}]})/) {
	$self->{'reference'}{'data'}{'v2'}   = $1 if (defined($1));
	$self->{'reference'}{'data'}{'v2letter'} = $2 if (defined($1));
    } else {
	$self->{'reference'}{'data'}{'v2'}   = $e;
    }
    $self->{'reference'}{'original'}{'v2'}   = $e;  
}

sub set_b     {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'original'}{'b'}  = $e; 

    # If there is a key then create the book2key and abbreviation2key associations
    my $key = $self->get_regexes->key($e);
    unless (defined($key)) {
	print Dumper $self->{'regex'}{'book2key'};
	print Dumper $self->{'regex'}{'abbreviation2key'};
	croak "Key must be defined: $e\n";
    }
    $self->{'reference'}{'data'}{'key'} = $self->get_regexes->key($e);
#    }
}
sub set_b2    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));

    $self->{'reference'}{'original'}{'b2'}  = $e; 
    $self->{'reference'}{'data'}{'key2'} = $self->get_regexes->key($e);
}

sub set_context_words  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'data'}{'context_words'} = $e; 
}

# Setors for spaces
# Ge 1:1-Ap 21:22
# This shows how each of the areas that have the potential
# for a space are defined.
# Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
sub set_s2    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s2'} = $e; 
}
sub set_s3    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s3'} = $e; 
}
sub set_s4    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s4'} = $e; 
}
sub set_s5    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s5'} = $e; 
}
sub set_s6    {
    my $self = shift; 
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s6'} = $e; 
}
sub set_s7    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s7'} = $e; 
}
sub set_s8    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s8'} = $e; 
}
sub set_s9    {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'spaces'}{'s9'} = $e; 
}


sub set_cvs   {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'info'}{'cvs'} = $e; 
}
sub set_dash  {
    my $self = shift;
    my $e = shift;
    return unless (_non_empty($e));
    $self->{'reference'}{'info'}{'dash'} = $e; 
}

sub book_type {
    my $self = shift;
    return 'NONE' unless (_non_empty($self->ob));
    return 'CANONICAL_NAME' if ($self->ob =~ m/@{[$self->get_regexes->{'livres'}]}/);
    return 'ABBREVIATION' if ($self->ob =~ m/@{[$self->get_regexes->{'abbreviations'}]}/);
    return 'UNKNOWN';
}

sub formatted_book {
    my $self = shift;
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';
    
    if ($book_format eq 'ABBREVIATION' || ($book_format eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
    	$ret .= $self->abbreviation || '';
    } else {
    	$ret .= $self->book || '';
    }

    return $ret;
} 

sub formatted_book2 {
    my $self = shift;
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';

    if ($book_format eq 'ABBREVIATION' || ($book_format eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
    	$ret .= $self->abbreviation2 || '';
    } else {
    	$ret .= $self->book2 || '';
    }

    return $ret;
} 

sub set {
    my $self = shift;
    my $r = shift;
    my $context = shift;

    $self->{reference} = dclone($context->{reference}) if defined($context->{reference});

    # $r must be a defined hash
    return unless(defined($r) && ref($r) eq 'HASH');

    # Save the words that provide context
    $self->set_context_words($r->{context_words});

    # Set the main part of the reference
    $self->set_b($r->{b});   # Match Book
    $self->set_c($r->{c});   # Chapter
    $self->set_v($r->{v});   # Verse

    # Set the range part of the reference    
    $self->set_b2($r->{b2});  # Match Book
    $self->set_c2($r->{c2});  # Chapter
    $self->set_v2($r->{v2});  # Verse

    # Set the formatting and informational parts
    $self->set_cvs($r->{cvs}) if ((defined($r->{c}) && defined($r->{v})) || (defined($r->{c2}) && defined($r->{v2})));   # The Chapter Verse Separtor
    $self->set_dash($r->{dash}); # The reference range operator

    # If this is a book with only one chapter then be sure that chapter is set to '1'
    if(((defined($self->book) && $self->book =~ m/@{[$self->get_regexes->{'livres_avec_un_chapitre'}]}/) ||
       (defined($self->abbreviation) && $self->abbreviation =~ m/@{[$self->get_regexes->{'livres_avec_un_chapitre'}]}/)) &&
	!(defined($self->c) && defined($self->c) && $self->c eq '1')) {
	$self->set_v($self->c);
	$self->set_c('1');
	$self->set_cvs(':');
    }

    # Set the spaces
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22

    $self->set_s2($r->{s2});
    $self->set_s3($r->{s3});
    $self->set_s4($r->{s4});
    $self->set_s5($r->{s5});
    $self->set_s6($r->{s6});
    $self->set_s7($r->{s7});
    $self->set_s8($r->{s8});
    $self->set_s9($r->{s9});

}

##################################################################################
# Reference Parsing
##################################################################################
sub parse {
    my $self = shift; 
    my $token = shift;
    my $state = shift;
    my $context_words = '';
    ($context_words, $state) = $self->parse_context_words($token, $state);

    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';
    
    # type: LCVLCV
    if ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {

        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, b2=>$12, s7=>$13, c2=>$14, s8=>$15, s9=>$17, v2=>$18,  context_words=>$context_words});
    }   
 
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCVLC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {
	
	$self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, b2=>$12, s7=>$13, c2=>$14, s8=>$15, context_words=>$context_words });
    }

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCLCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
	
        $self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, b2=>$8, s7=>$9, c2=>$10, s8=>$11, cvs=>$12, s9=>$13, v2=>$14, context_words=>$context_words });
    }

    # type: LCVCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
	
        $self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, c2=>$12, s8=>$13, s9=>$15, v2=>$16, context_words=>$context_words});
    }

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: LCLC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {
	
	$self->set({ b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, b2=>$8, s7=>$9, c2=>$10, s8=>$11, context_words=>$context_words });
    }

    # type: LCCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, c2=>$8, s8=>$9, cvs=>$10, s9=>$11, v2=>$12, context_words=>$context_words});
    }  

    # type: LCVV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, dash=>$10, s6=>$11, v2=>$12, s7=>$13, context_words=>$context_words});
    }

    # type: LCV
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, cvs=>$6, s4=>$7, v=>$8, s5=>$9, context_words=>$context_words});
    } 

    # type: LCC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)/x) {
    
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, dash=>$6, s6=>$7, c2=>$8, s7=>$9, context_words=>$context_words});
    }

    # type: LC
    elsif ($token =~ m/($spaces)($r->{'livres_et_abbreviations'})($spaces)($r->{'chapitre'})($spaces)/x) {        
        $self->set({b=>$2, s2=>$3, c=>$4, s3=>$5, context_words=>$context_words});
    } else {
            $self->parse_chapitre($token, $state, $context_words);
    } 
    return $self;
}

sub parse_chapitre {
    my $self = shift; 
    my $token = shift;
    my $state = shift;
    my $context_words = shift;
    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';

    # We are here!

    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: CVCV
    if ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, dash=>$8, s6=>$9, c2=>$10, s8=>$11, s9=>$13, v2=>$14, context_words=>$context_words });
    } 

    # type: CCV
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, dash=>$4, s6=>$5, c2=>$6, s8=>$7, cvs=>$8, s9=>$9, v2=>$10, context_words=>$context_words });
    } 

    # type: CVV
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'cv_separateur'})($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, dash=>$8, s6=>$9, v2=>$10, s7=>$11, context_words=>$context_words });
    } 

    # type: CV
    elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)($r->{'cv_separateur'})([\s ]*)($r->{'verset'})([\s ]*)/x) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, cvs=>$4, s4=>$5, v=>$6, s5=>$7, context_words=>$context_words });
    }

    # type: CC
    elsif ($token =~ m/($spaces)($r->{'chapitre'})($spaces)($r->{'intervale'})($spaces)($r->{'chapitre'})($spaces)/ && $state eq CHAPTER) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, dash=>$4, s4=>$5, c2=>$6, s7=>$7, context_words=>$context_words });
    } 

    # type: C
    elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)/ && $state eq CHAPTER) {
    # elsif ($token =~ m/([\s ]*)($r->{'chapitre'})([\s ]*)/) {
        $state = 'match';
        $self->set({ s2=>$1, c=>$2, s3=>$3, context_words=>$context_words });
    } 

    # Cet un Verset
    else {
        $self->parse_verset($token, $state, $context_words);
    }
}

sub parse_verset {
    my $self = shift; 
    my $token = shift;
    my $state = shift; 
    my $context_words = shift;
    my $r = $self->get_regexes;

    my $spaces = '[\s ]*';

    unless (defined($state)) {
        carp "\n\n$token: " .__LINE__ ."\n\n";
    }
    # Ge(s2)1(s3):(s4)1(s5)-(s6)Ap(s7)21(s8):(s9)22
    # type: VV
    if ($token =~ m/($spaces)($r->{'verset'})($spaces)($r->{'intervale'})($spaces)($r->{'verset'})($spaces)/ && $state eq VERSE) {
        $state = 'match';
        $self->set({s2=>$1, v=>$2, s5=>$3, dash=>$4, s6=>$5, v2=>$6, context_words=>$context_words});
    }
    
    # type: V
    elsif ($token =~ m/([\s ]*)($r->{'verset'})([\s ]*)/ && $state eq VERSE) {
        $state = 'match';
        $self->set({s2=>$1, v=>$2, s5=>$3, context_words=>$context_words});
    } 

    # Error
    else {
        $self->set({type => 'Error'});
    }
}

################################################################################
# Format Section
# This section provides a default normalize form that is useful for various
# operations with references
################################################################################
sub parse_context_words {
    my $self = shift;
    my $refstr = shift;
    my $r = $self->get_regexes;
    my $spaces = '[\s ]*';
    my $state = shift;
    my $header = '';

    if ($refstr =~ m/^($r->{'livres_et_abbreviations'})(?:$spaces)(?:$r->{'cv_list'})/) {
	$header = $1; $state = BOOK;
    } elsif ($refstr =~ m/^($r->{'chapitre_mots'})(?:$spaces)(?:$r->{'cv_list'})/) {
	$header = $1; $state = CHAPTER;
    } elsif ($refstr =~ m/($r->{'verset_mots'})(?:$spaces)(?:$r->{'cv_list'})/) {
	$header = $1; $state = VERSE;
    }
    return ($header, $state);
}


sub formatted_context_words {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';
    if ($self->state_is_chapitre || $self->state_is_verset) {
	$ret .= $self->context_words || '';
    }

    return $ret;
}

sub formatted_c  { shift->c || ''; }
sub formatted_v  { shift->v || ''; }
sub formatted_c2 { shift->c2 || ''; }
sub formatted_v2 { shift->v2 || ''; }

sub formatted_cvs {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
 
    # if C and V exist then return ...
      # 1. The value given in the configuation file or ...
      # 2. The value parsed from the original reference
      # 3. ':'
    # if C and V do not exist then return ''
    return (
	(_non_empty($self->c) && _non_empty($self->v)) 
	? 
	(defined($self->get_configuration->get('reference','cvs')) 
	 ? 
	 $self->get_configuration->get('reference','cvs')
	 :
	 (defined( $self->cvs ) ? $self->cvs : ':')) 
	:
	'');
}

sub formatted_cvs2 {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
 
    # if C and V exist then return ...
      # 1. The value given in the configuation file or ...
      # 2. The value parsed from the original reference
      # 3. ':'
    # if C and V do not exist then return ''
    return (
	(_non_empty($self->c2) && _non_empty($self->v2)) 
	? 
	(defined($self->get_configuration->get('reference','cvs')) 
	 ? 
	 $self->get_configuration->get('reference','cvs') 
	 :
	 (defined( $self->cvs ) ? $self->cvs : ':')) 
	:
	'');
}

sub formatted_interval {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
 
    # if C and V exist then return ...
      # 1. The value given in the configuation file or ...
      # 2. The value parsed from the original reference
      # 3. '-'
    # if C and V do not exist then return ''
   return ((_non_empty($self->formatted_book2) || _non_empty($self->c2) || _non_empty($self->v2) ) 
	? 
	(defined($self->get_configuration->get('reference','intervale'))
	 ? 
	 $self->get_configuration->get('reference','intervale') 
	 :
	 (defined( $self->dash ) ? $self->dash : ':')) 
	:
	'');
}

sub normalize {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $book_format = shift || 'ORIGINAL';
    my $ret = '';
    
    # These variables are used as caches in this function so we don't need to find there values multiple times
    my ($book, $book2, $c, $c2) = ('','','','');

    if (defined($self->book) && defined($self->book2) || (!(defined($self->v) || defined($self->v2)) && $state eq 'VERSE') ) {
	$state = 'BOOK';
    } elsif (defined($self->c) && defined($self->c2) && $state eq 'VERSE') {
	$state = 'CHAPTER';
    }

    # Write out the context words and the book or abbreviation
    if ($state eq 'BOOK') {	
	$ret .= $self->formatted_context_words($state, $book_format);
	$ret .= $book = $self->formatted_book($book_format);
	$ret .= ' ' if defined($self->s2);
    }

    # Write out the chapter and the chapter/verse separator
    if ($state eq 'BOOK' || $state eq 'CHAPTER') {
	$ret .= $c = $self->formatted_c;
	$ret .= $self->formatted_cvs;
    }

    # Write out the verse
    $ret .= $self->formatted_v;

    # Write out the interval character to connect two references as a range of verses
    $ret .= $self->formatted_interval;

    # Write out the second book or abbreviation
    $book2 = $self->formatted_book2($book_format);
    $ret .= $book2 if ($book ne $book2);

    # If there is a space defined after book2 and we are not printing the same book twice then ' '
    $ret .= ' ' if (defined($self->s7) && $book ne $book2);

    # Write out the chapter
    $c2 = $self->formatted_c2;
    $ret .= $c2 if ($c ne $c2);

    # Write out the second chapter/verse separator
    $ret .= $self->formatted_cvs2 if ($c ne $c2);

    # Write out the second verse
    $ret .= $self->formatted_v2;

    return $ret;
}

# When debugging I don't want to type normalize over and over again
sub n { return shift->normalize; }

sub bol {
    my $self = shift;
    my $state = shift || 'BOOK';
    my $ba = shift || 'ORIGINAL';
    my $ret = '';

    if (defined($self->book) && defined($self->book2) || (!(defined($self->v) || defined($self->v2)) && $state eq 'VERSE') ) {
	$state = 'BOOK';
    } elsif (defined($self->c) && defined($self->c2) && $state eq 'VERSE') {
	$state = 'CHAPTER';
    }

    if ($state eq 'BOOK') {
	if ($self->state_is_chapitre || $self->state_is_verset) {
	    $ret .= $self->context_words || '';
	}

	if ($ba eq 'ABBREVIATION' || ($ba eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
	    $ret .= $self->abbreviation || '';
	} else {
	    $ret .= $self->book || '';
	}

	$ret .= ' ' if defined($self->s2);
    }

    if ($state eq 'BOOK' || $state eq 'CHAPTER') {
	$ret .= $self->c || '';
	$ret .= (_non_empty($self->c) && ! _non_empty($self->v) && (_non_empty($self->c2) && ! _non_empty($self->v2)) ) ? $self->cvs || '$' : '';
	$ret .= (
	    (_non_empty($self->c) && _non_empty($self->v)) 
	    ? 
	    (defined($self->get_configuration->get('reference','cvs')) 
	     ? 
	     $self->get_configuration->get('reference','cvs')
	     :
	     (defined( $self->cvs ) ? $self->cvs : ':')) 
	    :
	    '');
    }

    $ret .= $self->v || '';
    $ret .= ((_non_empty($self->formatted_book2) || _non_empty($self->c2) || _non_empty($self->v2) ) 
	? 
	(defined($self->get_configuration->get('reference','intervale'))
	 ? 
	 $self->get_configuration->get('reference','intervale') 
	 :
	 (defined( $self->dash ) ? $self->dash : ':')) 
	:
	'');

    if ($ba eq 'ABBREVIATION' || ($ba eq 'ORIGINAL' && $self->book_type eq 'ABBREVIATION')) {
	$ret .= $self->abbreviation2 || '';
    } else {
	$ret .= $self->book2 || '';
    }

    $ret .= ' ' if defined($self->s7);

    $ret .= $self->c2 || '';
    $ret .= (_non_empty($self->c) && ! _non_empty($self->v) && (_non_empty($self->c2) && ! _non_empty($self->v2)) ) ? $self->cvs || '$' : '';
    $ret .= (
	(_non_empty($self->c2) && _non_empty($self->v2)) 
	? 
	(defined($self->get_configuration->get('reference','cvs')) 
	 ? 
	 $self->get_configuration->get('reference','cvs') 
	 :
	 (defined( $self->cvs ) ? $self->cvs : ':')) 
	:
	'');    
    $ret .= $self->v2 || '';
    return $ret;
}


##################################################################################
# State Helpers 
#
# The context of a reference refers to the first part of it defined...
# For example: 'Ge 1:1' has its book, chapter and verse parts defined. So its 
#              state is 'explicit'  This means it is a full resolvable reference 
#              '10:1' has its chapter and verse parts defined. So its 
#               context is 'chapitre' 
#              'v. 1' has its verse part defined. So its context is 'verset' 
# 
##################################################################################
sub state_is_chapitre {
    my $self = shift;
    return _non_empty($self->c) && !$self->is_explicit;
}

sub state_is_verset {
    my $self = shift;
    return _non_empty($self->v) && !_non_empty($self->c) && !$self->is_explicit;
}

# The state of a reference can have three values BOOK, CHAPTER or VERSE.
# To find the state of a reference choose the leftmost value that exists in 
# that reference
#
# Examples:
#  'Ge 1:2' has a state of 'BOOK'
#  '1:2' has a state of 'CHAPTER'
#  '2' has a state of 'VERSE'
sub state_is_book {
    my $self = shift;
    return $self->is_explicit;
}

sub state {
    my $self = shift;
    return 'BOOK'    if $self->state_is_book;
    return 'CHAPTER' if $self->state_is_chapitre;
    return 'VERSE'   if $self->state_is_verset;
    return 'UNKNOWN';
}

# The context of a reference can have three values BOOK, CHAPTER or VERSE.
# To find the state of a reference choose the rightmost value that exists in 
# that reference
#
# Examples:
#  'Ge 1:1' has a state of 'VERSE'
#  'Ge 1' has a state of 'CHAPTER'
#  'Ge' has a state of 'BOOK' note: a valid reference must be either CHAPTER or VERSE and not simply BOOK
#  TODO: write tests
sub context_is_verset {
    my $self = shift;
    return _non_empty($self->v) || _non_empty($self->v2);
}

sub context_is_chapitre {
    my $self = shift;
    return (_non_empty($self->c) || _non_empty($self->c2)) && !$self->context_is_verset;
}

sub context_is_book {
    my $self = shift;
    return (_non_empty($self->formatted_book) || _non_empty($self->formatted_book2)) && !$self->context_is_chapitre;
}

sub context {
    my $self = shift;
    return 'BOOK'    if $self->context_is_book;
    return 'CHAPTER' if $self->context_is_chapitre;
    return 'VERSE'   if $self->context_is_verset;
    return 'UNKNOWN';
}

sub is_explicit {
    my $self = shift;
    # Explicit reference must have a book and a chapter
    return (_non_empty($self->key));
}

sub shared_state {
    my $r1 = shift;
    my $r2 = shift;

    # If this reference has an interval ... don't handle it result may be technically 
    # correct but on a practical note ... they are to difficult to read
    # return if $r1->has_interval || $r2->has_interval;

    # Two references can not have shared context if they do not have the same state
    return unless ($r1->state eq $r2->state);

    return VERSE   if ((defined($r1->v) && defined($r2->v))     && (($r1->v ne $r2->v) && ($r1->c eq $r2->c) && ($r1->key eq $r2->key)) );
    return CHAPTER if ((defined($r1->c) && defined($r2->c))     && (($r1->c ne $r2->c) && (!(defined($r1->key) && defined($r2->key)) || (defined($r1->c) && defined($r2->c) && $r1->key eq $r2->key))) );
    return BOOK    if ((defined($r1->key) && defined($r2->key)) && (($r1->key ne $r2->key)));
    return;
}

########################################################################
# Helper Functions
#

sub has_interval {
    my $self = shift;
    return (defined($self->key2) || defined($self->c2) || defined($self->v2));
}

sub begin_interval_reference {
    my $self = shift;
    my $ret = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes); 

    $ret->set({ b => $self->ob, 
		c => $self->oc, 
		v => $self->ov, 
		s2 => $self->s2, 
		s3 => $self->s3, s4 => $self->s4, 
		s5 => $self->s5, cvs => $self->cvs });

    return $ret;
}
sub end_interval_reference {
    my $self = shift;
    my $ret = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes); 

    my ($b, $c, $s7);

    if (!defined($self->ob2) && (defined($self->oc2) || defined($self->ov2) )) {
	$b = $self->ob;
	$s7 = $self->s2;
    } else {
	$b = $self->ob2;
	$s7 = $self->s7;
    }

    if (!defined($self->oc2) && ( defined($self->ov2) )) {
	$c = $self->oc;
    } else {
	$c = $self->oc2;
    }
    
    return unless (_non_empty($b) || _non_empty($c) || _non_empty($self->ov2));

    $ret->set({ b => $b,
		c => $c, 
		v => $self->ov2, 
		s2 => $s7,
		s3 => $self->s8, s4 => $self->s9, 
		cvs => $self->cvs });

    return $ret;
}

sub interval {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    return $r1 if ($r1->compare($r2) == 0);

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }
    
    my $min = $r1->begin_interval_reference->min($r1->end_interval_reference, $r2->begin_interval_reference, $r2->end_interval_reference);
    my $max = $r1->begin_interval_reference->max($r1->end_interval_reference, $r2->begin_interval_reference, $r2->end_interval_reference);

    my $ret = new Religion::Bible::Regex::Reference($r1->get_configuration, $r1->get_regexes);

    $ret->set({ b => $min->formatted_book, c => $min->c, v => $min->v, 
		b2 => $max->formatted_book, c2 => $max->c, v2 => $max->v2 || $max->v,
		cvs => $min->cvs || $max->cvs, dash => '-',
		s2 => $min->s2, 
		s3 => $min->s3, s4 => $min->s4, 
		s5 => $min->s5,  
		s7 => $max->s2, s8 => $max->s3,
		s9 => $max->s4, 
 });

    return $ret;
}
sub min {
    my $self = shift;
    my @refs = @_; 
    my $ret = $self;

    foreach my $r (@refs) {
#	next unless (defined(ref $r));
        if ($ret->gt($r)) {
            $ret = $r;
        }
    }
    return $ret;
} 

sub max {
    my $self = shift;
    my @refs = @_; 
    my $ret = $self;

    foreach my $r (@refs) {
        if ($ret->lt($r)) {
            $ret = $r;
        }
    }
    return $ret;
} 

# References must be of the forms LCV, CV or V
sub compare {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    # Messy logic that compares two references with a context of 'BOOK' 
    # ex. 
    # ('Ge 1:1' and 'Ge 2:1'), ('Ge 1:1' and 'Ge 2'), ('Ge 1' and 'Ge 2:1'), ('Ge 1' and 'Ge 2')   
    # ('Ge 1:1' and 'Ex 2:1'), ('Ge 1:1' and 'Ex 2'), ('Ge 1' and 'Ex 2:1'), ('Ge 1' and 'Ex 2')   
    # ('Ex 1:1' and 'Ge 2:1'), ('Ex 1:1' and 'Ge 2'), ('Ex 1' and 'Ge 2:1'), ('Ex 1' and 'Ge 2')   
    if (defined($r1->key) && defined($r2->key)) {
	if (($r1->key + 0 <=> $r2->key + 0) == 0) {
	    if (defined($r1->c) && defined($r2->c)) {
		if (($r1->c + 0 <=> $r2->c + 0) == 0) {
		    if (defined($r1->v) && defined($r2->v)) {
			return ($r1->v + 0 <=> $r2->v + 0);
		    } else {
			return ($r1->c + 0 <=> $r2->c + 0);
		    }
		} else {
		    return ($r1->c + 0 <=> $r2->c + 0);
		}
	    } else {
		return ($r1->key + 0 <=> $r2->key + 0);
	    }
	} else {
	    return ($r1->key + 0 <=> $r2->key + 0);
	}	
    } 
    # Messy logic that compares two references with a context of 'CHAPTER' 
    # ex.  ('1:1' and '2:1'), ('1:1' and '2'), ('1' and '2:1'), ('1' and '2')
    else {
	if (defined($r1->c) && defined($r2->c)) {
	    if (($r1->c + 0 <=> $r2->c + 0) == 0) {
		if (defined($r1->v) && defined($r2->v)) {
		    return ($r1->v + 0 <=> $r2->v + 0);
		} else {
		    return ($r1->c + 0 <=> $r2->c + 0);
		}
	    } else {
		return ($r1->c + 0 <=> $r2->c + 0);
	    }
	} else {
	    if (defined($r1->v) && defined($r2->v)) {
		return ($r1->v + 0 <=> $r2->v + 0);
	    } else {
		return ($r1->c + 0 <=> $r2->c + 0);
	    }
	}
    }

#    return 1 if ((defined($r1->key) && defined($r2->key)) && ($r1->key + 0 > $r2->key + 0));
#    return 1 if ((defined($r1->c) && defined($r2->c)) && ($r1->c + 0 > $r2->c + 0));
#    return 1 if ((defined($r1->v) && defined($r2->v)) && ($r1->v + 0 > $r2->v + 0));
    return;
}
sub gt {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    ($r1->compare($r2) == -1) ? return : return 1;

}
sub lt {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));

    # To be comparable both references must have the same state
    # ex. 'Ge 1:1' may not be compared to 'chapter 2' or 'v. 4'
    unless ($r1->state eq $r2->state) {
	carp "Attempted to compare two reference that do no have the same state: " . $r1->normalize . " and " . $r2->normalize . "\n";
	return;
    }

    my $ret = $r1->compare($r2);
    ($ret == 1) ? return : return 1;

}


sub combine {
    my $r1 = shift;
    my $r2 = shift;
    
    # References must not be empty
    return unless (_non_empty($r1));
    return unless (_non_empty($r2));
    
    my $ret = new Religion::Bible::Regex::Reference($r1->get_configuration, $r1->get_regexes);

    if ($r2->state eq 'BOOK') {
	$ret->set({}, $r2);
    } elsif ($r2->state eq 'CHAPTER') {    
	$ret->set(
	    {
		b => $r2->formatted_book2 || $r2->formatted_book || $r1->formatted_book2 || $r1->formatted_book,
		c => $r2->c,
		v => $r2->v,

		c2 => $r2->c2,
		v2 => $r2->v2,	
	
 		cvs => $r2->cvs ||  $r1->cvs,
 		dash => $r2->dash || $r1->dash,
 		s2 => $r2->s2 || $r1->s2, 
 		s3 => $r2->s3 || $r1->s3, 
 		s4 => $r2->s4 || $r1->s4, 
 		s5 => $r2->s5 || $r1->s5, 
 		s6 => $r2->s6 || $r1->s6, 
 		s7 => $r2->s7, 
 		s8 => $r2->s8 || $r1->s8,
 		s9 => $r2->s9 || $r1->s9, 
	    }, $r2
	    );
    } else {
	$ret->set(
	    {
		b => $r2->formatted_book2 || $r2->formatted_book || $r1->formatted_book2 || $r1->formatted_book,
		c => $r2->c2 || $r2->c || $r1->c2 || $r1->c,
		v => $r2->v,

		v2 => $r2->v2,
		cvs => $r2->cvs || $r1->cvs,
		dash => $r2->dash || $r1->dash,
		s2 => $r2->s2 || $r1->s2, 
		s3 => $r2->s3 || $r1->s3, 
		s4 => $r2->s4 || $r1->s4, 
		s5 => $r2->s5 || $r1->s5, 
		s6 => $r2->s6 || $r1->s6, 
		s7 => $r2->s7,
		s8 => $r2->s8 || $r1->s8,
		s9 => $r2->s9 || $r1->s9, 
	    }, $r2
	    );
    }
    
    return $ret;

}
sub _non_empty {
    my $value = shift;
    return (defined($value) && $value ne '');
}  

# Returns the first _non_empty value or ''
sub _setor {
    foreach my $v (@_) {
        return $v if _non_empty($v);
    }
    
    # if no value is given the default should be a empty string
    return '';
}

1; # Magic true value required at end of module
__END__




=head1 NAME

Religion::Bible::Regex::Reference -  this Perl object represents a Biblical reference along with the functions that can be applied to it.


=head1 VERSION

This document describes Religion::Bible::Regex::Reference version 0.8


=head1 SYNOPSIS

=over 4

  use Religion::Bible::Regex::Config;
  use Religion::Bible::Regex::Builder;
  use Religion::Bible::Regex::Reference;

  # $yaml_config_file is either a YAML string or the path to a YAML file
  $yaml_config_file = 'config.yml';

  my $c = new Religion::Bible::Regex::Config($yaml_config_file);
  my $r = new Religion::Bible::Regex::Builder($c);
  my $ref = new Religion::Bible::Regex::Reference($r, $c);
    
  $ref->parse('Ge 1:1');

=back

=head1 DESCRIPTION

This class is meant as a building block to enable people and publishing houses 
to build tools for processing documents which contain Bible references.

This is the main class for storing state information about a Bible reference and
can be used to build scripts that perform a variety of useful operations.  
For example, when preparing a Biblical commentary in electronic format a publishing 
house can save a lot of time and manual labor by creating scripts that do 
the following:

=over 4

=item * Automatically find and tag Bible references

=item * Find invalid Bible references

=item * Check that the abbreviations used are consistent throughout the entire book.

=item * Create log files of biblical references that need to be reviewed by a person.

=back

This class is meant to be a very general-purpose so that any type of tool that needs to manipulate Bible references can use it.


=head1 Bible Reference Types

Bible references can be classified into a few different patterns.

Since this code was originally written and commented in French, we've retained
the French abbreviations for these different Bible reference types. 

=over 4

    'L' stands for 'Livre'    ('Book' in English)
    'C' stands for 'Chapitre' ('Chapter' in English)
    'V' stands for 'Verset'   ('Verse' in English)

=back

Here are the different Bible reference types with an example following each one:

=over 4

    # Explicit Bible Reference Types
    LCVLCV Ge 1:1-Ex 1:1
    LCVCV  Ge 1:1-2:1
    LCCV   Ge 1-2:5
    LCVV   Ge 1:2-5
    LCV    Ge 1:1
    LCC    Ge 1-12
    LC     Ge 1        
            
    # Implicit Bible Reference Types
    CVCV   1:1-2:1
    CCV    1-2:5
    CVV    1:2-5
    CV     1:1
    CC     1-12
    C      1
    VV     1-5
    V      1

=back

=head2 Explicit and Implicit Bible Reference Types	

We say the Bible reference is explicit when it has enough information within the 
reference to identify an exact location within the Bible. See above for examples.

We say that a Bible reference is implicit when the reference itself does not 
contain enough information to find its location in the Bible. often times within 
a commentary we will find implicit Bible references that use the context of the text
to identify the Bible reference.

    in Chapter 4
    in verse 17
    see 4:17
    as we see in chapter 5

=head1 INTERFACE 

=head2 new

Creates a new Religion::Bible::Regex::Reference. Requires two parameters a Religion::Bible::Regex::Config object and a Religion::Bible::Regex::Regex object

=head2 get_configuration

Returns the Religion::Bible::Regex::Config object used by this reference.

=head2 get_regexes

Returns the Religion::Bible::Regex::Builder object used by this reference.

=head2 get_reference_hash

Returns the hash that contains all of the parts of the current Bible reference.

=head2 is_explicit

Returns true if all the information is there to reference an exact verse or verses in the Bible.

=head2 set

=head2 key 
=head2 c   
=head2 v   

=head2 key2 
=head2 c2   
=head2 v2   

=head2 ob
=head2 ob2
=head2 oc  
=head2 oc2 
=head2 ov  
=head2 ov2 

=head2 s2 
=head2 s3 
=head2 s4 
=head2 s5 
=head2 s6 
=head2 s7 
=head2 s8 
=head2 s9 

=head2 book          
=head2 book2         
=head2 abbreviation  
=head2 abbreviation2 
=head2 cvs           
=head2 dash  

=head2 set_key 
=head2 set_c   
=head2 set_v   

=head2 set_key2 
=head2 set_c2   
=head2 set_v2   

=head2 set_b  
=head2 set_b2 
=head2 set_oc  
=head2 set_oc2 
=head2 set_ov  
=head2 set_ov2 
=head2 set_cvs  
=head2 set_dash 

=head2 set_s2 
=head2 set_s3 
=head2 set_s4 
=head2 set_s5 
=head2 set_s6 
=head2 set_s7 
=head2 set_s8 
=head2 set_s9 
    
=head2 abbreviation2book
=head2 abbreviation2key
=head2 book2abbreviation
=head2 book2key
=head2 book_type
=head2 formatted_book
=head2 formatted_book2
=head2 key2abbreviation
=head2 key2book
=head2 reference
=head2 set_b
=head2 set_b2
=head2 set_cvs
=head2 set_dash
=head2 setold
=head3 normalize

=head2 compare
=head2 end_interval_reference
=head2 gt
=head2 interval
=head2 lt
=head2 max
=head2 min
=head2 n
=head2 state
=head2 parse_context_words
=head2 set_context_words
=head2 combine
=head2 bol
=head2 shared_state
=head2 	context
=head2 	context_is_book
=head2 	context_is_chapitre
=head2 	context_is_verset
=head2 	context_words
=head2 	formatted_c
=head2 	formatted_c2
=head2 	formatted_context_words
=head2 	formatted_cvs
=head2 	formatted_cvs2
=head2 	formatted_interval
=head2 	formatted_v
=head2 	formatted_v2



Requires a hash of values to initalize the Bible reference. Optional argument a previous reference which can provide context for initializing a reference

=head2 state_is_verset

Returns true if the current the state is VERSE

=head2 state_is_chapitre

Returns true if the current the state is CHAPTER

=head2 state_is_book   

Returns true if the current the state is BOOK

=head2 begin_interval_reference
=head2 has_interval
=head2 parse
=head2 parse_chapitre
=head2 parse_verset

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Religion::Bible::Regex::Reference requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 4

=item * Religion::Bible::Regex::Config

=item * Religion::Bible::Regex::Builder

=back

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-religion-bible-regex-reference@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Daniel Holmlund  C<< <holmlund.dev@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Holmlund C<< <holmlund.dev@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
